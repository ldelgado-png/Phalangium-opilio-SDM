# Phalangium opilio | GBIF coordinate-quality audit
# Run from the working directory containing 01_datos/gbif_descarga_original.zip:
#   source("R/01_coordinate_quality_GBIF.R")
# CoordinateCleaner tests generate alerts; they do not demonstrate an error.

options(timeout = max(900, getOption("timeout")))

if (!requireNamespace("CoordinateCleaner", quietly = TRUE)) {
  stop('Install CoordinateCleaner with install.packages("CoordinateCleaner").')
}
message("CoordinateCleaner version: ",
        as.character(utils::packageVersion("CoordinateCleaner")))

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
zip_file <- file.path(root, "01_datos", "gbif_descarga_original.zip")
out_dir <- file.path(root, "01_datos", "coordinatecleaner")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
if (!file.exists(zip_file)) {
  stop("The source GBIF archive is missing: ", zip_file)
}

entries <- utils::unzip(zip_file, list = TRUE)$Name
source_file <- entries[grepl("\\.csv$", entries, ignore.case = TRUE)]
if (length(source_file) != 1L) {
  stop("Expected exactly one tab-separated .csv file in the source ZIP.")
}

occ <- utils::read.delim(
  unz(zip_file, source_file),
  sep = "\t", header = TRUE, quote = "",
  stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA"), fileEncoding = "UTF-8"
)
required <- c("gbifID", "species", "taxonRank", "occurrenceStatus",
              "decimalLongitude", "decimalLatitude",
              "coordinateUncertaintyInMeters", "issue")
if (!all(required %in% names(occ))) {
  stop("Required GBIF occurrence fields are missing: ",
       paste(setdiff(required, names(occ)), collapse = ", "))
}
stopifnot(nrow(occ) > 0)

for (nm in c("decimalLongitude", "decimalLatitude",
             "coordinateUncertaintyInMeters")) {
  occ[[nm]] <- suppressWarnings(as.numeric(occ[[nm]]))
}
occ$.source_row <- seq_len(nrow(occ))

# The first applicable rule assigns the initial exclusion reason.
reason <- rep(NA_character_, nrow(occ))
mark <- function(test, label) {
  idx <- !is.na(test) & test & is.na(reason)
  reason[idx] <<- label
}
mark(is.na(occ$occurrenceStatus) | occ$occurrenceStatus != "PRESENT",
     "not_a_confirmed_presence")
mark(is.na(occ$taxonRank) | occ$taxonRank != "SPECIES",
     "not_species_rank")
mark(is.na(occ$species) | occ$species != "Phalangium opilio",
     "other_species")
mark(!is.finite(occ$decimalLongitude) |
       !is.finite(occ$decimalLatitude),
     "coordinates_missing")
mark(abs(occ$decimalLongitude) > 180 |
       abs(occ$decimalLatitude) > 90 |
       (occ$decimalLongitude == 0 & occ$decimalLatitude == 0),
     "coordinates_outside_valid_range")

source_issues <- ifelse(is.na(occ$issue), "", occ$issue)
severe_issues <- c(
  "COORDINATE_OUT_OF_RANGE", "COUNTRY_COORDINATE_MISMATCH",
  "ZERO_COORDINATE", "COORDINATE_REPROJECTION_SUSPICIOUS"
)
for (flag in severe_issues) {
  pattern <- paste0("(^|;)", flag, "(;|$)")
  mark(grepl(pattern, source_issues), paste0("GBIF_", flag))
}
uncertainty <- occ$coordinateUncertaintyInMeters
mark(!is.na(uncertainty) &
       (uncertainty < 0 | uncertainty > 5000),
     "reported_uncertainty_over_5000m")

occ$.initial_exclusion <- reason
keep_columns <- intersect(
  c("gbifID", "datasetKey", "species", "scientificName",
    "taxonRank", "occurrenceStatus", "basisOfRecord",
    "countryCode", "stateProvince", "locality",
    "decimalLongitude", "decimalLatitude",
    "coordinateUncertaintyInMeters", "year", "issue",
    ".source_row", ".initial_exclusion"),
  names(occ)
)
utils::write.csv(
  occ[!is.na(reason), keep_columns, drop = FALSE],
  file.path(out_dir, "01_excluded_before_CC.csv"),
  row.names = FALSE, na = ""
)

candidates <- occ[is.na(reason), keep_columns, drop = FALSE]
candidates$.uncertainty_unreported <-
  is.na(candidates$coordinateUncertaintyInMeters)

# Run spatial tests on unique positions; map the results to all occurrences.
position_key <- function(x) paste(x$decimalLongitude, x$decimalLatitude,
                                  sep = "|")
