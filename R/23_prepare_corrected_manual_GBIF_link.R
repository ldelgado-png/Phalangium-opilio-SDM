# Phalangium opilio | Prepare corrected manual GBIF download link
#
# From the project root in RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/23_prepare_corrected_manual_GBIF_link.R")
#
# No GBIF credentials; no download is requested; no ZIP is accessed.
# This step supplies a link to GBIF's manual download predicate form.
# Users MUST verify the displayed total and predicates before submission.
# This is a provisional Western Palaearctic RECTANGLE, not a defended M.
# None of the seven Venezuelan field collection events is accessed.

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Install jsonlite: install.packages('jsonlite')")
}

backbone <- "d7dddbf4-2cf0-4f39-9b2a-bb099caae36c"
geometry <- "POLYGON((-12 30,60 30,60 72,-12 72,-12 30))"
is_taxon <- function(taxon_key) {
  list(type = "equals", key = "TAXON_KEY",
       value = as.character(taxon_key), checklistKey = backbone)
}
query <- list(
  type = "and",
  predicates = list(
    is_taxon("907"),
    list(type = "not", predicate = is_taxon("5776654")),
    list(type = "equals", key = "OCCURRENCE_STATUS", value = "PRESENT"),
    list(type = "equals", key = "HAS_COORDINATE", value = "true"),
    list(type = "greaterThanOrEquals", key = "YEAR", value = "1980"),
    list(type = "lessThanOrEquals", key = "YEAR", value = "2025"),
    list(type = "within", geometry = geometry)
  )
)

outdir <- file.path(
  normalizePath(getwd(), winslash = "/", mustWork = TRUE),
  "01_datos", "sampling_effort", "target_group_preparation"
)
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
predicate_path <- file.path(outdir,
                            "31_corrected_manual_GBIF_predicate.json")
jsonlite::write_json(query, predicate_path, auto_unbox = TRUE,
                     pretty = TRUE)
compact <- jsonlite::toJSON(query, auto_unbox = TRUE, pretty = FALSE)
url <- paste0(
  "https://www.gbif.org/occurrence/download/request/about?predicate=",
  utils::URLencode(as.character(compact), reserved = TRUE)
)
writeLines(url, file.path(outdir, "31_corrected_manual_GBIF_link.txt"))

cat("\n[R23] MANUAL GBIF FILTERS — NOT SUBMITTED\n")
cat("Positive taxon: Opiliones, GBIF Backbone TAXON_KEY 907\n")
cat("Exclude species: Phalangium opilio, GBIF Backbone 5776654\n")
cat("Checklist taxonomy: ", backbone, "\n", sep = "")
cat("Years: 1980–2025; coordinates required; PRESENT only\n")
cat("Geometry WKT: ", geometry, "\n", sep = "")
cat("Download format to select in GBIF: SIMPLE_CSV\n")
cat("Before submitting, confirm that the preview contains a positive\n")
cat("Opiliones taxon filter. The old 1.25-billion-record request did NOT.\n")
cat("The R/19 count (~270,072 non-focal records) is a historical\n")
cat("search-API estimate, NOT a guarantee of the new download count.\n")
cat("The GBIF interface may use Catalogue of Life instead of the older\n")
cat("GBIF Backbone; use the actual order NAME and verify the positive\n")
cat("taxon filter if the browser remaps taxon identifiers.\n")
cat("\nOpen or paste this GBIF download form URL in a browser:\n", url, "\n")
cat("\nSaved local JSON: ", predicate_path, "\n", sep = "")
cat("NO occurrence download requested. NO field data loaded.\n")
