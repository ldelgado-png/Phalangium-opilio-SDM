# Phalangium opilio | Full-grid climate-range transfer audit
#
# Run in RStudio after R/06_prepare_climate_and_transfer_diagnostics.R:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/07_full_grid_transfer_range_audit.R")
#
# This is an exploratory extrapolation warning based on the initial
# Western Palaearctic rectangular window, NOT a fitted SDM, MESS, or MOP.
# Venezuelan field observations are deliberately not read by this script.

if (!requireNamespace("terra", quietly = TRUE)) {
  stop("Install terra before running this analysis.")
}
root <- getwd()
d <- file.path(root, "01_datos", "climate_diagnostics")
west_file <- file.path(d, "16_worldclim_western_window_5m.tif")
sa_file <- file.path(d, "17_worldclim_south_america_5m.tif")
cor_file <- file.path(d, "20_predictor_correlation_western_window.csv")
needed <- c(west_file, sa_file, cor_file)
if (!all(file.exists(needed))) {
  stop("Missing climate files in ", d, ". Run script 06 first, or set ",
       "the working directory to the Phalangium_opilio_SDM project folder.")
}

western <- terra::rast(west_file)
south <- terra::rast(sa_file)
variables <- c("BIO1", "BIO4", "BIO12", "BIO15")
if (terra::nlyr(western) != 4L || terra::nlyr(south) != 4L ||
    !identical(names(western), variables) ||
    !identical(names(south), variables)) {
  stop("Unexpected environmental predictor names or layer counts.")
}
if (!terra::same.crs(western, south)) {
  stop("Western and South American rasters have different coordinate systems.")
}

# Global summaries are calculated over ALL valid land raster cells.
ref_min <- as.numeric(terra::global(western, "min", na.rm = TRUE)[, 1])
ref_max <- as.numeric(terra::global(western, "max", na.rm = TRUE)[, 1])
if (any(!is.finite(ref_min) | !is.finite(ref_max))) {
  stop("Invalid reference climatic ranges.")
}

valid <- !is.na(south[[1]])
for (i in 2:4) valid <- valid & !is.na(south[[i]])
all_valid_n <- as.numeric(terra::global(valid, "sum", na.rm = TRUE)[1, 1])
if (!is.finite(all_valid_n) || all_valid_n <= 0) {
  stop("No complete South American climate cells available.")
}
any_outside_count <- terra::ifel(valid, 0, NA)
audit <- vector("list", length(variables))
for (i in seq_along(variables)) {
  below <- valid & south[[i]] < ref_min[i]
  above <- valid & south[[i]] > ref_max[i]
  below_n <- as.numeric(terra::global(below, "sum", na.rm = TRUE)[1, 1])
  above_n <- as.numeric(terra::global(above, "sum", na.rm = TRUE)[1, 1])
  any_outside_count <- any_outside_count +
    terra::ifel(below | above, 1, 0)
  audit[[i]] <- data.frame(
    predictor = variables[i],
    reference_min = ref_min[i],
    reference_max = ref_max[i],
    sa_valid_cells = all_valid_n,
    n_below_reference = below_n,
    n_above_reference = above_n,
    pct_below_reference = round(100 * below_n / all_valid_n, 3),
    pct_above_reference = round(100 * above_n / all_valid_n, 3),
    pct_outside_univariate = round(
      100 * (below_n + above_n) / all_valid_n, 3
    )
  )
}
audit <- do.call(rbind, audit)
rownames(audit) <- NULL

any_novel <- terra::ifel(any_outside_count > 0, 1, 0)
names(any_novel) <- "any_predictor_outside_range"
n_novel <- as.numeric(terra::global(any_novel, "sum", na.rm = TRUE)[1, 1])
all_pct <- round(100 * n_novel / all_valid_n, 3)

# BIO1 classification: 0 = within, 1 = below, 2 = above; NA = no data.
bio1_class <- terra::ifel(
  south[["BIO1"]] < ref_min[1], 1,
  terra::ifel(south[["BIO1"]] > ref_max[1], 2, 0)
)
names(bio1_class) <- "BIO1_climate_range_class"

# VIFs refer to sampled candidate-window environments, not a finalized M.
cor_mat <- as.matrix(utils::read.csv(
  cor_file, row.names = 1, check.names = FALSE
))
if (!identical(rownames(cor_mat), variables) ||
    !identical(colnames(cor_mat), variables)) {
  stop("Correlation matrix must have BIO1, BIO4, BIO12, BIO15 in order.")
}
eigenvalues <- eigen(cor_mat, symmetric = TRUE, only.values = TRUE)$values
if (min(eigenvalues) <= 1e-9) {
  stop("The correlation matrix is singular: VIF cannot be calculated.")
}
vif <- data.frame(
  predictor = variables,
  variance_inflation_factor = round(diag(solve(cor_mat)), 4)
)

utils::write.csv(
  audit, file.path(d, "25_all_cells_climate_range_by_variable.csv"),
  row.names = FALSE
)
utils::write.csv(
  data.frame(n_valid_sa_cells = all_valid_n,
             n_outside_any = n_novel,
             pct_outside_any = all_pct),
  file.path(d, "26_all_cells_climate_range_overall.csv"),
  row.names = FALSE
)
utils::write.csv(
  vif, file.path(d, "27_exploratory_predictor_VIF.csv"),
  row.names = FALSE
)
terra::writeRaster(
  any_novel, file.path(d, "28_sa_any_climate_range_exceedance_5m.tif"),
  overwrite = TRUE, gdal = "COMPRESS=LZW"
)
terra::writeRaster(
  bio1_class, file.path(d, "29_sa_BIO1_range_direction_5m.tif"),
  overwrite = TRUE, gdal = "COMPRESS=LZW"
)
grDevices::png(
  file.path(d, "30_sa_exploratory_climate_range_map.png"),
  width = 1400, height = 1200, res = 160
)
terra::plot(any_novel, main = paste0(
  "Phalangium opilio: South American climate novelty\n",
  "Reference: exploratory Western Palaearctic window"
))
grDevices::dev.off()

cat("\nPHALANGIUM OPILIO | FULL-GRID ENVIRONMENTAL RANGE AUDIT\n")
cat("Valid South American climate cells:", all_valid_n, "\n")
cat("Outside at least one exploratory reference range:",
    n_novel, " (", all_pct, "%)\n", sep = "")
cat("\nExceedance direction (ALL valid cells):\n")
print(audit, row.names = FALSE)
cat("\nApproximate predictor VIF within the sampled reference window:\n")
print(vif, row.names = FALSE)
cat("\nPrivate diagnostic files:", normalizePath(d, winslash = "/"), "\n")
cat("No Venezuelan field localities were used or evaluated here.\n")
cat("The reference rectangle is not the finalized accessible area M.\n")
cat("No SDM has been fitted; novel climate does not imply unsuitable habitat.\n")
