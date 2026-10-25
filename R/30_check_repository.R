# Base-R checks of the public peer-review archive; no private coordinates needed.
check_public_archive <- function() {
  scripts <- c("run_all.R", list.files("R", pattern = "[.]R$", full.names = TRUE))
  invisible(lapply(scripts, parse))
  message("Parsed ", length(scripts), " R scripts.")

  read_table <- function(name, columns) {
    path <- file.path("results", name)
    if (!file.exists(path)) stop("Required public table missing: ", path)
    x <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
    if (!all(columns %in% names(x))) stop("Missing columns in ", path)
    x
  }
  cells <- read_table("venezuela_transfer_cells_public.csv",
    c("cell_id", "n_events", "suitability_cloglog", "MESS", "MOP_distance",
      "MESS_limiting_variable", "univariate_extrapolation"))
  stopifnot(nrow(cells) == 3L, !anyDuplicated(cells$cell_id),
            all(cells$n_events > 0), all(cells$n_events == as.integer(cells$n_events)),
            sum(cells$n_events) == 7L)
  numeric_values <- as.matrix(cells[, c("suitability_cloglog", "MESS", "MOP_distance")])
  stopifnot(all(is.finite(numeric_values)),
            all(cells$suitability_cloglog >= 0 & cells$suitability_cloglog <= 1),
            all(cells$MESS < 0), all(cells$MOP_distance >= 0),
            all(cells$MESS_limiting_variable == "BIO4"),
            all(as.logical(cells$univariate_extrapolation) == (cells$MESS < 0)))
  events <- cells[rep(seq_len(nrow(cells)), cells$n_events), , drop = FALSE]
  summary <- read_table("27_venezuela_transfer_summary.csv",
    c("sites", "sites_complete", "sites_MESS_negative", "median_suitability", "median_MESS", "median_MOP"))
  stopifnot(nrow(summary) == 1L, summary$sites == nrow(events),
            summary$sites_complete == nrow(events), summary$sites_MESS_negative == nrow(events),
            abs(summary$median_suitability - median(events$suitability_cloglog)) < 1e-10,
            abs(summary$median_MESS - median(events$MESS)) < 1e-10,
            abs(summary$median_MOP - median(events$MOP_distance)) < 1e-10)

  ref <- read_table("26_reference_environment_parameters.csv",
                    c("variable", "reference_mean", "reference_sd", "sampled_min", "sampled_max"))
  stopifnot(identical(ref$variable, c("BIO1", "BIO4", "BIO12", "BIO15")),
            all(is.finite(as.matrix(ref[, -1]))), all(ref$reference_sd > 0),
            all(ref$sampled_min < ref$sampled_max))
  ev <- read_table("initial_spatial_block_ENMeval.csv",
                    c("fc", "rm", "tune.args", "auc.train", "auc.val.avg", "ncoef"))
  expected <- as.vector(outer(c("L", "LQ", "LQH"), c(1, 2), function(fc, rm) paste0("fc.", fc, "_rm.", rm)))
  stopifnot(nrow(ev) == 6L, !anyDuplicated(ev$tune.args), setequal(ev$tune.args, expected),
            all(is.finite(ev$auc.val.avg)), all(ev$auc.val.avg >= 0 & ev$auc.val.avg <= 1))
  evaluated <- read_table("model_evaluation_summary.csv", c("setting", "auc_val_mean", "manuscript_model"))
  stopifnot(identical(evaluated$setting, ev$tune.args),
            all(abs(evaluated$auc_val_mean - round(ev$auc.val.avg, 3)) < 1e-10),
            identical(as.logical(evaluated$manuscript_model), evaluated$setting == "fc.LQ_rm.2"))
  context <- read_table("venezuela_suitability_percentiles.csv",
                        c("n_events", "suitability_cloglog", "MESS", "MOP_distance", "SA_valid_cells"))
  stopifnot(nrow(context) == nrow(cells), identical(context$n_events, cells$n_events))
  for (column in c("suitability_cloglog", "MESS", "MOP_distance")) {
    stopifnot(all(abs(context[[column]] - cells[[column]]) < 1e-10))
  }
  manifest <- utils::read.csv("data/review_artifact_manifest.csv", stringsAsFactors = FALSE)
  stopifnot(nrow(manifest) == 7L, all(file.exists(manifest$path)),
            all(file.info(manifest$path)$size == manifest$size_bytes))
  message("Public archive checks passed: 6 models, 7 events, 3 climatic cells and 7 source artifacts.")
  invisible(TRUE)
}
check_public_archive()
