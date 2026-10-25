# Public archive checks by default; expensive model rebuilding is explicit.
# Rscript run_all.R
# Rscript run_all.R --with-rasters
# Rscript run_all.R --rebuild-model  (use a separate working copy)

run_workflow <- function(args = commandArgs(trailingOnly = TRUE)) {
  allowed <- c("--with-rasters", "--rebuild-model")
  if (length(setdiff(args, allowed))) stop("Unknown argument(s): ", paste(setdiff(args, allowed), collapse = ", "))
  if (!file.exists("run_all.R") || !dir.exists("R")) stop("Run from the repository root.")
  rebuilding <- "--rebuild-model" %in% args
  if (rebuilding && !file.exists("01_datos/gbif_descarga_original.zip")) {
    stop("Rebuilding requires the exact GBIF archive at 01_datos/gbif_descarga_original.zip; see data/README.md.")
  }
  stages <- "R/30_check_repository.R"
  if (rebuilding) stages <- c(stages, "R/01_coordinate_quality_GBIF.R",
    "R/03_restore_GBIF_record_provenance.R", "R/06_prepare_climate_and_transfer_diagnostics.R",
    "R/11_pilot_ENMeval_maxnet.R", "R/25_exploratory_MESS_MOP_south_america.R")
  if ("--with-rasters" %in% args) stages <- c(stages, "R/28_export_reproducibility_tables.R")

  out <- file.path(getwd(), "local_review")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  log <- data.frame(script = stages, status = "not run", stringsAsFactors = FALSE)
  on.exit({
    utils::write.csv(log, file.path(out, "run_all_log.csv"), row.names = FALSE)
    writeLines(utils::capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
  }, add = TRUE)

  if (rebuilding && "--with-rasters" %in% args) {
    previous <- options(phalangium.evaluation_input = file.path(getwd(), "04_resultados_modelo",
      "pilot_western_palaearctic", "05_ENMeval_tuning_results.csv"),
      phalangium.check_archived_tables = FALSE)
    on.exit(options(previous), add = TRUE)
  }
  for (i in seq_along(stages)) {
    message("Running ", stages[i])
    error <- tryCatch({
      source(stages[i], local = new.env(parent = globalenv()), echo = FALSE)
      NULL
    }, error = function(e) conditionMessage(e))
    if (!is.null(error)) {
      log$status[i] <- paste("ERROR:", error)
      stop("Stopped at ", stages[i], ": ", error, call. = FALSE)
    }
    log$status[i] <- "ok"
  }
  message(if (rebuilding) "Requested rebuilding stages completed; compare generated results with the archive."
          else "Requested public archive checks completed; no model was refitted.")
  message("Execution log and session information: ", out)
  invisible(log)
}
run_workflow()
