# Phalangium opilio | Initial maxnet / ENMeval modelling run
#
# RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/11_pilot_ENMeval_maxnet.R")
#
# This is an INITIAL, exploratory calibration using the Western Palaearctic
# climate window. The rectangular window is NOT a biogeographically justified
# accessible area M. Its background is NOT the final background design.
#
# Venezuelan field records are STRICTLY HELD OUT: they are never loaded here,
# and are not used for tuning, evaluation, thresholds, or model selection.
#
# The script fits 6 candidate models and saves spatial cross-validation
# results. A fixed-a-priori LQ, RM=2 prediction can be made for visual inspection
# only; it must not be called the final model or external validation.

required_packages <- c("terra", "ENMeval", "maxnet")
unavailable <- required_packages[!vapply(required_packages,
                                         requireNamespace, logical(1),
                                         quietly = TRUE)]
if (length(unavailable)) {
  message("Installing: ", paste(unavailable, collapse = ", "))
  utils::install.packages(unavailable,
                          repos = "https://cloud.r-project.org")
}
unavailable <- required_packages[!vapply(required_packages,
                                         requireNamespace, logical(1),
                                         quietly = TRUE)]
if (length(unavailable)) {
  stop("Unavailable packages: ", paste(unavailable, collapse = ", "))
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
data_dir <- file.path(root, "01_datos")
candidate_file <- file.path(data_dir, "coordinatecleaner",
                            "02_all_candidates_with_CC_flags.csv")
raster_file <- file.path(data_dir, "climate_diagnostics",
                         "16_worldclim_western_window_5m.tif")
sa_file <- file.path(data_dir, "climate_diagnostics",
                     "17_worldclim_south_america_5m.tif")
missing_inputs <- c(candidate_file, raster_file)
missing_inputs <- missing_inputs[!file.exists(missing_inputs)]
if (length(missing_inputs)) {
  stop("Required inputs absent; open your Phalangium_opilio_SDM ",
       "folder as the R working directory. Missing: ",
       paste(missing_inputs, collapse = "; "))
}

out <- file.path(root, "04_resultados_modelo",
                 "pilot_western_palaearctic")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out, "terra_temporary"),
           recursive = TRUE, showWarnings = FALSE)
terra::terraOptions(
  tempdir = file.path(out, "terra_temporary"),
  memfrac = 0.6, progress = 1
)

message("Loading corrected GBIF candidates and WorldClim raster...")
x <- utils::read.csv(candidate_file, check.names = FALSE,
                     stringsAsFactors = FALSE,
                     colClasses = c(gbifID = "character"),
                     na.strings = c("", "NA"))
fields <- c("gbifID", "decimalLongitude", "decimalLatitude",
            "coordinateUncertaintyInMeters", "basisOfRecord",
            ".summary", ".uncertainty_unreported")
if (length(setdiff(fields, names(x)))) {
  stop("Missing columns: ", paste(setdiff(fields, names(x)),
                                  collapse = ", "))
}
x$.summary <- as.logical(x$.summary)
x$.uncertainty_unreported <- as.logical(x$.uncertainty_unreported)
if (nrow(x) != 56524L || anyNA(x$.summary) ||
    sum(x$.summary) != 50403L ||
    sum(x$.uncertainty_unreported) != 12898L) {
  stop("Unexpected GBIF audit totals. Rerun source restoration script 03.")
}
bio <- terra::rast(raster_file)
variables <- c("BIO1", "BIO4", "BIO12", "BIO15")
if (terra::nlyr(bio) != 4L ||
    !identical(names(bio), variables)) {
  stop("Expected WorldClim predictor order BIO1, BIO4, BIO12, BIO15.")
}
if (terra::is.lonlat(bio) != TRUE) {
  stop("This workflow expects geographic lon/lat WorldClim rasters.")
}
lon <- suppressWarnings(as.numeric(x$decimalLongitude))
lat <- suppressWarnings(as.numeric(x$decimalLatitude))
if (any(!is.finite(lon) | !is.finite(lat))) {
  stop("Unexpected non-finite coordinates in corrected GBIF candidates.")
}

# The provisional calibration window matches the previously studied
# Western Palaearctic rectangle (12 W to 60 E, 30 N to 72 N).
in_window <- lon >= -12 & lon <= 60 & lat >= 30 & lat <= 72
accepted <- which(x$.summary & in_window)
p <- x[accepted, , drop = FALSE]
xy <- cbind(lon[accepted], lat[accepted])
cells <- terra::cellFromXY(bio[[1]], xy)
valid_cell <- !is.na(cells)
p <- p[valid_cell, , drop = FALSE]
cells <- cells[valid_cell]
if (length(cells) < 1000L) stop("Insufficient calibration occurrences.")
p$worldclim_cell <- cells

