# run_all.R -- ordered driver for the Phalangium opilio SDM workflow
#
# Usage: open the repository root as the R working directory, then
#   source("run_all.R")
# Steps whose inputs are missing are reported and skipped (not silently ignored).
#
# STATUS: written 2026-10-19 from the script headers; NOT yet executed end-to-end.
# Run it once on a clean checkout and commit results/sessionInfo.txt before claiming
# end-to-end reproduction.
#
# External inputs (not redistributed):
#   01_datos/gbif_descarga_original.zip   GBIF download DOI 10.15468/dl.9gn3qv
#                                         (SHA-256 in data/README.md)
#   01_datos/climate_diagnostics/16_worldclim_western_window_5m.tif   WorldClim 2.1 BIO1, BIO4,
#   01_datos/climate_diagnostics/17_worldclim_south_america_5m.tif    BIO12, BIO15 at 5', cropped by
#                                                                     R/06 (see that script)

stopifnot(file.exists("run_all.R"), dir.exists("R"))
dir.create("results", showWarnings = FALSE)

# Core steps that produce the numbers reported in the manuscript, in dependency order.
core <- c(
  "R/01_coordinate_quality_GBIF.R",           # coordinate screening (CoordinateCleaner)
  "R/03_restore_GBIF_record_provenance.R",    # restores gbifID provenance (63,407 -> 56,524)
  "R/06_prepare_climate_and_transfer_diagnostics.R", # climate rasters
  "R/11_pilot_ENMeval_maxnet.R",              # six maxnet models, 4 latitudinal blocks; LQ/RM2 projection
  "R/25_exploratory_MESS_MOP_south_america.R",# MESS and MOP over South America
  "R/26_venezuela_transfer_diagnostics_v3.R", # values at the Venezuelan events
  "R/27_figura2_idoneidad_MESS_JIS.R",        # manuscript Figure 3
  "R/28_export_reproducibility_tables.R",     # derived tables for deposit
  "R/29_sensitivity_BIO4_clamping.R"          # sensitivity: BIO4 and clamping
)
# Diagnostic / sensitivity steps documented in docs/ (optional; not needed for the main numbers):
optional <- setdiff(sort(list.files("R", pattern = "[.]R$", full.names = TRUE)), core)

args <- commandArgs(trailingOnly = TRUE)
steps <- if ("--with-diagnostics" %in% args) c(core, optional) else core

log <- data.frame(script = steps, status = NA_character_, stringsAsFactors = FALSE)
for (i in seq_along(steps)) {
  f <- steps[i]
  if (!file.exists(f)) { log$status[i] <- "missing script"; next }
  message("\n===== ", f, " =====")
  res <- tryCatch({ source(f, echo = FALSE, local = new.env()); "ok" },
                  error = function(e) paste("ERROR:", conditionMessage(e)))
  log$status[i] <- res
  if (!identical(res, "ok")) message("  -> ", res, " (continuing; fix inputs and re-run)")
}
print(log, right = FALSE)
utils::write.csv(log, "results/run_all_log.csv", row.names = FALSE)
writeLines(utils::capture.output(sessionInfo()), "results/sessionInfo.txt")
message("\nSession information written to results/sessionInfo.txt")
