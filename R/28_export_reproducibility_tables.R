# R/28: derived tables for deposit and for the manuscript's model-evaluation reporting.
# Inputs available in the public repository:
#   results/initial_spatial_block_ENMeval.csv
#   results/26_venezuela_site_transfer_values.csv
#   04_resultados_modelo/pilot_western_palaearctic/*.tif  (suitability, MESS, MOP)
# Optional inputs (local only; written by R/11): 01_pilot_calibration_occurrences.csv,
#   02_pilot_background_xy.csv, 06_maxnet_pilot_models.rds, 05_ENMeval_tuning_results.csv.

suppressPackageStartupMessages(library(terra))
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
res_dir <- file.path(root, "results")
mod_dir <- file.path(root, "04_resultados_modelo", "pilot_western_palaearctic")
nov_dir <- file.path(mod_dir, "transfer_novelty_EXPLORATORY_NOT_FINAL")

# --- A. Model evaluation summary: AUC gap, Boyce index, AICc ------------------------------------
ev <- read.csv(file.path(res_dir, "initial_spatial_block_ENMeval.csv"))
summ <- data.frame(
  setting       = ev$tune.args,
  auc_train     = round(ev$auc.train, 3),
  auc_val_mean  = round(ev$auc.val.avg, 3),
  auc_val_sd    = round(ev$auc.val.sd, 3),
  auc_gap       = round(ev$auc.train - ev$auc.val.avg, 3),
  cbi_val_mean  = round(ev$cbi.val.avg, 3),
  cbi_val_sd    = round(ev$cbi.val.sd, 3),
  or10_mean     = round(ev$or.10p.avg, 3),
  delta_AICc    = round(ev$delta.AICc, 1),
  n_coef        = ev$ncoef
)
summ$manuscript_model <- summ$setting == "fc.LQ_rm.2"
write.csv(summ, file.path(res_dir, "model_evaluation_summary.csv"), row.names = FALSE)

# --- B. Percentile context of the Venezuelan values within South America ------------------------
sites <- read.csv(file.path(res_dir, "26_venezuela_site_transfer_values.csv"))
cells <- unique(sites[, c("suitability_cloglog", "MESS", "MOP_distance")])
suit <- terra::values(rast(file.path(mod_dir, "09_pilot_south_america_LQ_rm2_cloglog_NOT_FINAL.tif")), na.rm = TRUE)[, 1]
mess <- terra::values(rast(file.path(nov_dir, "27_sa_MESS_5m_EXPLORATORY.tif"))[[5]], na.rm = TRUE)[, 1]
mop  <- terra::values(rast(file.path(nov_dir, "29_sa_MOP_nearest1pct_distance_5m_EXPLORATORY.tif")), na.rm = TRUE)[, 1]
pct <- data.frame(
  n_events                       = as.integer(table(match(
    paste(sites$suitability_cloglog, sites$MESS, sites$MOP_distance),
    paste(cells$suitability_cloglog, cells$MESS, cells$MOP_distance)))),
  suitability_cloglog            = cells$suitability_cloglog,
  share_SA_cells_suit_ge_site    = vapply(cells$suitability_cloglog, function(x) mean(suit >= x), 0),
  MESS                           = cells$MESS,
  share_SA_cells_MESS_lt_site    = vapply(cells$MESS, function(x) mean(mess < x), 0),
  MOP_distance                   = cells$MOP_distance,
  MOP_percentile_in_SA           = vapply(cells$MOP_distance, function(x) mean(mop < x), 0),
  SA_median_MOP                  = median(mop),
  SA_share_MESS_negative         = mean(mess < 0),
  SA_valid_cells                 = length(mess)
)
write.csv(pct, file.path(res_dir, "venezuela_suitability_percentiles.csv"), row.names = FALSE)

# --- C. Optional local artefacts to deposit (skipped if absent) ---------------------------------
dep <- file.path(root, "data")
occ_f <- file.path(mod_dir, "01_pilot_calibration_occurrences.csv")
bg_f  <- file.path(mod_dir, "02_pilot_background_xy.csv")
if (file.exists(occ_f)) {
  o <- read.csv(occ_f, colClasses = c(gbifID = "character"))
  keep <- intersect(c("gbifID", "decimalLongitude", "decimalLatitude", "worldclim_cell", "basisOfRecord"), names(o))
  write.csv(o[, keep], file.path(dep, "calibration_presence_cells.csv"), row.names = FALSE)
  message("Wrote data/calibration_presence_cells.csv (", nrow(o), " rows; expected 10,426)")
}
if (file.exists(bg_f)) {
  file.copy(bg_f, file.path(dep, "calibration_background_xy.csv"), overwrite = TRUE)
  message("Wrote data/calibration_background_xy.csv")
}
mod_f <- file.path(mod_dir, "06_maxnet_pilot_models.rds")
if (file.exists(mod_f)) {
  m <- readRDS(mod_f)[["fc.LQ_rm.2"]]
  saveRDS(m, file.path(dep, "maxnet_LQ_rm2_model.rds"), compress = "xz")
  message("Wrote data/maxnet_LQ_rm2_model.rds")
}
message("Done. Check the GBIF licence terms before redistributing record-level tables.")
