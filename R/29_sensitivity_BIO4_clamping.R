# R/29: sensitivity of the Venezuelan predictions to BIO4 and to clamping.
# MOTIVATION: the three Venezuelan cells have BIO4 below the calibration range (MESS < 0),
# and the manuscript projection uses clamping, so the reported cloglog values (0.558-0.617) are
# evaluated at the BIO4 boundary. This script (i) refits LQ/RM2 on the SAME presences and
# background without BIO4, and (ii) predicts at the Venezuelan cells with and without clamping.
# It does NOT use the Venezuelan records to fit or select anything.
#
# STATUS: written 2026-10-19; not yet executed. Requires the local outputs of R/11
# (01_pilot_calibration_occurrences.csv, 02_pilot_background_xy.csv) and the WorldClim rasters.

for (p in c("terra", "maxnet")) if (!requireNamespace(p, quietly = TRUE)) stop("Install ", p)
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
mod_dir <- file.path(root, "04_resultados_modelo", "pilot_western_palaearctic")
bio_w <- terra::rast(file.path(root, "01_datos", "climate_diagnostics", "16_worldclim_western_window_5m.tif"))
bio_s <- terra::rast(file.path(root, "01_datos", "climate_diagnostics", "17_worldclim_south_america_5m.tif"))
vars_all <- c("BIO1", "BIO4", "BIO12", "BIO15")
stopifnot(identical(names(bio_w), vars_all), identical(names(bio_s), vars_all))

occ <- read.csv(file.path(mod_dir, "01_pilot_calibration_occurrences.csv"))
bg  <- read.csv(file.path(mod_dir, "02_pilot_background_xy.csv"))
occ_xy <- cbind(occ$decimalLongitude, occ$decimalLatitude)
bg_xy  <- as.matrix(bg[, c("longitude", "latitude")])
env <- rbind(terra::extract(bio_w, occ_xy)[, vars_all], terra::extract(bio_w, bg_xy)[, vars_all])
pa  <- c(rep(1, nrow(occ_xy)), rep(0, nrow(bg_xy)))
ok  <- complete.cases(env); env <- env[ok, ]; pa <- pa[ok]
stopifnot(sum(pa) > 10000)   # expected ~10,426 presences

sites <- read.csv(file.path(root, "results", "26_venezuela_site_transfer_values.csv"))
sv <- terra::extract(bio_s, as.matrix(sites[, c("longitude", "latitude")]))[, vars_all]
cells <- !duplicated(round(sv, 6)); sv <- sv[cells, ]; ids <- sites$site_id[cells]

fit <- function(vars) {
  d <- env[, vars, drop = FALSE]
  maxnet::maxnet(pa, d, f = maxnet::maxnet.formula(pa, d, classes = "lq"), regmult = 2)
}
pred <- function(m, vars, clamp) {
  as.numeric(predict(m, sv[, vars, drop = FALSE], type = "cloglog", clamp = clamp))
}
sets <- list(all4 = vars_all, no_BIO4 = c("BIO1", "BIO12", "BIO15"))
out <- do.call(rbind, lapply(names(sets), function(n) {
  m <- fit(sets[[n]])
  data.frame(model = n, site_id = ids,
             BIO4_site = sv$BIO4, BIO4_calib_min = min(env$BIO4),
             cloglog_clamp = pred(m, sets[[n]], TRUE),
             cloglog_noclamp = pred(m, sets[[n]], FALSE))
}))
write.csv(out, file.path(root, "results", "sensitivity_BIO4_clamping.csv"), row.names = FALSE)
print(out, digits = 3)
message("Interpretation guide: if 'all4' clamp differs strongly from 'all4' noclamp or from 'no_BIO4', ",
        "the 0.558-0.617 values depend on BIO4 extrapolation and should be reported with that caveat.")
