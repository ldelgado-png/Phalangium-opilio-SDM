# Phalangium opilio | Alternative background-extent sensitivity diagnostic
#
# Run in RStudio from the existing project folder:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/14_candidate_background_extent_diagnostics.R")
#
# Provisional hypothesis test, NOT a definition of an accessible area (M).
# Does not fit maxnet, re-run ENMeval, or read the Venezuelan field records.

for (pkg in c("terra", "ENMeval")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Please install package ", pkg, " before continuing.")
  }
}
root <- getwd()
pilot <- file.path(root, "04_resultados_modelo", "pilot_western_palaearctic")
bio_file <- file.path(root, "01_datos", "climate_diagnostics",
                      "16_worldclim_western_window_5m.tif")
p_file <- file.path(pilot, "01_pilot_calibration_occurrences.csv")
bg_file <- file.path(pilot, "02_pilot_background_xy.csv")
if (!all(file.exists(c(bio_file, p_file, bg_file)))) {
  stop("The existing pilot files could not be located. ",
       "Set the working directory to Phalangium_opilio_SDM ",
       "and ensure the initial pilot (script 11) was completed.")
}
bio <- terra::rast(bio_file)
if (!identical(names(bio), c("BIO1", "BIO4", "BIO12", "BIO15"))) {
  stop("Unexpected WorldClim predictors.")
}
p <- utils::read.csv(p_file, stringsAsFactors = FALSE)
original_bg <- utils::read.csv(bg_file, stringsAsFactors = FALSE)
xy <- data.frame(
  longitude = as.numeric(p$decimalLongitude),
  latitude = as.numeric(p$decimalLatitude)
)
orig_xy <- original_bg[, c("longitude", "latitude"), drop = FALSE]
if (nrow(xy) != 10426L || nrow(orig_xy) != 10000L ||
    any(!is.finite(as.matrix(xy))) ||
    any(!is.finite(as.matrix(orig_xy)))) {
  stop("Unexpected pilot input dimensions or non-finite coordinates.")
}

# Rebuild a raster with the existing calibration cells marked; terra::distance
# on geographic rasters computes distance to non-NA cells, in kilometres here.
# The buffer is not evidence of dispersal distance or historical accessibility.
presence_cells <- unique(terra::cellFromXY(bio[[1]], as.matrix(xy)))
if (anyNA(presence_cells) || length(presence_cells) != 10426L) {
  stop("Pilot presences are not unique valid WorldClim raster cells.")
}
presence_raster <- bio[[1]]
terra::values(presence_raster) <- NA_real_
presence_raster[presence_cells] <- 1

message("Calculating geographic distances to calibration presences...")
distance_km <- terra::distance(
  presence_raster, unit = "km", method = "cosine"
)
distance_values <- terra::extract(distance_km, as.matrix(xy))
distance_at_presences <- as.numeric(distance_values[[ncol(distance_values)]])
if (any(!is.finite(distance_at_presences)) ||
    max(distance_at_presences) > 1) {
  stop("Distance-to-presence raster is misaligned with the input points.")
}
valid <- !is.na(bio[[1]])
for (i in 2:4) valid <- valid & !is.na(bio[[i]])

# These radii are HYPOTHETICAL spatial-sensitivity settings, not M values.
radii_km <- c(250, 500)
results <- list()
all_bg <- list(original_rectangle = orig_xy)
set.seed(20261018L)

for (km in radii_km) {
  message("Preparing hypothetical ", km, " km neighbourhood...")
  m <- terra::ifel(valid & distance_km <= km, 1, NA)
  names(m) <- paste0("near_presence_", km, "km")
  terra::writeRaster(
    m, file.path(pilot, paste0("21_candidate_bg_", km, "km_mask.tif")),
    overwrite = TRUE, gdal = "COMPRESS=LZW"
  )
  allowed_cells <- as.numeric(terra::global(m, "sum", na.rm = TRUE)[1, 1])
  if (!is.finite(allowed_cells) || allowed_cells < 12000) {
    warning(km, " km neighbourhood offers only ", allowed_cells,
            " environmental cells. Inspect the mask.")
  }

  available_bg_cells <- allowed_cells - length(presence_cells)
  if (available_bg_cells < 5000) {
    stop("Too few cells available outside presence locations in the ",
         km, " km candidate background.")
  }
  sample_n <- min(14000L, as.integer(allowed_cells))
  samples <- terra::spatSample(
    m, size = sample_n, method = "random", na.rm = TRUE,
    as.df = TRUE, xy = TRUE, values = FALSE, warn = FALSE
  )
  new_bg <- as.data.frame(samples[, 1:2, drop = FALSE])
  names(new_bg) <- c("longitude", "latitude")
  sample_cell <- terra::cellFromXY(bio[[1]], as.matrix(new_bg))
  ok <- !is.na(sample_cell) &
        !(sample_cell %in% presence_cells) & !duplicated(sample_cell)
  new_bg <- new_bg[ok, , drop = FALSE]
  if (nrow(new_bg) < 5000) {
    stop("Insufficient sampled cells for ", km, " km diagnostic: ",
         nrow(new_bg))
  }
  if (nrow(new_bg) > 10000) {
    new_bg <- new_bg[seq_len(10000), , drop = FALSE]
  }
  rownames(new_bg) <- NULL
  utils::write.csv(
    new_bg,
    file.path(pilot, paste0("22_candidate_bg_", km, "km_xy.csv")),
    row.names = FALSE
  )
  all_bg[[paste0("within_", km, "km")]] <- new_bg
  results[[paste0(km, "km")]] <- allowed_cells
}