# Choose one occurrence per ACTUAL 5-arcminute raster cell, prioritizing
# more precise reported coordinates; do not treat records in one cell
# as independent climatic observations.
unc <- suppressWarnings(as.numeric(p$coordinateUncertaintyInMeters))
record_priority <- match(
  p$basisOfRecord,
  c("PRESERVED_SPECIMEN", "HUMAN_OBSERVATION",
    "MACHINE_OBSERVATION", "MATERIAL_CITATION",
    "OCCURRENCE", "MATERIAL_SAMPLE")
)
record_priority[is.na(record_priority)] <- 99L
ord <- order(is.na(unc), unc, record_priority, p$gbifID, na.last = TRUE)
p <- p[ord, , drop = FALSE]
p <- p[!duplicated(p$worldclim_cell), , drop = FALSE]
p_xy <- data.frame(
  longitude = as.numeric(p$decimalLongitude),
  latitude = as.numeric(p$decimalLatitude)
)
p_env <- terra::extract(bio, as.matrix(p_xy))
keep <- stats::complete.cases(p_env[, variables, drop = FALSE])
p <- p[keep, , drop = FALSE]
p_xy <- p_xy[keep, , drop = FALSE]
if (nrow(p_xy) < 1000L) stop("Too few climate-valid presence cells.")
rownames(p_xy) <- NULL
rownames(p) <- NULL

# The pilot background is sampled from the full climatic land coverage
# of this rectangle. This is a deliberate provisional assumption, not M.
valid <- !is.na(bio[[1]])
for (i in 2:4) valid <- valid & !is.na(bio[[i]])
valid <- terra::ifel(valid, 1, NA)
set.seed(20261017L)
bg_sample <- terra::spatSample(
  valid, size = 16000L, method = "random",
  na.rm = TRUE, as.df = TRUE, values = FALSE, xy = TRUE,
  warn = FALSE
)
bg_sample <- as.data.frame(bg_sample)
if (ncol(bg_sample) < 2L) {
  stop("Background sampling returned no coordinate columns.")
}
bg_xy <- bg_sample[, 1:2, drop = FALSE]
names(bg_xy) <- c("longitude", "latitude")
bg_xy$longitude <- as.numeric(bg_xy$longitude)
bg_xy$latitude <- as.numeric(bg_xy$latitude)
bg_cell <- terra::cellFromXY(bio[[1]], as.matrix(bg_xy))
presence_cells <- terra::cellFromXY(bio[[1]], as.matrix(p_xy))
bg_keep <- !is.na(bg_cell) &
           !(bg_cell %in% presence_cells) &
           !duplicated(bg_cell)
bg_xy <- bg_xy[bg_keep, , drop = FALSE]
if (nrow(bg_xy) < 5000L) {
  stop("Too few independent background cells: ", nrow(bg_xy),
       ". Check the geographic window and raster mask.")
}
if (nrow(bg_xy) > 10000L) {
  bg_xy <- bg_xy[seq_len(10000L), , drop = FALSE]
}
bg_env <- terra::extract(bio, as.matrix(bg_xy))
complete <- stats::complete.cases(bg_env[, variables, drop = FALSE])
bg_xy <- bg_xy[complete, , drop = FALSE]
bg_env <- bg_env[complete, variables, drop = FALSE]
if (nrow(bg_xy) < 5000L) stop("Insufficient climate-valid background.")
rownames(bg_xy) <- NULL

# We record these inputs for exact reproducibility. None contain
# independently held-out South American field observations.
utils::write.csv(p, file.path(out, "01_pilot_calibration_occurrences.csv"),
                 row.names = FALSE, na = "")
utils::write.csv(bg_xy, file.path(out, "02_pilot_background_xy.csv"),
                 row.names = FALSE)
if (nrow(bg_env) > 4) {
  cm <- stats::cor(bg_env, use = "complete.obs")
  vif <- diag(solve(cm))
  utils::write.csv(cm, file.path(out, "03_pilot_background_correlation.csv"))
  utils::write.csv(
    data.frame(predictor = names(vif), VIF = as.numeric(vif)),
    file.path(out, "04_pilot_background_VIF.csv"),
    row.names = FALSE
  )
}

# Six a priori tuning combinations and four spatially structured blocks.
# Every tuning criterion uses calibration-region occurrences only.
message("\nStarting ENMeval / maxnet pilot with ",
        nrow(p_xy), " presence cells and ", nrow(bg_xy),
        " background cells. Six settings, block cross-validation.")
message("This step may take several minutes on a desktop computer.")
set.seed(20261017L)
fit <- ENMeval::ENMevaluate(
  occs = p_xy,
  envs = bio,
  bg = bg_xy,
  tune.args = list(fc = c("L", "LQ", "LQH"), rm = c(1, 2)),
  partitions = "block",
  partition.settings = list(orientation = "lat_lat"),
  algorithm = "maxnet",
  other.settings = list(
    abs.auc.diff = FALSE,
    pred.type = "cloglog",
    validation.bg = "partition"
  ),
  doClamp = TRUE,
  raster.preds = FALSE,
  overlap = FALSE,
  parallel = FALSE,
  quiet = FALSE
)
res <- ENMeval::eval.results(fit)
if (!nrow(res)) stop("ENMeval returned an empty results table.")
models <- ENMeval::eval.models(fit)
if (!length(models)) stop("No fitted maxnet models were returned.")
utils::write.csv(res, file.path(out, "05_ENMeval_tuning_results.csv"),
                 row.names = FALSE, na = "")
