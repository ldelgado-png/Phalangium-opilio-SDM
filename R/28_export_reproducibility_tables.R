# Regenerate derived tables from public evaluation, three-cell and raster inputs.
# Run from the repository root. Outputs stay in ignored local_review/tables/.
# No field coordinates, model refitting or automatic record-level export is used.

if (!requireNamespace("terra", quietly = TRUE)) stop("Install terra first.")
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
res_dir <- file.path(root, "results")
mod_dir <- file.path(root, "04_resultados_modelo", "pilot_western_palaearctic")
nov_dir <- file.path(mod_dir, "transfer_novelty_EXPLORATORY_NOT_FINAL")
out_dir <- getOption("phalangium.review_output_dir", file.path(root, "local_review", "tables"))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

evaluation_file <- getOption("phalangium.evaluation_input",
                            file.path(res_dir, "initial_spatial_block_ENMeval.csv"))
ev <- utils::read.csv(evaluation_file, stringsAsFactors = FALSE)
required <- c("tune.args", "auc.train", "auc.val.avg", "auc.val.sd",
              "cbi.val.avg", "cbi.val.sd", "or.10p.avg", "delta.AICc", "ncoef")
if (!all(required %in% names(ev))) stop("Evaluation table has missing columns.")
summ <- data.frame(
  setting = ev$tune.args,
  auc_train = round(ev$auc.train, 3),
  auc_val_mean = round(ev$auc.val.avg, 3),
  auc_val_sd = round(ev$auc.val.sd, 3),
  auc_gap = round(ev$auc.train - ev$auc.val.avg, 3),
  cbi_val_mean = round(ev$cbi.val.avg, 3),
  cbi_val_sd = round(ev$cbi.val.sd, 3),
  or10_mean = round(ev$or.10p.avg, 3),
  delta_AICc = round(ev$delta.AICc, 1),
  n_coef = ev$ncoef,
  manuscript_model = ev$tune.args == "fc.LQ_rm.2",
  stringsAsFactors = FALSE
)

# The public table identifies the three cells and event multiplicities.
cells <- utils::read.csv(file.path(res_dir, "venezuela_transfer_cells_public.csv"),
                         stringsAsFactors = FALSE)
required <- c("cell_id", "n_events", "suitability_cloglog", "MESS", "MOP_distance")
if (!all(required %in% names(cells)) || anyDuplicated(cells$cell_id)) {
  stop("Expected unique cell labels and diagnostic columns in the public table.")
}
values_finite <- function(path, layer = 1L) {
  r <- terra::rast(path)
  if (terra::nlyr(r) < layer) stop("Required layer absent: ", path)
  v <- as.numeric(terra::values(r[[layer]]))
  v <- v[is.finite(v)]
  if (!length(v)) stop("No finite raster values: ", path)
  v
}
suit <- values_finite(file.path(mod_dir, "09_pilot_south_america_LQ_rm2_cloglog_NOT_FINAL.tif"))
mess <- values_finite(file.path(nov_dir, "27_sa_MESS_5m_EXPLORATORY.tif"), 5L)
mop <- values_finite(file.path(nov_dir, "29_sa_MOP_nearest1pct_distance_5m_EXPLORATORY.tif"))
pct <- data.frame(
  n_events = cells$n_events,
  suitability_cloglog = cells$suitability_cloglog,
  share_SA_cells_suit_ge_site = vapply(cells$suitability_cloglog, function(x) mean(suit >= x), 0),
  MESS = cells$MESS,
  share_SA_cells_MESS_lt_site = vapply(cells$MESS, function(x) mean(mess < x), 0),
  MOP_distance = cells$MOP_distance,
  MOP_percentile_in_SA = vapply(cells$MOP_distance, function(x) mean(mop < x), 0),
  SA_median_MOP = stats::median(mop),
  SA_share_MESS_negative = mean(mess < 0),
  SA_valid_cells = length(mess)
)

tables <- list(model_evaluation_summary.csv = summ,
               venezuela_suitability_percentiles.csv = pct)
for (name in names(tables)) {
  regenerated <- tables[[name]]
  utils::write.csv(regenerated, file.path(out_dir, name), row.names = FALSE)
  if (isTRUE(getOption("phalangium.check_archived_tables", TRUE))) {
    archived <- utils::read.csv(file.path(res_dir, name), stringsAsFactors = FALSE)
    if (!identical(names(archived), names(regenerated)) || nrow(archived) != nrow(regenerated)) {
      stop("Regenerated table structure differs from archive: ", name)
    }
    for (column in names(regenerated)) {
      a <- archived[[column]]; b <- regenerated[[column]]
      same <- if (is.numeric(b)) {
        all(is.finite(a)) && all(is.finite(b)) && all(abs(a - b) <= 1e-10)
      } else if (is.logical(b)) {
        identical(as.logical(a), b)
      } else identical(as.character(a), as.character(b))
      if (!isTRUE(same)) stop("Archive comparison failed: ", name, " / ", column)
    }
    message("Verified against deposited table: ", name)
  }
}
message("Derived tables written to ", out_dir,
        "; archived tables and source rasters were not overwritten.")