# Always use the SAME presence partition assignment, derived from the
# original pilot. This permits a descriptive comparison of candidate
# background distributions WITHOUT refitting and calculating new AUCs.
saved <- readRDS(file.path(pilot, "07_ENMeval_pilot_evaluation.rds"))
pil_grps <- as.character(ENMeval::eval.occs.grp(saved))
pil_occs <- as.data.frame(ENMeval::eval.occs(saved))
if (length(pil_grps) != nrow(xy) || nrow(pil_occs) != nrow(xy)) {
  stop("Pilot model partition metadata are inconsistent.")
}
folds <- sort(unique(pil_grps))
if (length(folds) != 4L) stop("Expected four pilot folds.")

# The original block groups were split by latitude (lat_lat). Their
# boundaries are reconstructed by median boundaries between adjacent
# occurrence folds, then verified against the stored pilot background folds.
fold_range <- do.call(rbind, lapply(folds, function(g) {
  ix <- which(pil_grps == g)
  data.frame(
    fold = g,
    min_lat = min(as.numeric(pil_occs[[2]][ix])),
    max_lat = max(as.numeric(pil_occs[[2]][ix])),
    median_occ_lat = stats::median(as.numeric(pil_occs[[2]][ix]))
  )
}))
fold_range <- fold_range[order(fold_range$median_occ_lat), , drop = FALSE]
cutoffs <- vapply(seq_len(3), function(i) {
  (fold_range$max_lat[i] + fold_range$min_lat[i + 1]) / 2
}, numeric(1))

assign_folds <- function(ys) {
  match <- findInterval(ys, c(-Inf, cutoffs, Inf), rightmost.closed = TRUE)
  fold_range$fold[match]
}
saved_bg_grp <- as.character(ENMeval::eval.bg.grp(saved))
saved_bg <- as.data.frame(ENMeval::eval.bg(saved))
saved_bg_xy <- data.frame(
  longitude = as.numeric(saved_bg[[1]]),
  latitude = as.numeric(saved_bg[[2]])
)
if (nrow(saved_bg_xy) != 10000L) {
  stop("The saved background dataset is not the expected 10,000 cells.")
}
pilot_occ_grp_check <- assign_folds(as.numeric(pil_occs[[2]]))
if (!identical(pilot_occ_grp_check, pil_grps)) {
  stop("Latitude interval assignment does not reproduce the original ",
       "presence fold assignment.")
}
expected <- assign_folds(saved_bg_xy$latitude)
matches <- sum(expected == saved_bg_grp)
if (matches != length(expected)) {
  stop("Latitudinal group boundaries do not reproduce the original ",
       "background fold assignments (", matches, "/", length(expected),
       "). Inspect partition geometry before comparing scenarios.")
}
# Use the actual background stored inside ENMeval for the baseline.
all_bg$original_rectangle <- saved_bg_xy

by_scenario <- do.call(rbind, lapply(names(all_bg), function(label) {
  bg_xy <- all_bg[[label]]
  grp <- assign_folds(bg_xy$latitude)
  bg_env <- terra::extract(bio, as.matrix(bg_xy))
  if (anyNA(bg_env)) {
    stop("Background outside climate-valid cells in ", label)
  }
  do.call(rbind, lapply(folds, function(g) {
    oi <- which(pil_grps == g)
    bi <- which(grp == g)
    data.frame(
      scenario = label,
      fold = g,
      n_presences = length(oi),
      n_background = length(bi),
      background_percent = round(100 * length(bi) / nrow(bg_xy), 2),
      median_occ_lat = stats::median(as.numeric(pil_occs[[2]][oi])),
      median_bg_lat = if(length(bi)) stats::median(bg_xy$latitude[bi]) else NA,
      median_bg_BIO1 = if(length(bi)) stats::median(bg_env$BIO1[bi]) else NA,
      median_bg_BIO4 = if(length(bi)) stats::median(bg_env$BIO4[bi]) else NA,
      median_bg_BIO12 = if(length(bi)) stats::median(bg_env$BIO12[bi]) else NA,
      median_bg_BIO15 = if(length(bi)) stats::median(bg_env$BIO15[bi]) else NA
    )
  }))
}))
rownames(by_scenario) <- NULL
utils::write.csv(
  by_scenario, file.path(pilot, "23_candidate_bg_extent_fold_comparison.csv"),
  row.names = FALSE, na = ""
)

cat("\nPHALANGIUM OPILIO | BACKGROUND EXTENT SENSITIVITY\n")
print(by_scenario, row.names = FALSE)
cat("\nThis compares geography and available climates only, not model AUC.\n")
cat("The 250 and 500 km settings are hypothetical masks, NOT inferred M.\n")
cat("Outputs stored at ", normalizePath(pilot, winslash = "/"), "\n")
cat("Neither models nor Venezuelan field observations were accessed for tuning.\n")