saveRDS(models, file.path(out, "06_maxnet_pilot_models.rds"))
# The raw evaluation object can be large, but preserves partitions and
# additional diagnostics for methodological inspection.
saveRDS(fit, file.path(out, "07_ENMeval_pilot_evaluation.rds"))

# A PREDECLARED baseline is used for mapping, not the highest-scoring model
# and not one selected using any Venezuelan field observations.
baseline_name <- "fc.LQ_rm.2"
if (baseline_name %in% names(models)) {
  baseline <- models[[baseline_name]]
  fit_window_pred <- ENMeval::maxnet.predictRaster(
    baseline, bio, pred.type = "cloglog", doClamp = TRUE
  )
  names(fit_window_pred) <- "relative_climate_suitability_pilot"
  terra::writeRaster(
    fit_window_pred,
    file.path(out, "08_pilot_western_window_LQ_rm2_cloglog.tif"),
    overwrite = TRUE, gdal = "COMPRESS=LZW"
  )
  # South American layer is an exploratory transfer visualization.
  # It is NOT used to examine held-out Venezuelan field localities.
  if (file.exists(sa_file)) {
    sa <- terra::rast(sa_file)
    if (!identical(names(sa), variables)) {
      stop("The South American projection has unexpected predictor names.")
    }
    projected <- ENMeval::maxnet.predictRaster(
      baseline, sa, pred.type = "cloglog", doClamp = TRUE
    )
    names(projected) <- "relative_climate_suitability_pilot"
    dest <- file.path(
      out, "09_pilot_south_america_LQ_rm2_cloglog_NOT_FINAL.tif"
    )
    terra::writeRaster(projected, dest, overwrite = TRUE,
                       gdal = "COMPRESS=LZW")
    grDevices::png(
      file.path(out, "10_pilot_south_america_NOT_FINAL.png"),
      width = 1800, height = 1400, res = 160
    )
    terra::plot(
      projected,
      main = "Phalangium opilio | Initial climate suitability (pilot)",
      col = hcl.colors(90, "YlOrRd")
    )
    grDevices::dev.off()
  }
} else {
  warning("Baseline model ", baseline_name,
          " not found. Available fitted models: ",
          paste(names(models), collapse = ", "),
          ". Tuning results and models are saved without a map.")
}

writeLines(c(
  "Phalangium opilio - exploratory ENMeval/maxnet pilot",
  paste("Executed:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("R version:", R.version.string),
  paste("ENMeval:", as.character(utils::packageVersion("ENMeval"))),
  paste("terra:", as.character(utils::packageVersion("terra"))),
  paste("maxnet:", as.character(utils::packageVersion("maxnet"))),
  "GBIF DOI: https://doi.org/10.15468/dl.9gn3qv",
  paste("Calibration presences (unique raster cells):", nrow(p_xy)),
  paste("Background cells:", nrow(bg_xy)),
  "WorldClim v2.1: BIO1, BIO4, BIO12, BIO15; 5 arc-minutes.",
  "Initial domain: Western Palaearctic -12..60 E, 30..72 N.",
  "The provisional rectangular background is NOT the justified M.",
  "Cross-validation: ENMeval blocks; orientation = lat_lat.",
  "Feature classes L, LQ, LQH; regularization multipliers 1 and 2.",
  "Baseline visualization is a priori LQ, RM=2, not the optimal model.",
  "Venezuelan field occurrences NOT read, tuned against, or evaluated.",
  "Outputs are exploratory and NOT publication-ready SDM results."
), file.path(out, "11_pilot_execution_metadata.txt"))

cat("\nPHALANGIUM OPILIO | FIRST ENMEVAL / MAXNET FIT COMPLETED\n")
cat("Pilot calibration presences:", nrow(p_xy), "\n")
cat("Pilot background cells:", nrow(bg_xy), "\n")
cat("Tuned settings evaluated:", nrow(res), "\n")
available_metrics <- intersect(
  c("tune.args", "fc", "rm", "auc.val.avg",
    "or.10p.avg", "cbi.val.avg", "AICc", "delta.AICc",
    "ncoef"), names(res)
)
print(res[, available_metrics, drop = FALSE], row.names = FALSE)
cat("\nGenerated files:\n",
    normalizePath(out, winslash = "/", mustWork = TRUE), "\n")
cat("The Venezuelan field records were not accessed.\n")
cat("The pilot model and projection are NOT final.\n")
