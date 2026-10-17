# Phalangium opilio | restore original GBIF provenance in screened records
#
# Run in RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/03_restore_GBIF_record_provenance.R")
#
# This script reconstructs original source-row indices and uncertainty indicators
# by joining screened occurrences to their exact GBIF source snapshot by gbifID.
# It retains CoordinateCleaner results; tests are NOT repeated.

project <- getwd()
data_dir <- file.path(project, "01_datos")
audit_dir <- file.path(data_dir, "coordinatecleaner")
source_zip <- file.path(data_dir, "gbif_descarga_original.zip")
candidates_path <- file.path(audit_dir, "02_all_candidates_with_CC_flags.csv")
summary_path <- file.path(audit_dir, "06_coordinate_quality_summary.csv")

if (!file.exists(candidates_path)) {
  message("Locate '02_all_candidates_with_CC_flags.csv' in your audit folder.")
  candidates_path <- file.choose()
  if (basename(candidates_path) != "02_all_candidates_with_CC_flags.csv") {
    stop("Select 02_all_candidates_with_CC_flags.csv, not a subset.")
  }
  audit_dir <- dirname(candidates_path)
  data_dir <- dirname(audit_dir)
  source_zip <- file.path(data_dir, "gbif_descarga_original.zip")
  summary_path <- file.path(audit_dir, "06_coordinate_quality_summary.csv")
}
if (!file.exists(source_zip)) {
  stop("The original GBIF download is missing: ", source_zip)
}
if (!file.exists(summary_path)) stop("The previous summary is missing.")

zip_members <- utils::unzip(source_zip, list = TRUE)$Name
member <- zip_members[basename(zip_members) == "0032625-260928105237408.csv"]
if (length(member) != 1L) {
  stop("The original GBIF ZIP has an unexpected internal file name.")
}

message("Reading the original GBIF snapshot and screened candidates...")
original <- utils::read.delim(
  unz(source_zip, member), sep = "\t", header = TRUE,
  quote = "", colClasses = "character", check.names = FALSE,
  na.strings = c("", "NA"), fileEncoding = "UTF-8"
)
x <- utils::read.csv(candidates_path, check.names = FALSE,
                     stringsAsFactors = FALSE, na.strings = c("", "NA"))
report_old <- utils::read.csv(summary_path, stringsAsFactors = FALSE)

needed <- c("gbifID", "decimalLongitude", "decimalLatitude",
            "coordinateUncertaintyInMeters")
if (!all(needed %in% names(original)) ||
    !all(needed %in% names(x))) {
  stop("Required provenance fields are missing.")
}
if (nrow(original) != 63407) {
  stop("GBIF archive contains ", nrow(original),
       " records, expected 63,407. Please check your source ZIP.")
}
if (nrow(x) != 56524) {
  stop("Candidate file has ", nrow(x),
       " rows; expected 56,524 for this initial screening.")
}
if (anyDuplicated(original$gbifID)) {
  stop("The source GBIF IDs are not unique; the linkage is ambiguous.")
}
id_chr <- function(v) {
  if (is.numeric(v)) return(format(v, scientific = FALSE, trim = TRUE))
  trimws(as.character(v))
}
source_ids <- id_chr(original$gbifID)
candidate_ids <- id_chr(x$gbifID)
idx <- match(candidate_ids, source_ids)
if (anyNA(idx) || anyDuplicated(candidate_ids)) {
  stop("GBIF IDs in the saved candidates cannot be matched one-to-one.")
}

# Check that the raw coordinates agree with the stored screened records.
for (name in c("decimalLongitude", "decimalLatitude")) {
  original_num <- suppressWarnings(as.numeric(original[[name]][idx]))
  candidate_num <- suppressWarnings(as.numeric(x[[name]]))
  discrepant <- !is.finite(original_num) |
                !is.finite(candidate_num) |
                abs(original_num - candidate_num) > 1e-6
  if (any(discrepant)) {
    stop("Coordinate mismatch in ", name, ": ", sum(discrepant),
         " records. No files have been modified.")
  }
}

test_names <- c(".val", ".equ", ".zer", ".cap", ".cen",
                ".sea", ".gbf", ".inst")
required_flags <- c(test_names, ".summary")
if (!all(required_flags %in% names(x))) {
  stop("Missing CoordinateCleaner flags: ",
       paste(setdiff(required_flags, names(x)), collapse = ", "))
}
for (name in required_flags) {
  x[[name]] <- as.logical(x[[name]])
}
if (anyNA(x$.summary)) {
  stop("Missing CoordinateCleaner .summary values.")
}

# Restore source provenance for EVERY candidate record.
changed_source_rows <- if (".source_row" %in% names(x)) {
  sum(is.na(x$.source_row) | as.integer(x$.source_row) != idx)
} else {
  length(idx)
}
uncertainty_from_source <- is.na(original$coordinateUncertaintyInMeters[idx])
wrong_uncertainty_labels <- if (".uncertainty_unreported" %in% names(x)) {
  sum(is.na(x$.uncertainty_unreported) |
      as.logical(x$.uncertainty_unreported) != uncertainty_from_source)
} else {
  length(idx)
}
x$.source_row <- idx
x$.uncertainty_unreported <- uncertainty_from_source
x$.initial_exclusion <- NA_character_

