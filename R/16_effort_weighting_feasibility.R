# Phalangium opilio | Sampling-effort support and weighting feasibility
#
# Run in RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/16_effort_weighting_feasibility.R")
#
# This is a diagnostic of published Opiliones observation effort and potential
# weighting concentrations, NOT an accessible-area (M) definition or model fit.
# It does not load Venezuelan field records.

for (pkg in c("terra", "ENMeval")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Please install the R package ", pkg, " first.")
  }
}
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
pilot <- file.path(root, "04_resultados_modelo",
                   "pilot_western_palaearctic")
effort_dir <- file.path(root, "01_datos", "sampling_effort")
eff_file <- file.path(
  effort_dir, "opiliones_nobs_5km_mean_on_worldclim_5arcmin.tif"
)
bio_file <- file.path(root, "01_datos", "climate_diagnostics",
                      "16_worldclim_western_window_5m.tif")
presence_file <- file.path(pilot, "01_pilot_calibration_occurrences.csv")
background_file <- file.path(pilot, "02_pilot_background_xy.csv")
evaluation_file <- file.path(pilot, "07_ENMeval_pilot_evaluation.rds")
radius_files <- file.path(
  pilot, paste0("21_candidate_bg_", c(250, 500), "km_mask.tif")
)
expected <- c(eff_file, bio_file, presence_file,
              background_file, evaluation_file, radius_files)
if (!all(file.exists(expected))) {
  stop("Missing previously generated input files: ",
       paste(basename(expected[!file.exists(expected)]),
             collapse = "; "),
       ". Run scripts 11, 14 and 15 first.")
}
bio <- terra::rast(bio_file)
eff <- terra::rast(eff_file)
variables <- c("BIO1", "BIO4", "BIO12", "BIO15")
if (!identical(names(bio), variables) || terra::nlyr(eff) != 1L ||
    !isTRUE(terra::compareGeom(bio[[1]], eff,
                              stopOnError = FALSE))) {
  stop("Climate and effort rasters must share the 5-arcminute grid.")
}
message("Reading existing aligned Opiliones effort and calibration data...")
clim_values <- terra::values(bio, mat = TRUE)
climate_ok <- rowSums(is.finite(clim_values)) == 4L
rm(clim_values)
eff_values <- as.numeric(terra::values(eff, mat = TRUE)[, 1])
if (length(eff_values) != length(climate_ok) ||
    any(eff_values[climate_ok] < 0, na.rm = TRUE)) {
  stop("Unexpected values or invalid effort raster.")
}

p <- utils::read.csv(presence_file, stringsAsFactors = FALSE)
if (!all(c("decimalLongitude", "decimalLatitude") %in% names(p))) {
  stop("Unexpected pilot presence columns.")
}
p_xy <- cbind(as.numeric(p$decimalLongitude),
              as.numeric(p$decimalLatitude))
p_cells <- terra::cellFromXY(bio[[1]], p_xy)
if (nrow(p) != 10426L || anyNA(p_cells) ||
    anyDuplicated(p_cells) || !all(climate_ok[p_cells])) {
  stop("Pilot presence cells differ from the completed model inputs.")
}

bg <- utils::read.csv(background_file, stringsAsFactors = FALSE)
if (!all(c("longitude", "latitude") %in% names(bg))) {
  stop("Unexpected original pilot background columns.")
}
bg_cells <- terra::cellFromXY(
  bio[[1]], as.matrix(bg[, c("longitude", "latitude")])
)
if (nrow(bg) != 10000L || anyNA(bg_cells)) {
  stop("Unexpected original background sample.")
}

