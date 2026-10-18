# Phalangium opilio | Prepare order-specific GBIF sampling effort
#
# In RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/15_prepare_opiliones_effort.R")
#
# Inspects the published effort surface from El-Gabbas (2026).
# The diagnostic does NOT fit models, modify their tuning, assign
# an accessible area M, or inspect held-out Venezuelan observations.

if (!requireNamespace("terra", quietly = TRUE)) {
  stop("terra must be installed with install.packages('terra').")
}
if (!requireNamespace("ecokit", quietly = TRUE)) {
  stop(paste(
    "Install the author's ecokit R package once:",
    "install.packages('remotes');",
    "remotes::install_github('elgabbas/ecokit')",
    "Then rerun this script."
  ))
}
root <- getwd()
data_dir <- file.path(root, "01_datos")
clim_file <- file.path(data_dir, "climate_diagnostics",
                       "16_worldclim_western_window_5m.tif")
presence_file <- file.path(root, "04_resultados_modelo",
                           "pilot_western_palaearctic",
                           "01_pilot_calibration_occurrences.csv")
if (!all(file.exists(c(clim_file, presence_file)))) {
  stop("Missing pilot files. Set getwd() to the Phalangium_opilio_SDM folder.")
}
out_dir <- file.path(data_dir, "sampling_effort")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

bio <- terra::rast(clim_file)
if (!identical(names(bio), c("BIO1", "BIO4", "BIO12", "BIO15"))) {
  stop("Unexpected climate predictor names.")
}
presence <- utils::read.csv(
  presence_file, stringsAsFactors = FALSE,
  colClasses = c(gbifID = "character")
)
xy <- cbind(as.numeric(presence$decimalLongitude),
            as.numeric(presence$decimalLatitude))
if (nrow(xy) != 10426L || any(!is.finite(xy))) {
  stop("The original pilot presences do not match the validated input.")
}

aligned_file <- file.path(
  out_dir, "opiliones_nobs_5km_mean_on_worldclim_5arcmin.tif"
)
source_label <- NA_character_
climate_mask <- !is.na(bio[[1]])
if (file.exists(aligned_file)) {
  message("Resuming from the already-aligned Opiliones effort raster...")
  effort_mean <- terra::rast(aligned_file)
  if (terra::nlyr(effort_mean) != 1L ||
      !identical(names(effort_mean),
                 "mean_Opiliones_observations_in_source_cells") ||
      !isTRUE(terra::compareGeom(effort_mean, bio[[1]],
                                stopOnError = FALSE))) {
    stop("Cached aligned effort raster does not match the pilot ",
         "WorldClim grid. Verify the file before rerunning.")
  }
  source_label <- paste("Cached aligned raster:",
                        normalizePath(aligned_file, winslash = "/"))
} else {
message("Retrieving El-Gabbas (2026) Opiliones observation effort ",
        "(cumulative 1980-2025, native ~5 km grid).")
effort_meta <- ecokit::get_sampling_effort(
  group = "arachnida", descendants = "opiliones",
  metric = "n_obs", years = "total", resolution = 5,
  out_dir = out_dir
)
if (!is.data.frame(effort_meta) ||
    nrow(effort_meta) != 1L ||
    !"local_path" %in% names(effort_meta)) {
  stop("The downloaded effort metadata have an unexpected structure.")
}
effort_path <- as.character(effort_meta$local_path[1])
if (!file.exists(effort_path)) {
  effort_path <- file.path(out_dir, basename(effort_path))
}
if (!file.exists(effort_path)) {
  stop("The ecokit effort raster is not found at the reported local path.")
}
effort <- terra::rast(effort_path)
if (terra::nlyr(effort) != 1L) {
  stop("Expected a single observation-count effort raster.")
}
if (!terra::is.lonlat(effort)) {
  stop("The author's raster is not in expected geographic coordinates.")
}
if (!terra::same.crs(effort, bio)) {
  stop("Effort and climate CRS differ; inspect their EPSG and axes.")
}

# Crop FIRST, to avoid processing an entire global high-resolution raster.
# 5-km effort cells are not identical to 5-arcminute WorldClim cells.
effort_crop <- terra::crop(effort, terra::ext(bio), snap = "out")
if (is.null(effort_crop)) stop("No overlap between effort and climate.")
if (any(terra::global(effort_crop, "min", na.rm = TRUE)[1, 1] < 0)) {
  stop("Effort counts cannot be negative.")
}
message("Computing a diagnostic local average to align unequal grids...")
effort_mean <- terra::resample(
  effort_crop, bio[[1]], method = "average"
)
# Do not interpret these means as total GBIF observation counts
# in the destination cells. This grid is descriptive only.
names(effort_mean) <- "mean_Opiliones_observations_in_source_cells"
effort_mean <- terra::mask(effort_mean, climate_mask, maskvalues = 0)

terra::writeRaster(
  effort_mean, aligned_file, overwrite = TRUE,
  gdal = "COMPRESS=LZW"
)
source_label <- paste("Original downloaded effort raster:",
                      normalizePath(effort_path, winslash = "/"))

}
# terra::extract with an (x,y) coordinate matrix yields raster-value columns
# without the implicit ID field returned for vector geometries. The aligned
# raster is single-layer, so select its only value column by NAME.
extracted <- terra::extract(effort_mean, xy)
expected_value_column <- names(effort_mean)[1]
if (!is.data.frame(extracted) ||
    !(expected_value_column %in% names(extracted)) ||
    nrow(extracted) != nrow(presence)) {
  stop("Unexpected terra::extract output: ",
       paste(names(extracted), collapse = ", "),
       " (", nrow(extracted), " rows).")
}
presence_counts <- suppressWarnings(
  as.numeric(extracted[[expected_value_column]])
)

