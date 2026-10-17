# Phalangium opilio | Climatic predictor preparation and transfer diagnostics
# RStudio entry point:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/06_prepare_climate_and_transfer_diagnostics.R")
#
# Requires the corrected candidate file from the CoordinateCleaner workflow.
# Output: exploratory climate layers and environmental diagnostics; NO model fit.
# WorldClim v2.1, 1970-2000 climatology, 5 arc-minutes.

needed <- c("terra", "geodata", "rnaturalearth")
missing_packages <- needed[!vapply(needed, requireNamespace,
                                  logical(1), quietly = TRUE)]
if (length(missing_packages)) {
  message("Installing missing packages: ",
          paste(missing_packages, collapse = ", "))
  utils::install.packages(missing_packages,
                          repos = "https://cloud.r-project.org")
}
missing_packages <- needed[!vapply(needed, requireNamespace,
                                  logical(1), quietly = TRUE)]
if (length(missing_packages)) {
  stop("Install these packages manually before continuing: ",
       paste(missing_packages, collapse = ", "))
}

root <- getwd()
candidate_file <- file.path(
  root, "01_datos", "coordinatecleaner",
  "02_all_candidates_with_CC_flags.csv"
)
if (!file.exists(candidate_file)) {
  message("Select the corrected file '02_all_candidates_with_CC_flags.csv'.")
  candidate_file <- file.choose()
  if (basename(candidate_file) != "02_all_candidates_with_CC_flags.csv") {
    stop("Incorrect file selected.")
  }
  root <- dirname(dirname(dirname(candidate_file)))
}
data_dir <- file.path(root, "01_datos")
climate_dir <- file.path(data_dir, "clima_WorldClim_2_1")
output_dir <- file.path(data_dir, "climate_diagnostics")
dir.create(climate_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

occ <- utils::read.csv(
  candidate_file, stringsAsFactors = FALSE, check.names = FALSE
)
fields <- c("gbifID", "decimalLongitude", "decimalLatitude",
            "coordinateUncertaintyInMeters", ".summary",
            ".uncertainty_unreported")
if (length(setdiff(fields, names(occ)))) {
  stop("Required fields absent: ",
       paste(setdiff(fields, names(occ)), collapse = ", "))
}
occ$.summary <- as.logical(occ$.summary)
occ$.uncertainty_unreported <- as.logical(occ$.uncertainty_unreported)
if (nrow(occ) != 56524L || sum(occ$.summary, na.rm = TRUE) != 50403L ||
    sum(occ$.uncertainty_unreported, na.rm = TRUE) != 12898L) {
  stop("Unexpected candidate totals: run the corrected provenance audit first.")
}
lon <- suppressWarnings(as.numeric(occ$decimalLongitude))
lat <- suppressWarnings(as.numeric(occ$decimalLatitude))
if (any(!is.finite(lon) | !is.finite(lat))) stop("Invalid occurrence coordinates.")

message("Downloading/loading WorldClim 2.1 bioclimatic rasters ",
        "at 5 arc-minutes...")
world <- geodata::worldclim_global(
  var = "bio", res = 5, path = climate_dir, version = "2.1"
)
if (is.null(world) || terra::nlyr(world) != 19L) {
  stop("WorldClim acquisition did not return 19 bioclimatic layers.")
}
bio <- world[[c(1, 4, 12, 15)]]
names(bio) <- c("BIO1", "BIO4", "BIO12", "BIO15")
rm(world)
gc(verbose = FALSE)

# The rectangles are used for environmental coverage diagnostics only.
# Their boundaries must not be described as the species' accessible area (M).
temperate_window <- terra::ext(-12, 35, 35, 72)
western_window <- terra::ext(-12, 60, 30, 72)
temperate_clim <- terra::crop(bio, temperate_window)
western_clim <- terra::crop(bio, western_window)

message("Preparing a South American projection MASK from land polygons...")
south_america <- rnaturalearth::ne_countries(
  continent = "South America", scale = 110, returnclass = "sv"
)
if (is.null(south_america) || nrow(south_america) < 5) {
  stop("Natural Earth did not return expected South American polygons.")
}
if (!terra::same.crs(south_america, bio)) {
  south_america <- terra::project(south_america, terra::crs(bio))
}
# Include most offshore islands and the full continent in the initial extent.
sa_crop <- terra::crop(bio, terra::ext(-94, -32, -57, 15))
sa_clim <- terra::mask(sa_crop, south_america)
if (terra::nlyr(sa_clim) != 4L) stop("Incorrect South American climate stack.")

path_west <- file.path(output_dir, "16_worldclim_western_window_5m.tif")
path_sa <- file.path(output_dir, "17_worldclim_south_america_5m.tif")
terra::writeRaster(western_clim, path_west, overwrite = TRUE,
                   gdal = c("COMPRESS=LZW"))
terra::writeRaster(sa_clim, path_sa, overwrite = TRUE,
                   gdal = c("COMPRESS=LZW"))

# Select one occurrence per ACTUAL WorldClim raster cell. This supersedes
# provisional arithmetic 5-arcminute grid IDs and ensures raster alignment.
pick_records <- function(clim, xmin, xmax, ymin, ymax) {
  valid <- occ$.summary & lon >= xmin & lon <= xmax &
           lat >= ymin & lat <= ymax
  candidate <- occ[which(valid), , drop = FALSE]
  xy <- cbind(as.numeric(candidate$decimalLongitude),
              as.numeric(candidate$decimalLatitude))
  climate_cells <- terra::cellFromXY(clim[[1]], xy)
  good <- !is.na(climate_cells)
  candidate <- candidate[good, , drop = FALSE]
  climate_cells <- climate_cells[good]
  if (!length(climate_cells)) stop("No valid cells found for ", xmin, xmax)
  candidate$worldclim_cell <- climate_cells
  unc <- suppressWarnings(
    as.numeric(candidate$coordinateUncertaintyInMeters)
  )
  ord <- order(is.na(unc), unc, as.character(candidate$gbifID),
               na.last = TRUE)
  candidate <- candidate[ord, , drop = FALSE]
  candidate <- candidate[
    !duplicated(candidate$worldclim_cell), , drop = FALSE
  ]
  extracted <- terra::extract(
    clim,
    cbind(as.numeric(candidate$decimalLongitude),
          as.numeric(candidate$decimalLatitude))
  )
  values <- as.data.frame(extracted)
  if (!all(names(bio) %in% names(values))) {
    stop("Environmental extraction failed to return four BIO variables.")
  }
  values <- values[, names(bio), drop = FALSE]
  valid_climate <- stats::complete.cases(values)
  candidate <- candidate[valid_climate, , drop = FALSE]
  values <- values[valid_climate, , drop = FALSE]
  rownames(candidate) <- NULL
  rownames(values) <- NULL
  cbind(candidate, values)
}

temperate_points <- pick_records(temperate_clim, -12, 35, 35, 72)
western_points <- pick_records(western_clim, -12, 60, 30, 72)
write.csv(
  temperate_points,
  file.path(output_dir, "18_temperate_window_climate_occurrences.csv"),
  row.names = FALSE, na = ""
)
write.csv(
  western_points,
  file.path(output_dir, "19_western_window_climate_occurrences.csv"),
  row.names = FALSE, na = ""
)

# Descriptive correlations based on sampled available environments.
# Sampling here is NOT an ENMeval background sample or a bias correction.
set.seed(20261017)
reference <- terra::spatSample(
  western_clim, size = 12000, method = "random",
  na.rm = TRUE, as.df = TRUE, values = TRUE
)
reference <- reference[, names(bio), drop = FALSE]
reference <- reference[stats::complete.cases(reference), , drop = FALSE]
if (nrow(reference) < 1000) {
  stop("Too few nonmissing western-window climate cells sampled.")
}
cor_matrix <- stats::cor(reference, method = "pearson")
write.csv(cor_matrix,
          file.path(output_dir, "20_predictor_correlation_western_window.csv"))
print(round(cor_matrix, 3))

# A simple environmental-range check of land pixels in South America.
# NOT a formal MESS, MOP, ExDet or calibration-transfer validation.
minimum <- terra::global(western_clim, "min", na.rm = TRUE)[, 1]
maximum <- terra::global(western_clim, "max", na.rm = TRUE)[, 1]
if (any(!is.finite(minimum) | !is.finite(maximum))) {
  stop("Could not calculate western-window environmental ranges.")
}
set.seed(20261018)
south_sample <- terra::spatSample(
  sa_clim, size = 12000, method = "random",
  na.rm = TRUE, as.df = TRUE, values = TRUE
)
south_sample <- south_sample[
  stats::complete.cases(south_sample[, names(bio), drop = FALSE]),
  names(bio), drop = FALSE
]
if (nrow(south_sample) < 1000) {
  stop("Too few nonmissing South American climate cells sampled.")
}
south_values <- as.matrix(south_sample)
below <- sweep(south_values, 2, minimum, "<")
above <- sweep(south_values, 2, maximum, ">")
outside <- below | above
range_audit <- data.frame(
  predictor = names(bio),
  min_reference = as.numeric(minimum),
  max_reference = as.numeric(maximum),
  pct_sa_sample_outside_reference_range =
    round(100 * colMeans(outside), 2)
)
write.csv(
  range_audit,
  file.path(output_dir, "21_climate_range_transfer_diagnostic.csv"),
  row.names = FALSE
)
pct_any <- 100 * mean(rowSums(outside) > 0)

# Optional independent field observations, which must never be silently
# merged into the model-fitting calibration occurrences.
field_path <- file.path(data_dir, "coordinatecleaner",
                        "00_registros_Venezuela_manuscrito.csv")
if (file.exists(field_path)) {
  field <- utils::read.csv(field_path, stringsAsFactors = FALSE)
  if (all(c("decimalLongitude", "decimalLatitude") %in% names(field))) {
    extracted <- terra::extract(
      sa_clim,
      cbind(as.numeric(field$decimalLongitude),
            as.numeric(field$decimalLatitude))
    )
    if (all(names(bio) %in% names(extracted))) {
      field <- cbind(field, extracted[, names(bio), drop = FALSE])
      write.csv(
        field, file.path(output_dir, "22_venezuelan_field_climate_private.csv"),
        row.names = FALSE, na = ""
      )
    }
  }
}

metadata <- c(
  "Phalangium opilio environmental diagnostics",
  "GBIF DOI https://doi.org/10.15468/dl.9gn3qv",
  paste("R:", R.version.string),
  paste("terra:", as.character(utils::packageVersion("terra"))),
  paste("geodata:", as.character(utils::packageVersion("geodata"))),
  paste("rnaturalearth:", as.character(utils::packageVersion("rnaturalearth"))),
  "WorldClim v2.1 bioclimatic variables at 5 arcminutes (1970-2000).",
  "Predictors: BIO1, BIO4, BIO12, BIO15.",
  "The western calibration window is exploratory, not a defended accessible area M.",
  "South American cells are masked using Natural Earth 1:110m country polygons.",
  "Range checks are descriptive and are not MESS/MOP/ExDet analyses.",
  "Climate sampling and candidate occurrences do not constitute fitted SDMs."
)
writeLines(metadata, file.path(output_dir, "23_environmental_provenance.txt"))

cat("\nPHALANGIUM OPILIO | ENVIRONMENTAL COVERAGE DIAGNOSTICS\n")
cat("Climate: WorldClim v2.1, 5 arcminutes; 4 BIO predictors\n")
cat("Exploratory native-range cells with extracted climate:\n")
cat("  Temperate Europe:", nrow(temperate_points), "\n")
cat("  Western Palaearctic:", nrow(western_points), "\n")
cat("Correlation matrix printed above.\n")
cat("\nPercent of sampled South American land cells outside at least one\n")
cat("western-window environmental variable range:",
    round(pct_any, 2), "%\n")
cat("\nUnivariate range comparisons:\n")
print(range_audit, row.names = FALSE)
cat("\nFiles generated at:\n",
    normalizePath(output_dir, winslash = "/", mustWork = TRUE), "\n")
cat("NO species-distribution model has been fitted.\n")
