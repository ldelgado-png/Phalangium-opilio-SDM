# Phalangium opilio | Environmental novelty: exploratory MESS and MOP
# VERSION: 2026-10-18; diagnostic ONLY; must be executed in RStudio.
#
# RStudio (with project as working directory):
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/25_exploratory_MESS_MOP_south_america.R")
#
# NO Venezuelan field occurrences, localities, or their coordinates are read.
# No model object or prior prediction is accessed or re-fitted.
# The 12W–60E / 30N–72N rectangle is the FIXED OPERATIONAL DOMAIN for
# this manuscript, but NOT a biogeographically demonstrated accessible M.
# This script reports climate analogy and novelty relative to that rectangle
# only. It cannot externally validate any species distribution model.
#
# MESS: predicts::mess (Elith et al., 2010), percentile/range similarity
# MOP:  mean Euclidean distance to the nearest 1% of the sampled reference,
#       on variables STANDARDIZED using reference-only means and SDs.
#       FNN::get.knnx implements the exact k-nearest-distance calculation
#       efficiently for all transfer cells; verified on a small subsample
#       against mop::mop_distance, as used in Cobos et al. (2024).
# Strict-extrapolation flag: negative MESS (< 0); this detects at least one
# outside-reference variable, akin to the original binary MOP basic.
# A large MOP distance INSIDE the univariate reference ranges reflects
# unfamiliar MULTIVARIATE combinations, not strict range extrapolation.
# No cutoffs for "safe" distance are chosen or tuned from Venezuelan sites.

needed <- c("terra", "predicts", "mop", "FNN")
missing <- needed[!vapply(needed, requireNamespace, logical(1),
                            quietly = TRUE)]
if (length(missing)) {
  stop(
    "Packages missing: ", paste(missing, collapse = ", "),
    ". Install them once with install.packages(c(",
    paste(sprintf('"%s"', missing), collapse = ", "), "))"
  )
}
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
clim_dir <- file.path(root, "01_datos", "climate_diagnostics")
west_file <- file.path(clim_dir, "16_worldclim_western_window_5m.tif")
sa_file <- file.path(clim_dir, "17_worldclim_south_america_5m.tif")
if (!all(file.exists(c(west_file, sa_file)))) {
  stop(
    "Climate raster(s) not found. In RStudio open the ",
    "Phalangium_opilio_SDM project folder, then run getwd(). ",
    "The two expected inputs are 16_worldclim_western_window_5m.tif ",
    "and 17_worldclim_south_america_5m.tif, both under ",
    "01_datos/climate_diagnostics. DO NOT substitute a field-record CSV."
  )
}

outdir <- file.path(root, "04_resultados_modelo",
                    "pilot_western_palaearctic",
                    "transfer_novelty_EXPLORATORY_NOT_FINAL")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
scratch <- file.path(outdir, "terra_temp")
dir.create(scratch, recursive = TRUE, showWarnings = FALSE)
terra::terraOptions(
  tempdir = scratch, memfrac = 0.35, progress = 1
)

west <- terra::rast(west_file)
south <- terra::rast(sa_file)
variables <- c("BIO1", "BIO4", "BIO12", "BIO15")
if (!identical(names(west), variables) ||
    !identical(names(south), variables)) {
  stop("Both WorldClim predictor stacks must have the order ",
       "BIO1, BIO4, BIO12, BIO15.")
}
if (!isTRUE(terra::is.lonlat(west)) ||
    !isTRUE(terra::is.lonlat(south)) ||
    !isTRUE(terra::same.crs(west, south)) ||
    max(abs(terra::res(west) - terra::res(south))) > 1e-8) {
  stop("WorldClim reference and transfer rasters differ in CRS ",
       "or cell resolution. Do not resample silently.")
}

# Decision lock: the study domain has been fixed for the manuscript.
# It must not silently change between the archived pilot and these maps.
expected_extent <- c(-12, 60, 30, 72)
actual_extent <- c(
  terra::xmin(west), terra::xmax(west),
  terra::ymin(west), terra::ymax(west)
)
if (any(!is.finite(actual_extent)) ||
    any(abs(actual_extent - expected_extent) > 1e-5)) {
  stop(
    "Reference climate raster does not match the fixed study domain ",
    "(-12, 60, 30, 72). Got: ",
    paste(actual_extent, collapse = ", "),
    ". Do not modify the domain based on Venezuelan localities."
  )
}
cat("[R25] Fixed study calibration rectangle verified (not a proven M).\\n")