unique_rows <- !duplicated(position_key(candidates))
unique_candidates <- candidates[unique_rows, , drop = FALSE]

tests <- c("capitals", "centroids", "equal",
           "gbif", "institutions", "seas", "zeros")
test_results <- CoordinateCleaner::clean_coordinates(
  x = unique_candidates,
  lon = "decimalLongitude", lat = "decimalLatitude",
  species = "species",
  tests = tests, value = "spatialvalid",
  verbose = TRUE, seas_scale = 50
)
stopifnot(".summary" %in% names(test_results))
stopifnot(nrow(test_results) == nrow(unique_candidates))

test_columns <- grep("^\\.", names(test_results), value = TRUE)
pair_map <- match(position_key(candidates),
                  position_key(unique_candidates))
stopifnot(!anyNA(pair_map))

for (nm in test_columns) {
  candidates[[nm]] <- test_results[[nm]][pair_map]
}
candidates$cc_all_tests_pass <- as.logical(candidates$.summary)
individual_tests <- setdiff(test_columns, ".summary")
candidates$cc_flagged_tests <- vapply(
  seq_len(nrow(candidates)),
  function(i) {
    bad <- individual_tests[!vapply(
      individual_tests,
      function(nm) isTRUE(candidates[[nm]][i]),
      logical(1)
    )]
    paste(bad, collapse = ";")
  },
  character(1)
)

utils::write.csv(candidates,
                 file.path(out_dir, "02_all_candidates_with_CC_flags.csv"),
                 row.names = FALSE, na = "")
utils::write.csv(
  candidates[!candidates$cc_all_tests_pass, , drop = FALSE],
  file.path(out_dir, "03_records_for_review.csv"),
  row.names = FALSE, na = ""
)
utils::write.csv(
  candidates[candidates$cc_all_tests_pass, , drop = FALSE],
  file.path(out_dir, "04_candidates_without_CC_flags.csv"),
  row.names = FALSE, na = ""
)

# Exploratory cell-level thinning at 5 arcminutes.
# This is not a final model-training dataset.
passed <- candidates[candidates$cc_all_tests_pass, , drop = FALSE]
passed$.cell_5min <- paste(
  floor((90 - passed$decimalLatitude) * 12),
  floor((passed$decimalLongitude + 180) * 12),
  sep = "_"
)
record_type_priority <- match(
  passed$basisOfRecord,
  c("PRESERVED_SPECIMEN", "HUMAN_OBSERVATION",
    "MACHINE_OBSERVATION", "MATERIAL_CITATION",
    "OCCURRENCE", "MATERIAL_SAMPLE")
)
record_type_priority[is.na(record_type_priority)] <- 99
ord <- order(is.na(passed$coordinateUncertaintyInMeters),
             passed$coordinateUncertaintyInMeters,
             record_type_priority, passed$gbifID, na.last = TRUE)
passed <- passed[ord, , drop = FALSE]
cell_sample <- passed[!duplicated(passed$.cell_5min), , drop = FALSE]
utils::write.csv(
  cell_sample, file.path(out_dir, "05_occurrences_one_per_5min_cell.csv"),
  row.names = FALSE, na = ""
)

audit <- data.frame(
  indicator = c("GBIF_original", "excluded_before_CC",
                "candidates_before_CC", "unique_positions_before_CC",
                "candidate_records_passing_CC",
                "candidate_records_flagged_CC",
                "unique_5min_cells_without_CC_flags",
                "candidate_records_without_uncertainty"),
  n = c(nrow(occ), sum(!is.na(reason)), nrow(candidates),
        nrow(unique_candidates), sum(candidates$cc_all_tests_pass),
        sum(!candidates$cc_all_tests_pass), nrow(cell_sample),
        sum(candidates$.uncertainty_unreported))
)
for (nm in individual_tests) {
  audit <- rbind(audit, data.frame(
    indicator = paste0("failed_", nm),
    n = sum(!as.logical(candidates[[nm]]), na.rm = TRUE)
  ))
}
utils::write.csv(
  audit, file.path(out_dir, "06_coordinate_quality_summary.csv"),
  row.names = FALSE, na = ""
)
writeLines(c(
  "GBIF coordinate-quality screening audit",
  paste("CoordinateCleaner version:",
        utils::packageVersion("CoordinateCleaner")),
  paste("R version:", R.version.string),
  paste("Tests:", paste(tests, collapse = ", ")),
  "Flagged records require inspection and are not automatically discarded.",
  "Urban and outlier tests are not used for this synanthropic introduced species.",
  "Sampling bias and an accessible calibration area are separate decisions."
), file.path(out_dir, "07_execution_metadata.txt"))
print(audit, row.names = FALSE)
message("Coordinate-quality files saved to: ", out_dir)