# Test-specific flags (FALSE or NA = flagged) are independent of the provenance fields.
failed_tests <- is.na(x[, test_names, drop = FALSE]) |
                !as.matrix(x[, test_names, drop = FALSE])
# Preserve matrix dimensions and avoid recycling.
flag_matrix <- sapply(test_names, function(nm) {
  is.na(x[[nm]]) | !x[[nm]]
})
x$cc_all_tests_pass <- x$.summary
x$cc_flagged_tests <- apply(flag_matrix, 1, function(row) {
  paste(test_names[which(row)], collapse = ";")
})
if (any(x$cc_all_tests_pass & nzchar(x$cc_flagged_tests))) {
  stop("Unexpected CC summary/flag mismatch; no files have been modified.")
}
if (any(!x$cc_all_tests_pass & !nzchar(x$cc_flagged_tests))) {
  stop("Missing individual CC flags for rejected records.")
}

pass <- x[x$cc_all_tests_pass, , drop = FALSE]
flagged <- x[!x$cc_all_tests_pass, , drop = FALSE]
pass$.cell_5min <- paste(
  floor((90 - as.numeric(pass$decimalLatitude)) * 12),
  floor((as.numeric(pass$decimalLongitude) + 180) * 12),
  sep = "_"
)
priority <- match(
  pass$basisOfRecord,
  c("PRESERVED_SPECIMEN", "HUMAN_OBSERVATION",
    "MACHINE_OBSERVATION", "MATERIAL_CITATION",
    "OCCURRENCE", "MATERIAL_SAMPLE")
)
priority[is.na(priority)] <- 99
uncertainty <- suppressWarnings(as.numeric(pass$coordinateUncertaintyInMeters))
ord <- order(is.na(uncertainty), uncertainty, priority,
             pass$gbifID, na.last = TRUE)
pass <- pass[ord, , drop = FALSE]
cell_sample <- pass[!duplicated(pass$.cell_5min), , drop = FALSE]

# Preserve the original screening totals and recalculate affected fields.
report <- report_old[!grepl("^failed_", report_old$indicator), , drop = FALSE]
replace_count <- function(ind, value) {
  sel <- report$indicator == ind
  if (sum(sel) != 1L) stop("Missing or duplicate indicator: ", ind)
  report$n[sel] <<- as.numeric(value)
}
replace_count("GBIF_original", nrow(original))
replace_count("excluded_before_CC", nrow(original) - nrow(x))
replace_count("candidates_before_CC", nrow(x))
replace_count("unique_positions_before_CC",
              length(unique(paste(x$decimalLongitude, x$decimalLatitude))))
replace_count("candidate_records_passing_CC", nrow(pass))
replace_count("candidate_records_flagged_CC", nrow(flagged))
replace_count("unique_5min_cells_without_CC_flags", nrow(cell_sample))
replace_count("candidate_records_without_uncertainty",
              sum(uncertainty_from_source))
test_rows <- data.frame(
  indicator = paste0("failed_", test_names),
  n = vapply(test_names,
             function(nm) sum(is.na(x[[nm]]) | !x[[nm]]),
             numeric(1))
)
report <- rbind(report, test_rows)

# Write protected backups only after all validations pass.
paths <- c(
  "02_all_candidates_with_CC_flags.csv",
  "03_records_for_review.csv",
  "04_candidates_without_CC_flags.csv",
  "05_occurrences_one_per_5min_cell.csv",
  "06_coordinate_quality_summary.csv"
)
for (file in paths) {
  from <- file.path(audit_dir, file)
  to <- file.path(audit_dir, sub("\\.csv$", "_before_provenance_repair.csv", file))
  if (file.exists(from) && !file.exists(to)) {
    if (!file.copy(from, to)) stop("Cannot back up ", from)
  }
}
utils::write.csv(x, candidates_path, row.names = FALSE, na = "")
utils::write.csv(flagged, file.path(audit_dir, paths[2]),
                 row.names = FALSE, na = "")
utils::write.csv(pass, file.path(audit_dir, paths[3]),
                 row.names = FALSE, na = "")
utils::write.csv(cell_sample, file.path(audit_dir, paths[4]),
                 row.names = FALSE, na = "")
utils::write.csv(report, summary_path, row.names = FALSE, na = "")

writeLines(c(
  "Original GBIF source-provenance reconstruction",
  paste("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("R:", R.version.string),
  paste("GBIF DOI: https://doi.org/10.15468/dl.9gn3qv"),
  paste("Source IDs matched:", length(idx)),
  paste("Restored source-row identifiers:", changed_source_rows),
  paste("Restored uncertainty indicators:", wrong_uncertainty_labels),
  paste("Uncertainty not reported (candidate records):",
        sum(uncertainty_from_source)),
  "CoordinateCleaner spatial tests were not rerun.",
  "Source coordinates and test outcomes were not changed."
), file.path(audit_dir, "09_provenance_reconstruction_log.txt"))
message("\nReconstructed source-row identifiers: ", changed_source_rows)
message("Reconstructed uncertainty labels: ", wrong_uncertainty_labels)
message("Candidate records without reported uncertainty: ",
        sum(uncertainty_from_source))
print(report, row.names = FALSE)
message("\nOutputs updated at: ",
        normalizePath(audit_dir, winslash = "/", mustWork = TRUE))
