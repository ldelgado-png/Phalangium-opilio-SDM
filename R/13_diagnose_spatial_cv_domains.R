# Phalangium opilio | Diagnostic of spatial folds, climate and background
#
# Run in RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/13_diagnose_spatial_cv_domains.R")
#
# Uses the saved ENMeval object and WorldClim raster from the original pilot.
# Does not fit, tune or select models; does not access Venezuelan field sites.

if (!requireNamespace("ENMeval", quietly = TRUE) ||
    !requireNamespace("terra", quietly = TRUE)) {
  stop("ENMeval and terra must be installed.")
}
root <- getwd()
out <- file.path(root, "04_resultados_modelo", "pilot_western_palaearctic")
model_path <- file.path(out, "07_ENMeval_pilot_evaluation.rds")
if (!file.exists(model_path)) {
  message("Select 07_ENMeval_pilot_evaluation.rds in the pilot folder.")
  model_path <- file.choose()
  if (basename(model_path) != "07_ENMeval_pilot_evaluation.rds") {
    stop("Incorrect ENMeval model file.")
  }
  out <- dirname(model_path)
  root <- dirname(dirname(out))
}
raster_path <- file.path(root, "01_datos", "climate_diagnostics",
                         "16_worldclim_western_window_5m.tif")
if (!file.exists(raster_path)) {
  message("Select 16_worldclim_western_window_5m.tif.")
  raster_path <- file.choose()
  if (basename(raster_path) != "16_worldclim_western_window_5m.tif") {
    stop("Incorrect predictor raster.")
  }
}
message("Loading saved evaluation and predictors; no model fitting...")
e <- readRDS(model_path)
if (!methods::is(e, "ENMevaluation")) {
  stop("The saved object is not of class ENMevaluation.")
}
occs <- as.data.frame(ENMeval::eval.occs(e))
bg <- as.data.frame(ENMeval::eval.bg(e))
og <- as.character(ENMeval::eval.occs.grp(e))
bg_g <- as.character(ENMeval::eval.bg.grp(e))
vars <- c("BIO1", "BIO4", "BIO12", "BIO15")
bio <- terra::rast(raster_path)
if (!identical(names(bio), vars)) stop("Unexpected climate layers.")
if (nrow(occs) != 10426L || nrow(bg) != 10000L ||
    length(og) != nrow(occs) || length(bg_g) != nrow(bg)) {
  stop("The saved pilot dimensions do not match the documented run.")
}
groups <- sort(unique(og))
if (length(groups) != 4L || anyNA(og) ||
    anyNA(bg_g) || !setequal(groups, unique(bg_g))) {
  stop("Expected four complete presence/background block groups.")
}

# Coordinates are always longitude, latitude in the first two columns
# of the evaluated occurrence and background data frames.
occ_xy <- data.frame(lon = as.numeric(occs[[1]]),
                     lat = as.numeric(occs[[2]]))
bg_xy <- data.frame(lon = as.numeric(bg[[1]]),
                    lat = as.numeric(bg[[2]]))
if (any(!is.finite(as.matrix(occ_xy))) ||
    any(!is.finite(as.matrix(bg_xy)))) {
  stop("Non-finite occurrence/background coordinates.")
}
occ_ex <- as.data.frame(terra::extract(bio, as.matrix(occ_xy)))
bg_ex <- as.data.frame(terra::extract(bio, as.matrix(bg_xy)))
if (!all(vars %in% names(occ_ex)) ||
    !all(vars %in% names(bg_ex))) {
  stop("Could not extract predictor values for all model records.")
}
oenv <- occ_ex[, vars, drop = FALSE]
benv <- bg_ex[, vars, drop = FALSE]
if (anyNA(oenv) || anyNA(benv)) {
  stop("Missing predictor values: inspect raster and evaluation coordinates.")
}

geo <- do.call(rbind, lapply(groups, function(g) {
  oi <- which(og == g)
  bi <- which(bg_g == g)
  data.frame(
    fold = g,
    n_occurrences = length(oi),
    n_background = length(bi),
    background_percent = round(100 * length(bi) / nrow(bg), 2),
    presence_lon_min = min(occ_xy$lon[oi]),
    presence_lon_max = max(occ_xy$lon[oi]),
    presence_lat_min = min(occ_xy$lat[oi]),
    presence_lat_max = max(occ_xy$lat[oi]),
    background_lon_min = min(bg_xy$lon[bi]),
    background_lon_max = max(bg_xy$lon[bi]),
    background_lat_min = min(bg_xy$lat[bi]),
    background_lat_max = max(bg_xy$lat[bi]),
    median_presence_lat = stats::median(occ_xy$lat[oi]),
    median_background_lat = stats::median(bg_xy$lat[bi]),
    stringsAsFactors = FALSE
  )
}))
rownames(geo) <- NULL

