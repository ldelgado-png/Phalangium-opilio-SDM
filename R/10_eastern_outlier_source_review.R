# Phalangium opilio | Source provenance for eastern climatic outliers
#
# Run after scripts 03 and 09, in RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/10_eastern_outlier_source_review.R")
#
# Reconstructs original GBIF record metadata for eastern points exceeding
# a univariate Western Palaearctic climatic bound. Does NOT remove
# occurrences, fit a model, or use Venezuelan field observations.

data_dir <- file.path(getwd(), "01_datos")
climate_dir <- file.path(data_dir, "climate_diagnostics")
input <- file.path(climate_dir, "34_eastern_eurasia_climate_cells.csv")

if (!file.exists(input)) {
  message("Select 34_eastern_eurasia_climate_cells.csv")
  input <- file.choose()
  if (basename(input) != "34_eastern_eurasia_climate_cells.csv") {
    stop("Select the full eastern Eurasian climate-cell CSV.")
  }
  climate_dir <- dirname(input)
  data_dir <- dirname(climate_dir)
}
source_zip <- file.path(data_dir, "gbif_descarga_original.zip")
if (!file.exists(source_zip)) {
  stop("Cannot find the original GBIF download at: ", source_zip)
}

east <- utils::read.csv(
  input, stringsAsFactors = FALSE, check.names = FALSE,
  colClasses = c(gbifID = "character"), na.strings = c("", "NA")
)
required <- c("gbifID", "outside_any_reference_range",
              "outside_reference_variables", "BIO4", "countryCode",
              "stateProvince", "coordinateUncertaintyInMeters")
if (length(setdiff(required, names(east)))) {
  stop("Missing fields: ", paste(setdiff(required, names(east)),
                                  collapse = ", "))
}
if (nrow(east) != 68L || anyDuplicated(east$gbifID)) {
  stop("Unexpected eastern climate-cell dataset; inspect the input.")
}
east$outside_any_reference_range <-
  as.logical(east$outside_any_reference_range)
target <- east[which(east$outside_any_reference_range), , drop = FALSE]
if (nrow(target) != 3L ||
    !all(target$countryCode == "RU") ||
    !all(target$outside_reference_variables == "BIO4")) {
  stop("Unexpected outlier subset; inspect prior climate calculations.")
}

member <- utils::unzip(source_zip, list = TRUE)$Name
member <- member[basename(member) == "0032625-260928105237408.csv"]
if (length(member) != 1L) {
  stop("The archived GBIF TSV is missing or has changed.")
}
message("Reading source GBIF archive to verify observation metadata...")
raw <- utils::read.delim(
  unz(source_zip, member),
  sep = "\t", header = TRUE, quote = "",
  colClasses = "character", check.names = FALSE,
  stringsAsFactors = FALSE, na.strings = c("", "NA"),
  fileEncoding = "UTF-8"
)
if (nrow(raw) != 63407L || !"gbifID" %in% names(raw)) {
  stop("Unexpected GBIF source archive.")
}
if (anyDuplicated(raw$gbifID)) {
  stop("GBIF source occurrence keys are not unique.")
}
matched <- match(as.character(target$gbifID), raw$gbifID)
if (anyNA(matched)) {
  stop("One or more eastern climate outliers are absent in the source.")
}
source <- raw[matched, , drop = FALSE]
if (any(as.character(target$gbifID) != source$gbifID)) {
  stop("Inconsistent source-key match.")
}

metadata <- c(
  "occurrenceID", "references", "datasetName", "publisher",
  "recordedBy", "identifiedBy", "identificationRemarks",
  "identificationVerificationStatus", "verbatimScientificName",
  "scientificName", "species", "taxonKey", "taxonID",
  "eventDate", "coordinateUncertaintyInMeters", "geodeticDatum",
  "locality", "stateProvince", "countryCode", "issue"
)
metadata <- intersect(metadata, names(source))
# Keep the source columns with unambiguous names and preserve all field flags.
for (col in metadata) {
  target[[paste0("source_", col)]] <- source[[col]]
}
target$BIO4_reference_max <- 1488.34229
target$BIO4_exceedance <- as.numeric(target$BIO4) -
                         target$BIO4_reference_max
target$BIO4_exceedance_pct <- round(
  100 * target$BIO4_exceedance / target$BIO4_reference_max, 2
)
target$source_dataset_is_iNaturalist <-
  source$datasetKey == "50c9509d-22c7-4a22-a47d-8c48425ef4a7"
if (!all(target$source_dataset_is_iNaturalist)) {
  warning("At least one record is not from the expected iNaturalist dataset.")
}
# Preserve only evidence supplied in the source. Do not invent media links.
link_fields <- intersect(
  c("source_occurrenceID", "source_references"), names(target)
)
message("Original-source identifier fields found: ",
        if (length(link_fields)) paste(link_fields, collapse = ", ")
        else "none")

output <- file.path(climate_dir,
                    "38_eastern_outliers_with_original_GBIF_metadata.csv")
utils::write.csv(target, output, row.names = FALSE, na = "")
brief <- target[, c("gbifID", "stateProvince", "year",
                    "coordinateUncertaintyInMeters", "BIO4",
                    "BIO4_exceedance", "BIO4_exceedance_pct",
                    "source_dataset_is_iNaturalist"), drop = FALSE]
cat("\nEASTERN EURASIAN OUTLIER SOURCE AUDIT\n")
print(brief, row.names = FALSE)
cat("\nSource metadata columns: ", paste(metadata, collapse = ", "), "\n")
cat("Full original-source metadata file:\n",
    normalizePath(output, winslash = "/", mustWork = TRUE), "\n")
cat("Flags and uncertainty values do not replace specimen/photo review.\n")
cat("Venezuelan field records are strictly held out of all analyses here.\n")