# Quantify the observed effort for the original PRESENCE and UNIFORM
# BACKGROUND samples; both have already been used in the pilot model.
sample_support <- data.frame(
  sample = c("pilot_presences", "pilot_uniform_background"),
  n = c(length(p_cells), length(bg_cells)),
  positive_effort = c(
    sum(eff_values[p_cells] > 0, na.rm = TRUE),
    sum(eff_values[bg_cells] > 0, na.rm = TRUE)
  ),
  zero_effort = c(
    sum(eff_values[p_cells] == 0, na.rm = TRUE),
    sum(eff_values[bg_cells] == 0, na.rm = TRUE)
  ),
  missing_effort = c(
    sum(is.na(eff_values[p_cells])),
    sum(is.na(eff_values[bg_cells]))
  )
)
sample_support$percent_positive <- round(
  100 * sample_support$positive_effort / sample_support$n, 2
)

# The masks from script 14 are HYPOTHETICAL domains. They do not establish M.
scenario_masks <- list(
  original_rectangle = climate_ok
)
for (km in c(250, 500)) {
  raster <- terra::rast(file.path(
    pilot, paste0("21_candidate_bg_", km, "km_mask.tif")))
  if (!isTRUE(terra::compareGeom(raster, bio[[1]],
                                stopOnError = FALSE))) {
    stop("Candidate background mask geometry mismatch at ", km, " km.")
  }
  keep <- as.numeric(terra::values(raster, mat = TRUE)[, 1])
  scenario_masks[[paste0("within_", km, "km")]] <-
    climate_ok & !is.na(keep) & keep > 0
}

# Recover original four latitudinal block cutoffs without changing them.
e <- readRDS(evaluation_file)
if (!methods::is(e, "ENMevaluation")) {
  stop("Unexpected saved ENMeval evaluation object.")
}
occ_group <- as.character(ENMeval::eval.occs.grp(e))
occ_saved <- as.data.frame(ENMeval::eval.occs(e))
if (length(occ_group) != 10426L ||
    nrow(occ_saved) != 10426L) {
  stop("Unexpected original fold metadata.")
}
fold_levels <- sort(unique(occ_group))
if (length(fold_levels) != 4L) stop("Expected four spatial folds.")
fold_range <- do.call(rbind, lapply(fold_levels, function(g) {
  lat <- as.numeric(occ_saved[[2]][occ_group == g])
  data.frame(fold = g, lo = min(lat), hi = max(lat),
             median = stats::median(lat))
}))
fold_range <- fold_range[order(fold_range$median), , drop = FALSE]
cutoffs <- vapply(seq_len(3), function(i) {
  (fold_range$hi[i] + fold_range$lo[i + 1L]) / 2
}, numeric(1))
assign_fold <- function(lat) {
  ix <- findInterval(lat, c(-Inf, cutoffs, Inf),
                     rightmost.closed = TRUE)
  fold_range$fold[ix]
}
if (!identical(assign_fold(as.numeric(occ_saved[[2]])),
               occ_group)) {
  stop("Reconstructed fold boundaries differ from the saved ENMeval fit.")
}

