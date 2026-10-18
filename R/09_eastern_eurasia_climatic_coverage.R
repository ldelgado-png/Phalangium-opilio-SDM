# Phalangium opilio | Environmental coverage in eastern Eurasia
#
# RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/09_eastern_eurasia_climatic_coverage.R")
#
# Exploratory analysis, not native-range delimitation or model fitting.
# The held-out Venezuelan occurrences are not read or used.

for (pkg in c("terra", "geodata")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is required. Install with install.packages('",
         pkg, "').")
  }
}
root <- getwd()
occ_path <- file.path(root, "01_datos", "coordinatecleaner",
                      "02_all_candidates_with_CC_flags.csv")
if (!file.exists(occ_path)) {
  message("Select 02_all_candidates_with_CC_flags.csv.")
  occ_path <- file.choose()
  if (basename(occ_path) != "02_all_candidates_with_CC_flags.csv") {
    stop("Select the corrected, complete candidate file.")
  }
  root <- dirname(dirname(dirname(occ_path)))
}
d <- file.path(root, "01_datos", "climate_diagnostics")
reference_file <- file.path(d, "16_worldclim_western_window_5m.tif")
if (!file.exists(reference_file)) {
  stop("Missing western-window WorldClim file: ", reference_file,
       ". Please run script 06 first.")
}
occ <- utils::read.csv(occ_path, stringsAsFactors = FALSE,
                       check.names = FALSE, na.strings = c("", "NA"))
required <- c("gbifID", "countryCode", "decimalLongitude",
              "decimalLatitude", "coordinateUncertaintyInMeters",
              ".summary", ".uncertainty_unreported")
if (length(setdiff(required, names(occ))) > 0) {
  stop("Missing fields: ", paste(setdiff(required, names(occ)),
                                  collapse = ", "))
}
occ$.summary <- as.logical(occ$.summary)
occ$.uncertainty_unreported <- as.logical(occ$.uncertainty_unreported)
if (nrow(occ) != 56524L ||
    anyNA(occ$.summary) ||
    sum(occ$.summary) != 50403L ||
    sum(occ$.uncertainty_unreported) != 12898L) {
  stop("The corrected provenance audit is required (script 03).")
}
lon <- suppressWarnings(as.numeric(occ$decimalLongitude))
lat <- suppressWarnings(as.numeric(occ$decimalLatitude))
if (any(!is.finite(lon) | !is.finite(lat))) {
  stop("Invalid candidate coordinates.")
}

# Compare only screened, coordinate-valid candidates in the same latitudinal
# window used in script 08. These cutoffs are descriptive, not species limits.
sel <- occ$.summary & lon >= 60 & lon <= 180 & lat >= 30 & lat <= 72
east <- occ[sel, , drop = FALSE]
if (!nrow(east)) stop("No eastern Eurasian occurrences found.")
east$countryCode[is.na(east$countryCode)] <- "UNSPECIFIED"

cat("Loading the cached WorldClim 2.1 rasters at 5 arcminutes...\n")
clim <- geodata::worldclim_global(
  var = "bio", res = 5,
  path = file.path(root, "01_datos", "clima_WorldClim_2_1"),
  version = "2.1"
)
clim <- clim[[c(1, 4, 12, 15)]]
vars <- c("BIO1", "BIO4", "BIO12", "BIO15")
names(clim) <- vars
ref <- terra::rast(reference_file)
if (!identical(names(ref), vars)) {
  stop("Unexpected Western Palaearctic predictor names.")
}
if (!terra::same.crs(ref, clim)) stop("CRS mismatch between climate rasters.")

xy <- cbind(as.numeric(east$decimalLongitude),
            as.numeric(east$decimalLatitude))
east$worldclim_cell <- terra::cellFromXY(clim[[1]], xy)
valid_cell <- !is.na(east$worldclim_cell)
east <- east[valid_cell, , drop = FALSE]
if (!nrow(east)) stop("No eastward occurrences match WorldClim cells.")

