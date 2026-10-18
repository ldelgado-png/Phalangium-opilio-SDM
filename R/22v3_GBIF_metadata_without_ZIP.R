# Phalangium opilio | Verify a GBIF download WITHOUT fetching the ZIP.
# Version 3: new file path avoids previously cached GitHub raw content.
# No credentials, occurrence records, models, or field observations used.
#
# Run in RStudio from any directory:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/22v3_GBIF_metadata_without_ZIP.R")

message("[R22 v3] Reading GBIF metadata JSON only; NOT downloading the ZIP.")
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Install jsonlite: install.packages('jsonlite')")
}
download_key <- "0033385-260928105237408"
metadata_url <- paste0(
  "https://api.gbif.org/v1/occurrence/download/", download_key
)
metadata <- jsonlite::fromJSON(metadata_url, simplifyVector = FALSE)
if (!is.list(metadata) || !identical(as.character(metadata$key),
                                     download_key)) {
  stop("GBIF returned unexpected download metadata.")
}

# Use explicit scalar fallbacks; avoid relying on inline if/else syntax.
scalar <- function(value) {
  if (is.null(value) || length(value) != 1L) {
    return(NA_character_)
  }
  as.character(value)
}
status <- scalar(metadata$status)
download_format <- scalar(metadata$request$format)
doi <- scalar(metadata$doi)
records <- suppressWarnings(as.numeric(scalar(metadata$totalRecords)))
bytes <- suppressWarnings(as.numeric(scalar(metadata$size)))
size_gib <- round(bytes / (1024^3), 3)

cat("\n[R22 v3] GBIF DOWNLOAD METADATA (NO ZIP)\n")
cat("Key: ", download_key, "\n", sep = "")
cat("Status: ", status, "\n", sep = "")
cat("Format: ", download_format, "\n", sep = "")
cat("Total records: ", format(records, scientific = FALSE,
                                 big.mark = ","), "\n", sep = "")
cat("ZIP size in GiB: ", size_gib, "\n", sep = "")
cat("DOI: ", doi, "\n", sep = "")

# Display just the predicate; never print owner credentials/contact details.
cat("\nFilters from the original GBIF request:\n")
if (is.null(metadata$request$predicate)) {
  cat("Not included in API metadata. Review the GBIF download page.\n")
}
if (!is.null(metadata$request$predicate)) {
  str(metadata$request$predicate, max.level = 8L)
}

cat("\nCheck before using R/21: ")
if (!is.finite(bytes) || !is.finite(records) ||
    bytes > 1024^3 || records > 1e6) {
  cat("STOP: too large or incomplete metadata; do not load this ZIP.\n")
}
if (is.finite(bytes) && is.finite(records) &&
    bytes <= 1024^3 && records <= 1e6) {
  cat("Size threshold passed; source filtering still needs verification.\n")
}
cat("No ZIP downloaded, no model fitted, no Venezuelan observations accessed.\n")
