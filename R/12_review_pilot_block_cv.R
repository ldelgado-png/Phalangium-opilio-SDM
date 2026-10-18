# Phalangium opilio | Inspect pilot spatial cross-validation by fold
#
# RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/12_review_pilot_block_cv.R")
#
# Reads the previously saved ENMeval object. Does NOT refit models, read
# held-out Venezuelan records, or select a final model.

if (!requireNamespace("ENMeval", quietly = TRUE)) {
  stop("Install ENMeval using install.packages('ENMeval').")
}
pilot <- file.path(getwd(), "04_resultados_modelo",
                   "pilot_western_palaearctic")
input <- file.path(pilot, "07_ENMeval_pilot_evaluation.rds")
if (!file.exists(input)) {
  message("Select 07_ENMeval_pilot_evaluation.rds in your pilot folder.")
  input <- file.choose()
  if (basename(input) != "07_ENMeval_pilot_evaluation.rds") {
    stop("Please select the original saved ENMeval evaluation object.")
  }
  pilot <- dirname(input)
}

message("Reading completed ENMeval object (no model refitting)...")
e <- readRDS(input)
if (!methods::is(e, "ENMevaluation")) {
  stop("Unexpected evaluation object class: ",
       paste(class(e), collapse = ", "))
}
summary <- as.data.frame(ENMeval::eval.results(e))
folds <- as.data.frame(ENMeval::eval.results.partitions(e))
occ_grp <- as.character(ENMeval::eval.occs.grp(e))
bg_grp <- as.character(ENMeval::eval.bg.grp(e))
occs <- as.data.frame(ENMeval::eval.occs(e))
bg <- as.data.frame(ENMeval::eval.bg(e))

if (nrow(summary) != 6L || nrow(folds) != 24L) {
  stop("Expected 6 settings and 4 spatial folds per setting, got ",
       nrow(summary), " settings and ", nrow(folds), " fold rows.")
}
required <- c("tune.args", "fold", "auc.val", "auc.diff",
              "cbi.val", "or.10p")
missing <- setdiff(required, names(folds))
if (length(missing)) {
  stop("Required partition metrics absent: ",
       paste(missing, collapse = ", "))
}
if (length(occ_grp) != nrow(occs) ||
    length(bg_grp) != nrow(bg)) {
  stop("Saved spatial partitions do not match record counts.")
}
if (nrow(occs) != 10426L || nrow(bg) != 10000L) {
  stop("Unexpected calibration sample sizes: ", nrow(occs), " and ",
       nrow(bg))
}
groups <- sort(unique(c(occ_grp, bg_grp)))
if (length(groups) != 4L ||
    anyNA(occ_grp) || anyNA(bg_grp)) {
  stop("Four complete spatial partitions were expected.")
}
fold_counts <- data.frame(
  fold = groups,
  presence_cells = vapply(groups, function(g) sum(occ_grp == g), integer(1)),
  background_cells = vapply(groups, function(g) sum(bg_grp == g), integer(1))
)
if (any(fold_counts$presence_cells < 10L) ||
    any(fold_counts$background_cells < 10L)) {
  warning("One partition has fewer than 10 presence/background cells.")
}
if (!all(sort(unique(as.character(folds$fold))) == sort(groups))) {
  warning("Partition names in per-fold table differ from occurrence groups.")
}

# Report fold-specific statistics and uncertainty without selecting a
# model using the geographically withheld South American sites.
folds <- folds[order(folds$tune.args, folds$fold), , drop = FALSE]
summary <- summary[order(summary$fc, summary$rm), , drop = FALSE]
summary$auc_train_to_validation_gap <- 
  summary$auc.train - summary$auc.val.avg
summary$auc_val_coefficient_of_variation <-
  summary$auc.val.sd / pmax(summary$auc.val.avg, 1e-9)
summary$cbi_fold_sd <- summary$cbi.val.sd

write.csv(
  folds, file.path(pilot, "12_cv_metrics_by_fold.csv"),
  row.names = FALSE, na = ""
)
write.csv(
  fold_counts, file.path(pilot, "13_cv_fold_sample_sizes.csv"),
  row.names = FALSE, na = ""
)
write.csv(
  summary, file.path(pilot, "14_cv_summary_with_variability.csv"),
  row.names = FALSE, na = ""
)

grDevices::png(
  file.path(pilot, "15_cv_fold_metrics.png"),
  width = 2000, height = 1200, res = 165
)
graphics::par(mfrow = c(1, 2), mar = c(10, 4, 3, 1))
settings <- unique(folds$tune.args)
x <- factor(folds$tune.args, levels = settings)
graphics::boxplot(
  split(folds$auc.val, x),
  las = 2, ylab = "Validation AUC",
  main = "AUC by spatial validation fold", ylim = c(0, 1),
  col = "grey85", outline = TRUE
)
graphics::abline(h = 0.5, lty = 2, col = "grey50")
graphics::boxplot(
  split(folds$cbi.val, x),
  las = 2, ylab = "Continuous Boyce Index",
  main = "CBI by spatial validation fold",
  col = "grey85", outline = TRUE
)
grDevices::dev.off()

if (ncol(occs) >= 2L && ncol(bg) >= 2L) {
  grDevices::png(
    file.path(pilot, "16_cv_presence_background_blocks.png"),
    width = 1500, height = 1100, res = 160
  )
  graphics::plot(
    bg[, 1], bg[, 2], pch = 16, cex = .15,
    col = grDevices::adjustcolor("grey55", alpha.f = .30),
    xlab = "Longitude", ylab = "Latitude",
    main = "Spatially blocked calibration data"
  )
  pal <- c("#0072B2", "#E69F00", "#009E73", "#CC79A7")
  for (i in seq_along(groups)) {
    j <- which(occ_grp == groups[i])
    graphics::points(occs[j, 1], occs[j, 2], pch = 16,
                     cex = .3,
                     col = grDevices::adjustcolor(pal[i], alpha.f = .55))
  }
  graphics::legend(
    "bottomleft", bty = "n",
    legend = paste("Presence fold", groups),
    col = pal, pch = 16, cex = .8
  )
  grDevices::dev.off()
}

cat("\nPHALANGIUM OPILIO | FOUR-BLOCK PILOT MODEL REVIEW\n")
cat("Presences/background:", nrow(occs), "/", nrow(bg), "\n")
cat("Per-fold calibration and background sample sizes:\n")
print(fold_counts, row.names = FALSE)
cat("\nFold-specific validation metrics:\n")
print(folds[, required, drop = FALSE], row.names = FALSE)
cat("\nSummary of model performance and spatial variation:\n")
key <- c("tune.args", "auc.train", "auc.val.avg", "auc.val.sd",
         "auc_train_to_validation_gap",
         "cbi.val.avg", "cbi.val.sd", "or.10p.avg", "or.10p.sd",
         "AICc", "delta.AICc", "ncoef")
print(summary[, intersect(key, names(summary)), drop = FALSE],
      row.names = FALSE)
cat("\nOutputs:", normalizePath(pilot, winslash = "/"), "\n")
cat("No fitting, retuning, model choice, or external validation performed.\n")
cat("Venezuelan observations were not accessed.\n")