env_summary <- do.call(rbind, lapply(groups, function(g) {
  oi <- which(og == g)
  bi <- which(bg_g == g)
  do.call(rbind, lapply(vars, function(v) {
    data.frame(
      fold = g, predictor = v,
      n_presences = length(oi),
      n_background = length(bi),
      presence_median = stats::median(oenv[[v]][oi]),
      background_median = stats::median(benv[[v]][bi]),
      presence_q05 = unname(stats::quantile(oenv[[v]][oi], 0.05)),
      presence_q95 = unname(stats::quantile(oenv[[v]][oi], 0.95)),
      background_q05 = unname(stats::quantile(benv[[v]][bi], 0.05)),
      background_q95 = unname(stats::quantile(benv[[v]][bi], 0.95)),
      stringsAsFactors = FALSE
    )
  }))
}))
rownames(env_summary) <- NULL

# Exploratory calibration-vs-validation climatic coverage, evaluated on
# withheld PRESENCES only, based on the range of the OTHER THREE folds.
# This is not MESS/MOP, a quantitative transfer test, or a model metric.
overlap <- do.call(rbind, lapply(groups, function(g) {
  held <- which(og == g)
  train <- which(og != g)
  train_env <- as.matrix(oenv[train, vars, drop = FALSE])
  val_env <- as.matrix(oenv[held, vars, drop = FALSE])
  train_min <- apply(train_env, 2, min)
  train_max <- apply(train_env, 2, max)
  train_q05 <- apply(train_env, 2, stats::quantile, probs = 0.05)
  train_q95 <- apply(train_env, 2, stats::quantile, probs = 0.95)
  full_novel <- sweep(val_env, 2, train_min, "<") |
                sweep(val_env, 2, train_max, ">")
  central_novel <- sweep(val_env, 2, train_q05, "<") |
                   sweep(val_env, 2, train_q95, ">")
  data.frame(
    fold = g,
    withheld_presences = length(held),
    pct_any_variable_outside_train_minmax =
      round(100 * mean(rowSums(full_novel) > 0L), 2),
    pct_any_variable_outside_train_5to95 =
      round(100 * mean(rowSums(central_novel) > 0L), 2),
    pct_BIO1_outside_train_minmax =
      round(100 * mean(full_novel[, "BIO1"]), 2),
    pct_BIO4_outside_train_minmax =
      round(100 * mean(full_novel[, "BIO4"]), 2),
    pct_BIO12_outside_train_minmax =
      round(100 * mean(full_novel[, "BIO12"]), 2),
    pct_BIO15_outside_train_minmax =
      round(100 * mean(full_novel[, "BIO15"]), 2),
    stringsAsFactors = FALSE
  )
}))
rownames(overlap) <- NULL

utils::write.csv(
  geo, file.path(out, "17_cv_fold_geographic_coverage.csv"),
  row.names = FALSE, na = ""
)
utils::write.csv(
  env_summary, file.path(out, "18_cv_fold_environmental_summary.csv"),
  row.names = FALSE, na = ""
)
utils::write.csv(
  overlap, file.path(out, "19_cv_fold_training_climate_overlap.csv"),
  row.names = FALSE, na = ""
)

pal <- c("#0072B2", "#E69F00", "#009E73", "#CC79A7")
grDevices::png(
  file.path(out, "20_cv_fold_geography_diagnostic.png"),
  width = 2000, height = 1600, res = 160
)
graphics::par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))
xlim <- range(c(occ_xy$lon, bg_xy$lon))
ylim <- range(c(occ_xy$lat, bg_xy$lat))
for (i in seq_along(groups)) {
  fold <- groups[i]
  graphics::plot(
    bg_xy$lon, bg_xy$lat, pch = 16, cex = 0.13,
    col = grDevices::adjustcolor("grey65", alpha.f = 0.25),
    xlim = xlim, ylim = ylim,
    xlab = "Longitude", ylab = "Latitude",
    main = paste("Fold", fold, "| withheld presences in colour")
  )
  oi <- which(og == fold)
  bi <- which(bg_g == fold)
  graphics::points(bg_xy$lon[bi], bg_xy$lat[bi], pch = 16,
                   cex = 0.20, col = grDevices::adjustcolor(
                     "#1D1D1D", alpha.f = .25))
  graphics::points(occ_xy$lon[oi], occ_xy$lat[oi], pch = 16,
                   cex = .34,
                   col = grDevices::adjustcolor(pal[i], alpha.f = .7))
  graphics::legend(
    "bottomleft", bty = "n", cex = .75,
    legend = c("All background", "Withheld background",
               "Withheld presences"),
    col = c("grey65", "#1D1D1D", pal[i]), pch = 16
  )
}
grDevices::dev.off()

cat("\nPHALANGIUM OPILIO | SPATIAL CV DOMAIN DIAGNOSTIC\n")
cat("Geographical extent of withheld folds:\n")
print(geo, row.names = FALSE)
cat("\nClimate coverage of withheld presences relative to other folds:\n")
print(overlap, row.names = FALSE)
cat("\nClimate distribution by fold and variable:\n")
print(env_summary, row.names = FALSE)
cat("\nFiles saved to: ",
    normalizePath(out, winslash = "/", mustWork = TRUE), "\n")
cat("Neither ENMeval nor maxnet was refitted; no Venezuelan field\n",
    "observations were accessed or evaluated.\n")