# A reproducible, bounded reference sample supports memory-constrained
# computation; results depend on its finite environmental coverage.
# Do not interpret MESS/MOP as definitive without M and sample sensitivity.
seed <- 251018L
n_reference_target <- 5000L
mop_pct_nearest <- 1
set.seed(seed)
ref <- terra::spatSample(
  west, size = n_reference_target, method = "random",
  replace = FALSE, na.rm = TRUE, values = TRUE,
  as.df = TRUE, cells = FALSE, xy = FALSE
)
if (!all(variables %in% names(ref))) {
  stop("Unexpected reference sample columns.")
}
ref <- as.matrix(ref[, variables, drop = FALSE])
storage.mode(ref) <- "double"
ref <- ref[stats::complete.cases(ref) &
             rowSums(is.finite(ref)) == length(variables),
           , drop = FALSE]
if (nrow(ref) < 1000L) {
  stop("Too few complete reference climate cells. ",
       "Check the WorldClim mask.")
}
if (nrow(ref) > 15000L) {
  stop("Reference sample unexpectedly large; avoid excessive RAM.")
}
colnames(ref) <- variables
reference_n <- nrow(ref)
centers <- colMeans(ref)
spread <- apply(ref, 2, stats::sd)
if (any(!is.finite(spread)) || any(spread <= 0)) {
  stop("Reference sample has constant or invalid climate variables.")
}
standardize <- function(x) {
  v <- sweep(x, 2L, centers, FUN = "-")
  v <- sweep(v, 2L, spread, FUN = "/")
  v
}
ref_scaled <- standardize(ref)
k <- max(1L, as.integer(ceiling(
  nrow(ref_scaled) * mop_pct_nearest / 100
)))
if (k >= nrow(ref_scaled)) {
  stop("Invalid nearest-neighbour count.")
}
cat("\n[R25] Starting exploratory climate novelty analysis.\n")
cat("[R25] Reference window = western Palaearctic RECTANGLE, not M.\n")
cat("[R25] Sampled complete reference cells:", reference_n,
    "; seed:", seed, "; nearest reference cells:", k, "\n")
cat("[R25] Predictions and withheld Venezuelan observations are NOT read.\n")

ref_table <- as.data.frame(ref)
utils::write.csv(
  ref_table,
  file.path(outdir, "25_reference_environment_sample.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    variable = variables,
    reference_mean = as.numeric(centers),
    reference_sd = as.numeric(spread),
    sampled_min = apply(ref, 2, min),
    sampled_max = apply(ref, 2, max),
    stringsAsFactors = FALSE
  ),
  file.path(outdir, "26_reference_environment_parameters.csv"),
  row.names = FALSE
)

# Stage A1: raster-wide MESS and per-variable scores, disk-backed.
# predicts::mess returns the 4 predictor-specific MESS layers and a
# 5th overall minimum MESS when full=TRUE.
mess_file <- file.path(outdir, "27_sa_MESS_5m_EXPLORATORY.tif")
cat("\n[R25] Calculating MESS on ALL South American raster cells...\n")
mess_stack <- predicts::mess(
  south, v = ref, full = TRUE,
  filename = mess_file, overwrite = TRUE
)
if (terra::nlyr(mess_stack) != length(variables) + 1L) {
  stop("Unexpected MESS output layers. Inspect predicts::mess version.")
}
names(mess_stack) <- c(
  paste0(variables, "_MESS"), "overall_MESS"
)
mess <- mess_stack[[5]]
names(mess) <- "MESS"
cat("[R25] MESS GeoTIFF written.\n")

# Stage A2: the variable giving the smallest individual MESS.
driver_fun <- function(v) {
  if (is.null(dim(v))) {
    v <- matrix(v, ncol = length(variables), byrow = TRUE)
  }
  out <- rep(NA_real_, nrow(v))
  keep <- stats::complete.cases(v) & rowSums(is.finite(v)) ==
    length(variables)
  if (any(keep)) {
    out[keep] <- max.col(-v[keep, , drop = FALSE],
                         ties.method = "first")
  }
  out
}
driver_file <- file.path(outdir,
                        "28_sa_MESS_limiting_variable_5m_EXPLORATORY.tif")