# One occurrence per real climatic raster cell, favoring reported accuracy.
unc <- suppressWarnings(as.numeric(east$coordinateUncertaintyInMeters))
ord <- order(is.na(unc), unc, as.character(east$gbifID), na.last = TRUE)
east <- east[ord, , drop = FALSE]
east <- east[!duplicated(east$worldclim_cell), , drop = FALSE]
vals <- terra::extract(
  clim, cbind(as.numeric(east$decimalLongitude),
              as.numeric(east$decimalLatitude))
)
values <- as.data.frame(vals[, vars, drop = FALSE])
valid_env <- stats::complete.cases(values)
east <- east[valid_env, , drop = FALSE]
values <- values[valid_env, , drop = FALSE]
if (!nrow(east)) stop("No complete climatic measurements in eastern cells.")

min_ref <- as.numeric(terra::global(ref, "min", na.rm = TRUE)[, 1])
max_ref <- as.numeric(terra::global(ref, "max", na.rm = TRUE)[, 1])
if (any(!is.finite(min_ref) | !is.finite(max_ref))) {
  stop("Nonfinite climate-range limits.")
}
below <- sweep(as.matrix(values), 2, min_ref, "<")
above <- sweep(as.matrix(values), 2, max_ref, ">")
novel <- below | above
east$outside_any_reference_range <- rowSums(novel) > 0L
east$outside_reference_variables <- apply(novel, 1, function(v) {
  paste(vars[which(v)], collapse = ";")
})
east$BIO1_range_direction <- ifelse(
  below[, 1], "below", ifelse(above[, 1], "above", "within")
)
east <- cbind(east, values)
rownames(east) <- NULL

groups <- split(seq_len(nrow(east)), east$countryCode)
by_country <- do.call(rbind, lapply(names(groups), function(name) {
  ids <- groups[[name]]
  data.frame(
    countryCode = name,
    cells_with_climate = length(ids),
    cells_outside_any = sum(east$outside_any_reference_range[ids]),
    cells_BIO1_above = sum(east$BIO1_range_direction[ids] == "above"),
    cells_BIO1_below = sum(east$BIO1_range_direction[ids] == "below"),
    stringsAsFactors = FALSE
  )
}))
by_country <- by_country[order(-by_country$cells_with_climate),
                         , drop = FALSE]
rownames(by_country) <- NULL
summary <- data.frame(
  region = "eastern_eurasia_60E_to_180E_30N_to_72N",
  n_screened_occurrences_before_climate_cell_thinning = sum(sel),
  n_raster_cells_with_complete_climate = nrow(east),
  n_outside_any_WP_reference_variable_range =
    sum(east$outside_any_reference_range),
  percent_outside_any = round(
    100 * mean(east$outside_any_reference_range), 2
  ),
  n_BIO1_above_WP_reference = sum(east$BIO1_range_direction == "above"),
  n_BIO1_below_WP_reference = sum(east$BIO1_range_direction == "below"),
  stringsAsFactors = FALSE
)
by_variable <- data.frame(
  predictor = vars,
  WP_reference_min = min_ref,
  WP_reference_max = max_ref,
  eastern_min = apply(values, 2, min),
  eastern_max = apply(values, 2, max),
  eastern_cells_below = colSums(below),
  eastern_cells_above = colSums(above),
  eastern_cells_outside = colSums(novel),
  stringsAsFactors = FALSE
)

dir.create(d, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(
  east, file.path(d, "34_eastern_eurasia_climate_cells.csv"),
  row.names = FALSE, na = ""
)
utils::write.csv(
  by_country, file.path(d, "35_eastern_climatic_coverage_by_country.csv"),
  row.names = FALSE
)
utils::write.csv(
  summary, file.path(d, "36_eastern_climatic_coverage_summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  by_variable, file.path(d, "37_eastern_climatic_ranges_by_variable.csv"),
  row.names = FALSE
)

cat("\nPHALANGIUM OPILIO | EASTWARD CLIMATIC COVERAGE\n")
print(summary, row.names = FALSE)
cat("\nBy country (cell units):\n")
print(by_country, row.names = FALSE)
cat("\nVariable-wise eastward climatic range comparison:\n")
print(by_variable, row.names = FALSE)
cat("\nAll CSV outputs saved in:\n",
    normalizePath(d, winslash = "/", mustWork = TRUE), "\n")
cat("No held-out Venezuelan observations were accessed.\n")
cat("No accessible area M was defined, and no model was fitted.\n")
