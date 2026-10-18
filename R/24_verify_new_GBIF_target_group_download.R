# Phalangium opilio | Check a NEW GBIF download before fetching its ZIP.
# No credentials, no occurrence download, no model fitting.
# The seven Venezuelan field events are not accessed.
#
# Once GBIF has generated a NEW download key, use:
# options(phalangium.target_group_download_key = "NEW_DOWNLOAD_KEY")
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/24_verify_new_GBIF_target_group_download.R")
#
# IMPORTANT: only GBIF metadata JSON is read. This script refuses the
# incorrect request 0033385-260928105237408.

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Install jsonlite once: install.packages('jsonlite')")
}

key <- getOption("phalangium.target_group_download_key", "")
if (!is.character(key) || length(key) != 1L ||
    !grepl("^[0-9]+-[0-9]+$", key)) {
  stop("Supply your NEW GBIF key first via ",
       "options(phalangium.target_group_download_key = 'NEW_KEY').")
}
if (identical(key, "0033385-260928105237408")) {
  stop("REFUSED: the old request has 1,249,731,175 records ",
       "and no positive Opiliones filter.")
}
url <- paste0("https://api.gbif.org/v1/occurrence/download/", key)
message("[R24] Reading GBIF metadata only (not the ZIP): ", key)
meta <- tryCatch(
  jsonlite::fromJSON(url, simplifyVector = FALSE),
  error = function(e) {
    stop("GBIF download metadata could not be retrieved: ",
         conditionMessage(e))
  }
)
if (!is.list(meta) || !identical(as.character(meta$key), key)) {
  stop("Unexpected GBIF metadata or download key.")
}

scalar <- function(x) {
  if (is.null(x) || length(x) != 1L) {
    return(NA_character_)
  }
  as.character(x)
}
status <- scalar(meta$status)
fmt <- scalar(meta$request$format)
doi <- scalar(meta$doi)
nrec <- suppressWarnings(as.numeric(scalar(meta$totalRecords)))
size <- suppressWarnings(as.numeric(scalar(meta$size)))

# Walk the REAL submitted predicate, preserving the sign of NOT.
# Only positively constrained Opiliones and negatively constrained
# P. opilio under GBIF Backbone count as a verified combination.
walk_pred <- function(p, negative = FALSE) {
  if (is.null(p) || !is.list(p)) {
    return(list())
  }
  type <- toupper(scalar(p$type))
  if (identical(type, "NOT")) {
    return(walk_pred(p$predicate, !negative))
  }
  if (type %in% c("AND", "OR")) {
    return(unlist(lapply(p$predicates, walk_pred, negative = negative),
                  recursive = FALSE))
  }
  val <- scalar(p$value)
  if (!is.null(p$values)) {
    val <- paste(unlist(p$values, use.names = FALSE), collapse = ";")
  }
  list(list(type = type, key = scalar(p$key), value = val,
            checklist = scalar(p$checklistKey),
            geometry = scalar(p$geometry), negative = negative))
}

checks <- walk_pred(meta$request$predicate)
matches <- function(field, value, negative = FALSE, checklist = NULL) {
  any(vapply(checks, function(p) {
    if (!identical(p$negative, negative) ||
        !identical(p$key, field) ||
        !p$type %in% c("EQUALS", "IN") ||
        is.na(p$value) ||
        !value %in% strsplit(p$value, ";", fixed = TRUE)[[1]]) {
      return(FALSE)
    }
    if (!is.null(checklist) && !identical(p$checklist, checklist)) {
      return(FALSE)
    }
    TRUE
  }, logical(1)))
}
has_comparison <- function(field, op, value) {
  any(vapply(checks, function(p) {
    !p$negative && identical(p$type, op) &&
      identical(p$key, field) && identical(p$value, value)
  }, logical(1)))
}
has_geom <- any(vapply(checks, function(p) {
  !p$negative &&
    identical(p$type, "WITHIN") &&
    identical(p$geometry,
              "POLYGON((-12 30,60 30,60 72,-12 72,-12 30))")
}, logical(1)))

backbone <- "d7dddbf4-2cf0-4f39-9b2a-bb099caae36c"
checks_report <- c(
  positive_Opiliones_Backbone =
    matches("TAXON_KEY", "907", checklist = backbone),
  negative_Phalangium_opilio_Backbone =
    matches("TAXON_KEY", "5776654", negative = TRUE,
            checklist = backbone),
  occurrence_PRESENT = matches("OCCURRENCE_STATUS", "PRESENT"),
  has_coordinates = matches("HAS_COORDINATE", "true"),
  year_at_least_1980 =
    has_comparison("YEAR", "GREATERTHANOREQUALS", "1980"),
  year_at_most_2025 =
    has_comparison("YEAR", "LESSTHANOREQUALS", "2025"),
  intended_exploratory_polygon = has_geom
)

cat("\n[R24] NEW GBIF DOWNLOAD — VERIFIED METADATA, NO ZIP\n")
cat("Key: ", key, "\n", sep = "")
cat("Status: ", status, "\n", sep = "")
cat("Format: ", fmt, "\n", sep = "")
cat("Records: ", format(nrec, scientific = FALSE, big.mark = ","),
    "\n", sep = "")
cat("Compressed size (GiB): ",
    if (is.finite(size)) round(size / 1024^3, 4) else NA,
    "\n", sep = "")
cat("DOI: ", doi, "\n", sep = "")
cat("\nChecks against the actual GBIF request:\n")
print(checks_report)
cat("\n")
safe_size <- is.finite(size) && is.finite(nrec) &&
  size > 0 && size <= 1024^3 && nrec > 0 && nrec <= 1e6
ready <- identical(status, "SUCCEEDED") &&
  identical(fmt, "SIMPLE_CSV") && all(checks_report) && safe_size

if (ready) {
  cat("[R24] All checks passed under the conservative ",
      "1 GiB / 1-million-record processing cap.\n", sep = "")
  cat("The source is eligible for further QC, ",
      "not automatically valid as a final target-group background.\n",
      sep = "")
}
if (!ready) {
  cat("[R24] STOP: request not fully verified, still processing, ",
      "or outside safety limits. DO NOT download or process the ZIP.\n",
      sep = "")
}
cat("[R24] No records downloaded; no model fitted; ",
    "Venezuelan field events remain withheld.\n", sep = "")