driver <- terra::app(
  mess_stack[[seq_along(variables)]], fun = driver_fun,
  cores = 1L, filename = driver_file, overwrite = TRUE,
  wopt = list(datatype = "INT1U", gdal = c("COMPRESS=LZW"))
)
names(driver) <- "limiting_variable_index"
cat("[R25] Limiting-variable GeoTIFF written (1=BIO1, 2=BIO4, ",
    "3=BIO12, 4=BIO15).\n", sep = "")

# Stage A3: continuous MOP-distance map for ALL South American cells.
# FNN exact kd-tree queries replicate the mean of the closest 1% of
# reference environmental conditions used by mop::mop_distance.
# terra::app() streams input and output by blocks; each call further
# chunks kd-tree queries at <=2000 rows to bound peak RAM.
mop_distance_for_block <- function(v) {
  if (is.null(dim(v))) {
    v <- matrix(v, ncol = length(variables), byrow = TRUE)
  }
  out <- rep(NA_real_, nrow(v))
  ok <- stats::complete.cases(v) & rowSums(is.finite(v)) ==
    length(variables)
  idx <- which(ok)
  if (!length(idx)) {
    return(out)
  }
  chunks <- split(idx, ceiling(seq_along(idx) / 2000L))
  for (ii in chunks) {
    query <- standardize(v[ii, , drop = FALSE])
    nn <- FNN::get.knnx(
      data = ref_scaled, query = query, k = k,
      algorithm = "kd_tree"
    )
    out[ii] <- rowMeans(nn$nn.dist)
  }
  out
}

# Verify numerical equivalence on a small random, independent climate
# sample (NOT the field sites) before calculating the complete map.
set.seed(seed + 1L)
check <- terra::spatSample(
  south, size = 20L, method = "random",
  replace = FALSE, na.rm = TRUE, values = TRUE,
  as.df = TRUE, cells = FALSE, xy = FALSE
)
check <- as.matrix(check[, variables, drop = FALSE])
check <- check[stats::complete.cases(check) &
                 rowSums(is.finite(check)) == length(variables),
               , drop = FALSE]
if (nrow(check) < 8L) {
  stop("Not enough transfer cells for the MOP cross-check.")
}
colnames(check) <- variables
check_scaled <- standardize(check)
dist_fast <- mop_distance_for_block(check)
dist_package <- mop::mop_distance(
  m_matrix = ref_scaled, g_matrix = check_scaled,
  distance = "euclidean", percentage = mop_pct_nearest,
  comp_each = 8L, parallel = FALSE, progress_bar = FALSE
)
absdiff <- max(abs(dist_fast - dist_package))
if (!is.finite(absdiff) || absdiff > 1e-5) {
  stop("Fast kd-tree MOP distance differs from mop::mop_distance: ",
       absdiff, ". Stop; investigate before mapping.")
}
cat("[R25] FNN/MOP package equivalence verified on ",
    nrow(check), " independent environmental raster cells. ",
    "Maximum absolute difference: ", signif(absdiff, 5), "\n", sep = "")

mop_file <- file.path(
  outdir, "29_sa_MOP_nearest1pct_distance_5m_EXPLORATORY.tif"
)
cat("[R25] Computing continuous MOP distance with disk-backed ",
    "terra::app() and exact kd-tree neighbours...\n", sep = "")
mop_dist <- terra::app(
  south, fun = mop_distance_for_block, cores = 1L,
  filename = mop_file, overwrite = TRUE,
  wopt = list(datatype = "FLT4S", gdal = c("COMPRESS=LZW"))
)
names(mop_dist) <- "MOP_environmental_distance"
cat("[R25] Continuous MOP distance GeoTIFF written.\n")

# Stage A4: strict extrapolation is defined as MESS<0; the same
# sampled reference range constrains both MESS and MOP distances.
strict_file <- file.path(
  outdir, "30_sa_strict_extrapolation_5m_EXPLORATORY.tif"
)
strict <- terra::ifel(
  mess < 0, 1L, 0L,
  filename = strict_file, overwrite = TRUE,
  wopt = list(datatype = "INT1U", gdal = c("COMPRESS=LZW"))
)
names(strict) <- "MESS_negative_strict_extrapolation"