if (length(presence_counts) != nrow(presence)) {
  stop("Mismatch between presence cells and extracted effort values.")
}
valid_land <- as.numeric(terra::global(climate_mask, "sum", na.rm = TRUE)[1, 1])
has_effort <- terra::ifel(effort_mean > 0, 1, 0)
valid_effort_cells <- as.numeric(
  terra::global(has_effort, "sum", na.rm = TRUE)[1, 1]
)
missing_cells <- as.numeric(
  terra::global(is.na(effort_mean) & climate_mask, "sum",
                na.rm = TRUE)[1, 1]
)
report <- data.frame(
  metric = c(
    "climate_land_cells",
    "cells_with_positive_Opiliones_effort",
    "cells_missing_effort_raster_values",
    "pilot_presence_cells",
    "presence_cells_at_positive_effort",
    "presence_cells_at_zero_effort",
    "presence_cells_at_missing_effort"
  ),
  count = c(
    valid_land, valid_effort_cells, missing_cells, nrow(presence),
    sum(!is.na(presence_counts) & presence_counts > 0),
    sum(!is.na(presence_counts) & presence_counts == 0),
    sum(is.na(presence_counts))
  )
)
utils::write.csv(report, file.path(out_dir,
                                  "opiliones_effort_coverage_audit.csv"),
                 row.names = FALSE)
writeLines(c(
  "El-Gabbas (2026) global GBIF sampling effort",
  "https://doi.org/10.1111/ddi.70205",
  source_label,
  paste("ecokit:", as.character(utils::packageVersion("ecokit"))),
  paste("terra:", as.character(utils::packageVersion("terra"))),
  "Taxon: Arachnida -> Opiliones",
  "Metric: n_obs; cumulative years 1980-2025; source grain approx 5 km.",
  "Original source data are GBIF counts, not verified independent visits.",
  "WorldClim climate grain: 5 arcminutes, 1970-2000.",
  "Resampled mean is an exploratory proxy, NOT conserved record counts.",
  "The focal species may contribute observations to the effort raster.",
  "No absence inference should be made from zero-count cells.",
  "Neither a final background weight nor M has been defined.",
  "Venezuelan field observations were not loaded."
), file.path(out_dir, "opiliones_effort_provenance.txt"))

cat("\nOPILIONES | SAMPLING-EFFORT COVERAGE AUDIT\n")
print(report, row.names = FALSE)
cat("\nSource:", source_label)
cat("\nDiagnostic aligned raster:",
    normalizePath(aligned_file, winslash = "/"), "\n")
cat("No model fitted, no final background selected, ",
    "no Venezuelan field sites assessed.\n")
