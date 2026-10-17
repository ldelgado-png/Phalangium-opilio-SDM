# Phalangium opilio | repair coordinate audit tables without rerunning tests
# One-command RStudio use:
#   source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/02_rebuild_coordinate_quality_report.R")
#
# This rebuilds reporting fields, not the underlying CoordinateCleaner test values.

out_dir <- file.path(getwd(), "01_datos", "coordinatecleaner")
input_file <- file.path(out_dir, "02_all_candidates_with_CC_flags.csv")

if (!file.exists(input_file)) {
  message("Select '02_all_candidates_with_CC_flags.csv' ",
          "in your coordinatecleaner output folder.")
  input_file <- file.choose()
  if (basename(input_file) != "02_all_candidates_with_CC_flags.csv") {
    stop("Please select exactly 02_all_candidates_with_CC_flags.csv.")
  }
  out_dir <- dirname(input_file)
}
message("Reading saved per-record CoordinateCleaner results...")
x <- utils::read.csv(input_file, stringsAsFactors = FALSE,
                     check.names = FALSE, na.strings = c("", "NA"))

cc_columns <- c(".val", ".equ", ".zer", ".cap", ".cen",
                ".sea", ".gbf", ".inst")
required <- c(cc_columns, ".summary", "cc_all_tests_pass",
              ".source_row", ".uncertainty_unreported")
if (!all(required %in% names(x))) {
  stop("Cannot repair: missing columns: ",
       paste(setdiff(required, names(x)), collapse = ", "))
}

# CoordinateCleaner 3.0.1 outputs TRUE for passed tests.
for (nm in c(cc_columns, ".summary")) {
  x[[nm]] <- as.logical(x[[nm]])
}
if (anyNA(x$.summary)) {
  stop("Missing .summary values: manual investigation required.")
}
x$cc_all_tests_pass <- x$.summary

# Record-level labels must only describe actual CoordinateCleaner tests.
# NA in a CC flag is explicitly labelled 'missing_flag', never 'passed'.
test_matrix <- as.matrix(x[, cc_columns, drop = FALSE])
failed_matrix <- is.na(test_matrix) | !test_matrix
flags <- apply(failed_matrix, 1L, function(v) {
  paste(cc_columns[which(v)], collapse = ";")
})
x$cc_flagged_tests <- as.character(flags)
if (any(x$cc_all_tests_pass & nzchar(x$cc_flagged_tests))) {
  stop("Inconsistency between CoordinateCleaner .summary and test flags.")
}
if (any(!x$cc_all_tests_pass & !nzchar(x$cc_flagged_tests))) {
  stop("Incomplete individual test flags in flagged records.")
}

# Keep a copy of the original summary for audit provenance.
summary_file <- file.path(out_dir, "06_coordinate_quality_summary.csv")
prior_summary <- file.path(out_dir, "06_coordinate_quality_summary_before_fix.csv")
if (file.exists(summary_file) && !file.exists(prior_summary)) {
  file.copy(summary_file, prior_summary)
}
original <- utils::read.csv(prior_summary, stringsAsFactors = FALSE,
                            check.names = FALSE)
if (!all(c("indicator", "n") %in% names(original))) {
  stop("Expected indicator and n in the original summary.")
}
core <- original[!grepl("^failed_", original$indicator), , drop = FALSE]
core$n[core$indicator == "candidate_records_passing_CC"] <-
  sum(x$cc_all_tests_pass)
core$n[core$indicator == "candidate_records_flagged_CC"] <-
  sum(!x$cc_all_tests_pass)
cc_summary <- data.frame(
  indicator = paste0("failed_", cc_columns),
  n = vapply(cc_columns,
             function(nm) sum(is.na(x[[nm]]) | !x[[nm]]),
             numeric(1))
)
updated <- rbind(core, cc_summary)

# Recalculate report labels only; the test flags, coordinate pairs,
# initial filtering, and 5-arcminute thinning are unchanged.
utils::write.csv(x, input_file, row.names = FALSE, na = "")
utils::write.csv(x[!x$cc_all_tests_pass, , drop = FALSE],
                 file.path(out_dir, "03_records_for_review.csv"),
                 row.names = FALSE, na = "")
utils::write.csv(x[x$cc_all_tests_pass, , drop = FALSE],
                 file.path(out_dir, "04_candidates_without_CC_flags.csv"),
                 row.names = FALSE, na = "")
utils::write.csv(updated, summary_file, row.names = FALSE, na = "")

logfile <- file.path(out_dir, "08_report_correction.txt")
writeLines(c(
  "CoordinateCleaner report correction",
  paste("Corrected on:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("R version:", R.version.string),
  "Only these fields are interpreted as CoordinateCleaner tests:",
  paste(cc_columns, collapse = ", "),
  "Discarded erroneous summary fields: .source_row,",
  ".initial_exclusion, .uncertainty_unreported.",
  "CoordinateCleaner .summary and individual test flags are unchanged.",
  "No spatial tests were rerun. No coordinates were removed by this repair."
), logfile)

message("\nCorrected coordinate audit summary:")
print(updated, row.names = FALSE)
message("\nCorrected report files written to: ",
        normalizePath(out_dir, winslash = "/", mustWork = TRUE))
