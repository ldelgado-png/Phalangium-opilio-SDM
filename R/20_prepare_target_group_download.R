# Phalangium opilio | Prepare independent Opiliones target-group download
#
# RStudio, from the project root:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/20_prepare_target_group_download.R")
#
# The DEFAULT is a dry run that creates a fully inspectable GBIF query
# without downloading occurrences or transmitting account credentials.
# This query is for candidate discovery in the HISTORICAL PILOT RECTANGLE;
# it does NOT define a biogeographically accessible area M.
#
# To request the separately citable GBIF download later, only after
# inspection/approval, configure GBIF_USER, GBIF_PWD and GBIF_EMAIL in
# your local ~/.Renviron and then opt in using:
# options(phalangium.submit_target_group_download = TRUE)
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/20_prepare_target_group_download.R")
# options(phalangium.submit_target_group_download = FALSE)
#
# NEVER paste credentials into scripts, published logs or GitHub.

if (!requireNamespace("rgbif", quietly = TRUE)) {
  stop("Install rgbif before continuing: install.packages('rgbif')")
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
effort_dir <- file.path(root, "01_datos", "sampling_effort")
counts_file <- file.path(
  effort_dir, "23_gbif_target_group_count_feasibility.csv"
)
if (!file.exists(counts_file)) {
  stop("Missing completed R/19 results: ", counts_file,
       ". Run R/19 from the original project directory first.")
}
counts <- utils::read.csv(counts_file, stringsAsFactors = FALSE)
expected_cols <- c(
  "domain", "fold", "west", "east", "south", "north",
  "order_taxon_key", "focal_taxon_key", "years",
  "order_count", "focal_count", "difference_order_minus_focal"
)
if (length(setdiff(expected_cols, names(counts))) > 0L ||
    nrow(counts) != 5L ||
    sum(counts$domain == "pilot_rectangle") != 1L) {
  stop("Unexpected R/19 table shape or columns.")
}
reference <- counts[counts$domain == "pilot_rectangle", , drop = FALSE]
if (nrow(reference) != 1L ||
    !identical(as.character(reference$order_taxon_key), "907") ||
    !identical(as.character(reference$focal_taxon_key), "5776654") ||
    !identical(as.character(reference$years), "1980-2025") ||
    reference$west != -12 || reference$east != 60 ||
    reference$south != 30 || reference$north != 72 ||
    reference$order_count - reference$focal_count !=
      reference$difference_order_minus_focal) {
  stop("The documented GBIF taxonomic, spatial or temporal keys changed.")
}
folds <- counts[counts$domain != "pilot_rectangle", , drop = FALSE]
if (nrow(folds) != 4L ||
    sum(folds$order_count) != reference$order_count ||
    sum(folds$focal_count) != reference$focal_count) {
  stop("R/19 fold counts are inconsistent with the archived total.")
}
cat("\n[R20] Observed exploratory availability:",
    reference$order_count, "Opiliones; ",
    reference$focal_count, "focal; ",
    reference$difference_order_minus_focal, "non-focal (count difference).\n")

# Use the GBIF Backbone checklist to match R/19's numeric GBIF keys.
# New rgbif versions may otherwise default to the COL XR taxonomy.
gbif_backbone_uuid <- "d7dddbf4-2cf0-4f39-9b2a-bb099caae36c"
wkt <- "POLYGON((-12 30,60 30,60 72,-12 72,-12 30))"

# Construct a GBIF predicate, not a sampled background.
# pred_not() excludes the focal species taxon with the SAME taxonomy
# as the encompassing Opiliones predicate.
predicate <- rgbif::pred_and(
  rgbif::pred("taxonKey", "907"),
  rgbif::pred_not(rgbif::pred("taxonKey", "5776654")),
  rgbif::pred("occurrenceStatus", "PRESENT"),
  rgbif::pred("hasCoordinate", TRUE),
  rgbif::pred_gte("year", 1980),
  rgbif::pred_lte("year", 2025),
  rgbif::pred_within(wkt)
)

outdir <- file.path(effort_dir, "target_group_preparation")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
predicate_file <- file.path(outdir, "24_nonfocal_opiliones_predicate.rds")
notes_file <- file.path(outdir, "24_target_group_download_review.txt")
saveRDS(predicate, predicate_file)

writeLines(c(
  "Candidate GBIF Opiliones target-group data download (REVIEW ONLY).",
  paste("Prepared:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("rgbif:", as.character(utils::packageVersion("rgbif"))),
  paste("GBIF Backbone taxonomy checklistKey:", gbif_backbone_uuid),
  "Order: Opiliones (GBIF Backbone taxonKey 907).",
  "Excluded species: Phalangium opilio (taxonKey 5776654).",
  "Occurrence status PRESENT; coordinates required; event years 1980-2025.",
  paste("Counter-clockwise WKT:", wkt),
  paste("Archived total Opiliones:", reference$order_count),
  paste("Archived focal count:", reference$focal_count),
  paste("Preliminary non-focal count difference:",
        reference$difference_order_minus_focal),
  "IMPORTANT: these R/19 figures are live SEARCH API counts, not a download.",
  "The eventual downloaded record count may differ due to GBIF changes.",
  "This rectangle is a legacy exploratory bounding box, NOT accessible M.",
  "A completed target-group background requires screening of taxonomy,",
  "coordinates and possible spatial sampling biases; duplicate records",
  "and repeated records in the same 5-arcminute climate cell must be handled.",
  "Assess which non-focal taxa plausibly share the focal sampling process.",
  "After M is biogeographically justified, restrict the screened pool to M.",
  "No model fitting, candidate selection or Venezuelan field data are used.",
  "The default execution PREPARES but DOES NOT REQUEST a download.",
  "Set options(phalangium.submit_target_group_download = TRUE) explicitly",
  "and configure local GBIF_USER, GBIF_PWD, GBIF_EMAIL to request a DOI.",
  "Never save credentials in this project or include them in screenshots."
), notes_file)

cat("\n[R20] Reviewed candidate predicate:\n")
print(predicate)
cat("\nPrepared local review outputs:\n",
    normalizePath(outdir, winslash = "/"), "\n")

submit <- isTRUE(
  getOption("phalangium.submit_target_group_download", FALSE)
)
if (!submit) {
  cat("\nDRY RUN ONLY. No GBIF download requested.\n")
} else {
  required <- c("GBIF_USER", "GBIF_PWD", "GBIF_EMAIL")
  present <- nzchar(Sys.getenv(required, unset = ""))
  if (!all(present)) {
    stop("GBIF credentials are not all configured locally: ",
         paste(required[!present], collapse = ", "),
         ". Configure ~/.Renviron; never share passwords.")
  }
  params <- names(formals(rgbif::occ_download))
  if (!"checklistKey" %in% params) {
    stop("Update rgbif to an API version supporting checklistKey before ",
         "using the GBIF Backbone numeric taxon keys.")
  }
  # Explicit opt-in; no credentials printed or written to files.
  req <- rgbif::occ_download(
    predicate, format = "SIMPLE_CSV",
    checklistKey = gbif_backbone_uuid,
    user = Sys.getenv("GBIF_USER"),
    pwd = Sys.getenv("GBIF_PWD"),
    email = Sys.getenv("GBIF_EMAIL")
  )
  capture <- capture.output(print(req))
  capture <- capture[!grepl("GBIF_PWD|password", capture,
                             ignore.case = TRUE)]
  writeLines(c(
    "GBIF candidate target-group download was submitted on explicit opt-in.",
    paste("Submitted:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    capture,
    "Retain the returned GBIF download key and DOI for citations.",
    "No records are automatically imported or used for fitting."
  ), file.path(outdir, "25_target_group_download_receipt.txt"))
  cat("\nGBIF request submitted. Retain its key and eventual DOI:\n")
  print(req)
}
