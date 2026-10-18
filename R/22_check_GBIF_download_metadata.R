# Phalangium opilio | GBIF manual download metadata and safety preflight
#
# From the Phalangium project folder, run:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/22_check_GBIF_download_metadata.R")
#
# [R22 v2] Corrected R if/else block syntax throughout this script.
# This queries only a SMALL, PUBLIC JSON metadata object (NOT the ZIP).
# It does not require GBIF credentials, read any field observations,
# construct a background or fit a model.

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Install jsonlite once: install.packages('jsonlite')")
}
key <- "0033385-260928105237408"
url <- paste0("https://api.gbif.org/v1/occurrence/download/", key)
meta <- tryCatch(
  jsonlite::fromJSON(url, simplifyVector = FALSE),
  error = function(e) {
    stop("Could not read GBIF public metadata for ", key, ": ",
         conditionMessage(e), ". Try the URL in a web browser.")
  }
)
if (!is.list(meta) || !identical(as.character(meta$key), key)) {
  stop("Unexpected download metadata or download key.")
}
fmt <- if (is.null(meta$request$format)) {
  NA_character_
} else {
  as.character(meta$request$format)
}
nrec <- if (is.null(meta$totalRecords)) {
  NA_real_
} else {
  suppressWarnings(as.numeric(meta$totalRecords))
}
size <- if (is.null(meta$size)) {
  NA_real_
} else {
  suppressWarnings(as.numeric(meta$size))
}
doi <- if (is.null(meta$doi)) {
  NA_character_
} else {
  as.character(meta$doi)
}
status <- if (is.null(meta$status)) {
  NA_character_
} else {
  as.character(meta$status)
}

# Show predicates without printing the request owner, email or auth info.
walk_pred <- function(x) {
  if (!is.list(x)) return(character())
  out <- character()
  if (!is.null(x$key)) {
    field <- as.character(x$key)
    val <- if (is.null(x$value)) "" else as.character(x$value)
    if (!is.null(x$values)) {
      val <- paste(unlist(x$values, use.names = FALSE), collapse = ";")
    }
    out <- c(out, paste(as.character(x$type), field, val))
  }
  if (!is.null(x$predicates)) {
    out <- c(out, unlist(lapply(x$predicates, walk_pred),
                         use.names = FALSE))
  }
  if (!is.null(x$predicate)) {
    out <- c(out, walk_pred(x$predicate))
  }
  out
}
predicates <- walk_pred(meta$request$predicate)
cat("\n[R22] VERIFIED GBIF DOWNLOAD METADATA — NO ZIP DOWNLOADED\n")
cat("Download key:     ", key, "\n")
cat("Status:           ", status, "\n")
cat("Format:           ", fmt, "\n")
cat("Occurrence count: ", format(nrec, big.mark = ",",
                                    scientific = FALSE), "\n")
size_gib <- if (is.finite(size)) {
  round(size / 1024^3, 3)
} else {
  NA_real_
}
cat("ZIP size (GiB):   ", size_gib, "\n")
cat("DOI:              ", doi, "\n")
cat("\nOriginal download filters (inspect carefully):\n")
if (length(predicates)) {
  cat(paste0("- ", predicates, collapse = "\n"), "\n")
} else {
  cat("Predicates unavailable in metadata; inspect the download page.\n")
}

expected_n <- 313521
large <- !is.finite(size) || size > 1024^3
many <- !is.finite(nrec) || nrec > 1e6
if (large || many) {
  cat("\nWARNING: This download is too large or incompletely documented ",
      "for the current R/21 workflow. Do not download or load the ZIP.\n",
      "The previous R/19 preflight counted ~313,521 Opiliones records ",
      "in the exploratory rectangle; check taxonomy, location and ",
      "download format on the GBIF page.\n", sep = "")
} else {
  cat("\nSize gate (<1 GiB; <=1 million rows): passed. ",
      "This is NOT a data-quality or taxonomy validation.\n", sep = "")
}
cat("No model fitted and no Venezuelan observations used.\n")