# Five a-priori, DESCRIPTIVE weighting scenarios, including two with
# positive baseline mass in raster cells with no GBIF Opiliones record.
# None is selected or used for fitting in this script.
weight_variants <- c(
  "uniform", "raw_positive_only", "sqrt_positive_only",
  "log_positive_only", "one_plus_log_effort"
)
get_weights <- function(x, variant) {
  switch(variant,
    uniform = rep(1, length(x)),
    raw_positive_only = x,
    sqrt_positive_only = sqrt(x),
    log_positive_only = log1p(x),
    one_plus_log_effort = 1 + log1p(x)
  )
}
concentration <- list()
fold_mass <- list()
for (scenario in names(scenario_masks)) {
  # Keep candidate background cells distinct from the presence pixels.
  eligible <- scenario_masks[[scenario]]
  eligible[p_cells] <- FALSE
  cell_ids <- which(eligible)
  effort_here <- eff_values[cell_ids]
  if (!length(cell_ids) || all(is.na(effort_here))) {
    stop("No usable effort data in scenario: ", scenario)
  }
  # Missing values are treated conservatively as no recorded effort
  # in this sensitivity analysis, never as ecological absence.
  effort_here[is.na(effort_here)] <- 0
  latitude <- terra::xyFromCell(bio[[1]], cell_ids)[, 2]
  fold <- assign_fold(latitude)

  for (variant in weight_variants) {
    w <- get_weights(effort_here, variant)
    if (any(!is.finite(w) | w < 0) || sum(w) <= 0) {
      stop("Invalid candidate weights for ", scenario, " / ", variant)
    }
    total <- sum(w)
    p_weights <- w / total
    kish_effective_cells <- 1 / sum(p_weights^2)
    k <- max(1L, ceiling(length(w) * .01))
    mass_in_top_one_pct <- sum(sort(w, decreasing = TRUE)[seq_len(k)]) / total
    concentration[[length(concentration) + 1L]] <- data.frame(
      scenario = scenario,
      weighting_formula = variant,
      eligible_background_cells = length(cell_ids),
      positive_effort_cells = sum(effort_here > 0),
      percent_positive_effort_cells = round(
        100 * mean(effort_here > 0), 2),
      percent_zero_effort_cells = round(
        100 * mean(effort_here == 0), 2),
      percent_zero_weight_cells = round(100 * mean(w == 0), 2),
      effective_candidate_cells = round(kish_effective_cells, 1),
      effective_percent_of_candidate_cells = round(
        100 * kish_effective_cells / length(w), 2),
      percent_weight_mass_top_one_pct_cells = round(
        100 * mass_in_top_one_pct, 2),
      stringsAsFactors = FALSE
    )
    by_fold <- vapply(fold_levels, function(g) {
      sum(w[fold == g])
    }, numeric(1))
    fold_mass[[length(fold_mass) + 1L]] <- data.frame(
      scenario = scenario, weighting_formula = variant,
      fold = fold_levels,
      background_cells = vapply(
        fold_levels, function(g) sum(fold == g), integer(1)),
      percent_candidate_cells = round(
        100 * vapply(fold_levels, function(g) sum(fold == g),
                     integer(1)) / length(cell_ids), 2),
      percent_weight_mass = round(100 * by_fold / total, 2),
      stringsAsFactors = FALSE
    )
  }
}
concentration <- do.call(rbind, concentration)
fold_mass <- do.call(rbind, fold_mass)
rownames(concentration) <- NULL
rownames(fold_mass) <- NULL
utils::write.csv(
  sample_support, file.path(
    effort_dir, "16_effort_support_pilot_samples.csv"),
  row.names = FALSE
)
utils::write.csv(
  concentration, file.path(
    effort_dir, "17_effort_weighting_concentration.csv"),
  row.names = FALSE
)
utils::write.csv(
  fold_mass, file.path(
    effort_dir, "18_effort_weight_mass_by_fold.csv"),
  row.names = FALSE
)
writeLines(c(
  "Phalangium opilio | candidate Opiliones effort-weight sensitivity",
  "https://doi.org/10.1111/ddi.70205",
  paste("Evaluated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "Effort input: mean of native approx 5 km n_obs cells resampled to 5 arcminutes.",
  "WorldClim predictors: BIO1, BIO4, BIO12, BIO15.",
  "Original benchmark is a rectangle; 250 and 500 km masks are hypothetical.",
  "Effort counts may include Phalangium opilio records.",
  "Kish-effective support measures concentration of candidate weights only.",
  "No proposed weight is a proven correction for sampling bias.",
  "No model was fitted or selected. Venezuelan field sites were not read."
), file.path(effort_dir, "effort_weighting_feasibility_provenance.txt"))

cat("\nPHALANGIUM OPILIO | OPILIONES EFFORT-WEIGHT SUPPORT\n")
print(sample_support, row.names = FALSE)
cat("\nDiagnostic weight concentrations (NOT calibrated models):\n")
print(concentration, row.names = FALSE)
cat("\nCandidate weight mass by latitudinal fold:\n")
print(fold_mass, row.names = FALSE)
cat("\nFiles saved under:\n",
    normalizePath(effort_dir, winslash = "/", mustWork = TRUE), "\n")
cat("No background-weight formula selected, no model refitted, ",
    "and no Venezuelan field records accessed.\n")