# Count cells, not independent sites or areal coverage.
valid <- as.numeric(terra::global(
  !is.na(mess), fun = "sum", na.rm = TRUE
)[1, 1])
negative <- as.numeric(terra::global(
  strict, fun = "sum", na.rm = TRUE
)[1, 1])
if (!is.finite(valid) || valid <= 0 || !is.finite(negative)) {
  stop("Invalid cell-count summary.")
}
mess_rng <- terra::global(mess, fun = "range", na.rm = TRUE)
mop_rng <- terra::global(mop_dist, fun = "range", na.rm = TRUE)
summary_tab <- data.frame(
  reference = "western_palaearctic_rectangle_NOT_M",
  variables = paste(variables, collapse = ", "),
  sampling_seed = seed,
  sampled_reference_cells = reference_n,
  valid_transfer_cells = valid,
  MESS_negative_transfer_cells = negative,
  MESS_negative_transfer_pct = 100 * negative / valid,
  MOP_nearest_reference_pct = mop_pct_nearest,
  MOP_nearest_reference_k = k,
  MOP_validation_max_absolute_difference = absdiff,
  MESS_min = as.numeric(mess_rng[1, 1]),
  MESS_max = as.numeric(mess_rng[1, 2]),
  MOP_distance_min = as.numeric(mop_rng[1, 1]),
  MOP_distance_max = as.numeric(mop_rng[1, 2]),
  interpretation = "EXPLORATORY; rectangle is not M; no field sites used",
  stringsAsFactors = FALSE
)
utils::write.csv(
  summary_tab,
  file.path(outdir, "31_MESS_MOP_exploratory_summary.csv"),
  row.names = FALSE
)

# Preview only; not yet a publication-ready figure.
preview <- file.path(outdir, "32_sa_MESS_MOP_exploratory_preview.png")
grDevices::png(preview, width = 3200, height = 1500, res = 200)
tryCatch(
  {
    old_par <- graphics::par(
      mfrow = c(1, 2), mar = c(3.5, 3.5, 4, 5)
    )
    terra::plot(mess, main = "MESS - exploratory rectangle",
                cex.main = 0.9)
    terra::plot(mop_dist,
                main = "MOP distance (higher = less similar)",
                cex.main = 0.9)
    graphics::par(old_par)
  },
  finally = grDevices::dev.off()
)

writeLines(c(
  "Phalangium opilio: EXPLORATORY MESS/MOP climatic-transfer diagnosis.",
  "No Venezuelan field records, field-event tables, or held-out points were read.",
  "No suitability predictions or fitted maxnet/ENMeval models were read.",
  "Do NOT describe the provisional western Palaearctic rectangle as M.",
  paste("Reference climate raster:", normalizePath(west_file, winslash = "/")),
  paste("Transfer climate raster:", normalizePath(sa_file, winslash = "/")),
  paste("WorldClim variables:", paste(variables, collapse = ", ")),
  "WorldClim 2.1 at 5 arcminutes; native units retained.",
  paste("Sampling seed:", seed),
  paste("Sampled reference complete climate cells:", reference_n),
  "Reference draw is random and not an area-weighted sample of environments.",
  "MESS definition: predicts::mess, Elith et al. (2010).",
  "MESS < 0 denotes strict univariate out-of-range conditions.",
  "MOP definition: mean Euclidean distance to closest 1% of standardized",
  "reference conditions; reference-only means and SDs; exact FNN kd tree.",
  "MOP values are continuous distances, without a predefined novelty cutoff.",
  "FNN calculation cross-checked against mop::mop_distance on transfer climate cells.",
  paste("Cross-check maximum absolute difference:", absdiff),
  "MOP nearest-neighbour percent and sample size affect numerical results.",
  "Neither a high nor a low score proves suitability, occupancy or invasion.",
  "When final M and model are frozen, rerun reference-based novelty analysis",
  "and only then extract values at the independent Venezuelan collection sites.",
  paste("terra:", as.character(utils::packageVersion("terra"))),
  paste("predicts:", as.character(utils::packageVersion("predicts"))),
  paste("mop:", as.character(utils::packageVersion("mop"))),
  paste("FNN:", as.character(utils::packageVersion("FNN")))
), file.path(outdir, "33_MESS_MOP_exploratory_provenance.txt"))

cat("\n[R25] COMPLETED EXPLORATORY MESS/MOP (NO FIELD SITES)\n")
print(summary_tab, row.names = FALSE)
cat("\n[R25] Outputs:\n",
    normalizePath(outdir, winslash = "/", mustWork = TRUE), "\n")
cat("[R25] Preview: ", preview, "\n", sep = "")
cat("[R25] NOT a final M, not a final SDM, not external validation.\n")
