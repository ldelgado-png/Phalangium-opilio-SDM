# Phalangium opilio | Inspect manual GBIF Opiliones download
#
# Run from the project directory in RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/21_audit_manual_GBIF_target_group.R")
#
# No GBIF account or password is required to read the PUBLIC completed ZIP.
# This audit does not fit any SDM, define accessible M, tune predictors,
# compare candidate fits, or load the seven held-out Venezuelan field events.
# The pilot Western Palaearctic rectangle is a historical sensitivity window,
# NOT the asserted accessible calibration area M.

required <- c("data.table", "terra", "ENMeval", "jsonlite")
missing <- required[!vapply(required, requireNamespace, logical(1),
                             quietly = TRUE)]
if (length(missing)) {
  stop("Install required packages first: install.packages(c(",
       paste(sprintf('"%s"', missing), collapse = ", "), "))")
}
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
data_dir <- file.path(root, "01_datos")
clim_path <- file.path(data_dir, "climate_diagnostics",
                       "16_worldclim_western_window_5m.tif")
pilot_dir <- file.path(root, "04_resultados_modelo",
                       "pilot_western_palaearctic")
eval_path <- file.path(pilot_dir, "07_ENMeval_pilot_evaluation.rds")
presence_path <- file.path(pilot_dir,
                           "01_pilot_calibration_occurrences.csv")
if (!all(file.exists(c(clim_path, eval_path, presence_path)))) {
  stop("Open the original Phalangium_opilio_SDM project folder in RStudio. ",
       "Required prior WorldClim and ENMeval files were not found.")
}
key <- "0033385-260928105237408"
base_url <- "https://api.gbif.org/v1/occurrence/download/"
download_url <- paste0(base_url, "request/", key, ".zip")
outdir <- file.path(data_dir, "sampling_effort", "target_group_preparation")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
zip_path <- file.path(outdir, paste0(key, ".zip"))

# The download metadata are an extra check, not an excuse to silently
# substitute a different GBIF dataset when this specific link is unavailable.
meta <- tryCatch(
  jsonlite::fromJSON(paste0(base_url, key)),
  error = function(e) {
    message("GBIF metadata query unavailable: ", conditionMessage(e))
    NULL
  }
)
doi <- NA_character_
if (!is.null(meta)) {
  status <- as.character(meta$status)
  if (length(status) == 1L && nzchar(status) &&
      !identical(status, "SUCCEEDED")) {
    stop("GBIF download status is ", status, ", not SUCCEEDED.")
  }
  if (!is.null(meta$doi) && length(meta$doi) == 1L) {
    doi <- as.character(meta$doi)
  }
  message("GBIF metadata: status=", status, "; DOI=", doi)
}
# IMPORTANT: protect local storage/RAM. Do not automatically retrieve
# unusually large GBIF ZIPs, and never treat an incomplete ZIP as usable.
# Run R/22 metadata-only preflight first to check original download filters.
max_zip_bytes <- 1024^3    # conservative 1 GiB zipped
max_records <- 1e6         # conservative record-processing limit
if (is.null(meta) ||
    is.null(meta$size) || is.null(meta$totalRecords) ||
    !is.finite(suppressWarnings(as.numeric(meta$size))) ||
    !is.finite(suppressWarnings(as.numeric(meta$totalRecords)))) {
  stop("Cannot verify ZIP size and record count from public GBIF metadata. ",
       "Do NOT download the archive blindly. Run R/22 first.")
}
declared_size <- as.numeric(meta$size)
declared_records <- as.numeric(meta$totalRecords)
message("[R21] GBIF archive metadata: ",
        round(declared_size / 1024^3, 3), " GiB zipped; ",
        format(declared_records, big.mark = ",", scientific = FALSE),
        " records.")
if (declared_size > max_zip_bytes || declared_records > max_records) {
  stop("GBIF ZIP exceeds the safe automated R/21 limit (1 GiB or 1 million ",
       "records). Do NOT download or process it in this script. ",
       "Review GBIF download predicates and prefer a smaller SIMPLE_CSV.")
}
if (file.exists(zip_path) && file.info(zip_path)$size > max_zip_bytes) {
  stop("Local ZIP is already larger than 1 GiB. It is likely not the ",
       "intended compact Opiliones data set. Run R/22 to inspect metadata.")
}
if (file.exists(zip_path) &&
    is.finite(file.info(zip_path)$size) &&
    file.info(zip_path)$size > 1000 &&
    file.info(zip_path)$size < declared_size * 0.99) {
  stop("Locally cached ZIP is shorter than the declared GBIF archive size ",
       "(probably an incomplete download). Do not unzip it.")
}
if (!file.exists(zip_path) ||
    is.na(file.info(zip_path)$size) ||
    file.info(zip_path)$size < 1000) {
  message("Downloading the user-provided public GBIF ZIP: ", download_url)
  tryCatch(
    {
      utils::download.file(download_url, destfile = zip_path,
                           method = "libcurl", mode = "wb", quiet = FALSE)
    },
    error = function(e) {
      stop("ZIP could not be downloaded automatically: ",
           conditionMessage(e),
           ". Download it through your browser and save it as ",
           zip_path, ", then rerun the script.")
    }
  )
}
if (!file.exists(zip_path) || file.info(zip_path)$size < 1000) {
  stop("Download is missing or unexpectedly small: ", zip_path)
}
info <- tryCatch(utils::unzip(zip_path, list = TRUE),
                 error = function(e) {
                   stop("The GBIF ZIP appears unreadable: ",
                        conditionMessage(e))
                 })
if (!is.data.frame(info) || !nrow(info)) stop("Empty GBIF ZIP.")
entries <- as.character(info$Name)
if (any(grepl("(^/|(^|/)\\.\\.(/|$)|^[A-Za-z]:)", entries))) {
  stop("Unsafe ZIP paths: do not extract this archive.")
}
# Prefer the interpreted Darwin Core occurrence table if available, or
# the main GBIF SIMPLE_CSV. Refuse ambiguous archives.
candidates <- entries[grepl("\\.(csv|txt|tsv)$", entries, ignore.case = TRUE) &
                        !grepl("(^|/)(citations|rights|multimedia|verbatim|meta|dataset)",
                               entries, ignore.case = TRUE)]
if (!length(candidates)) {
  stop("Could not locate the GBIF occurrence data table in the ZIP. Files: ",
       paste(head(entries, 30), collapse = "; "))
}
score <- ifelse(grepl("(^|/)occurrence\\.(txt|csv|tsv)$",
                        candidates, ignore.case = TRUE), 0L,
                ifelse(grepl(key, candidates, fixed = TRUE), 1L, 2L))
selected <- candidates[order(score, nchar(candidates))][1]
message("Selected archive table: ", selected)
dir_data <- file.path(outdir, "unpacked")
dir.create(dir_data, recursive = TRUE, showWarnings = FALSE)
utils::unzip(zip_path, files = selected, exdir = dir_data, overwrite = TRUE)
source_path <- file.path(dir_data, selected)
if (!file.exists(source_path)) stop("Cannot extract ", selected)

# Read only the columns needed for the audit rather than loading every
# Darwin Core field into memory. GBIF SIMPLE_CSV is tab-delimited.
headers <- names(data.table::fread(source_path, nrows = 0L,
                                    encoding = "UTF-8", showProgress = FALSE))
needed <- c(
  "gbifID", "gbifId", "decimalLongitude", "decimalLatitude",
  "taxonKey", "speciesKey", "orderKey", "order", "species",
  "scientificName", "occurrenceStatus", "year",
  "coordinateUncertaintyInMeters", "issues", "basisOfRecord",
  "datasetKey", "taxonRank", "countryCode", "eventDate"
)
select_cols <- intersect(needed, headers)
essential <- c("decimalLongitude", "decimalLatitude", "year")
if (length(setdiff(essential, headers)) ||
    !any(c("orderKey", "order") %in% headers) ||
    !any(c("speciesKey", "taxonKey", "species", "scientificName") %in%
         headers)) {
  stop("GBIF data columns are insufficient for a defensible audit. Found: ",
       paste(headers, collapse = ", "),
       ". Inspect archive format and taxonomy settings.")
}
identifiers <- intersect(c("gbifID", "gbifId", "speciesKey",
                            "taxonKey", "orderKey", "datasetKey"), headers)
char_classes <- stats::setNames(rep("character", length(identifiers)),
                                 identifiers)
D <- data.table::fread(
  source_path, select = select_cols, colClasses = char_classes,
  encoding = "UTF-8", showProgress = TRUE, na.strings = c("", "NA")
)
n_original <- nrow(D)
if (!n_original) stop("GBIF occurrence table is empty.")
get_col <- function(n, default = NA_character_) {
  if (n %in% names(D)) as.character(D[[n]])
  else rep(default, n_original)
}
# GBIF downloads can encode taxonomy in GBIF Backbone (numeric keys)
# or Catalogue of Life eXtended (alphanumeric keys).  Prefer the
# INTERPRETED order NAME as an additional check, not solely key 907.
has_order <- rep(FALSE, n_original)
if ("orderKey" %in% names(D)) {
  has_order <- has_order | (get_col("orderKey") == "907")
}
if ("order" %in% names(D)) {
  has_order <- has_order | (
    tolower(trimws(get_col("order"))) == "opiliones"
  )
}
has_order[is.na(has_order)] <- FALSE

# Exclude the focal species even if the website download omitted a NOT
# predicate. speciesKey captures infraspecific names when GBIF supplies it.
focal <- rep(FALSE, n_original)
if ("speciesKey" %in% names(D)) {
  focal <- focal | (!is.na(get_col("speciesKey")) &
                      get_col("speciesKey") == "5776654")
}
if ("taxonKey" %in% names(D)) {
  focal <- focal | (!is.na(get_col("taxonKey")) &
                      get_col("taxonKey") == "5776654")
}
for (col in intersect(c("species", "scientificName"), names(D))) {
  v <- get_col(col)
  focal <- focal | (!is.na(v) &
    grepl("^Phalangium[[:space:]]+opilio([[:space:]]|$)",
          v, ignore.case = TRUE))
}
if ("occurrenceStatus" %in% names(D)) {
  is_present <- toupper(trimws(get_col("occurrenceStatus"))) ==
    "PRESENT"
  is_present[is.na(is_present)] <- FALSE
} else {
  warning("No occurrenceStatus column: retained records cannot be ",
          "verified as PRESENT; stop until archive format is resolved.")
  stop("Missing occurrenceStatus; please provide the archive structure.")
}
y <- suppressWarnings(as.numeric(get_col("year")))
lon <- suppressWarnings(as.numeric(get_col("decimalLongitude")))
lat <- suppressWarnings(as.numeric(get_col("decimalLatitude")))
valid_year <- is.finite(y) & y >= 1980 & y <= 2025
valid_coords <- is.finite(lon) & is.finite(lat) &
  lon >= -12 & lon <= 60 & lat >= 30 & lat <= 72 &
  lon >= -180 & lon <= 180 & lat >= -90 & lat <= 90
issue <- get_col("issues", "")
issue[is.na(issue)] <- ""
bad_issues <- grepl(
  "COORDINATE_INVALID|COORDINATE_OUT_OF_RANGE|ZERO_COORDINATE|COUNTRY_COORDINATE_MISMATCH",
  issue, ignore.case = TRUE
)
unc <- suppressWarnings(as.numeric(
  get_col("coordinateUncertaintyInMeters")
))
unc_high <- is.finite(unc) & unc > 10000
bio <- terra::rast(clim_path)
if (!identical(names(bio), c("BIO1", "BIO4", "BIO12", "BIO15"))) {
  stop("Unexpected predictors in archived WorldClim grid.")
}
xy <- cbind(lon, lat)
cells <- rep(NA_real_, n_original)
cells[valid_coords] <- terra::cellFromXY(bio[[1]], xy[valid_coords, ,
                                                       drop = FALSE])
vals <- terra::values(bio, mat = TRUE)
valid_raster_cells <- rowSums(is.finite(vals)) == 4L
has_climate <- !is.na(cells)
has_climate[has_climate] <- valid_raster_cells[cells[has_climate]]

# Screen the downloaded table WITHOUT making a final target-group choice.
checks <- list(
  in_order = has_order,
  not_focal = !focal,
  status_present = is_present,
  year_1980_2025 = valid_year,
  coordinates_in_pilot_window = valid_coords,
  climate_cell_with_four_predictors = has_climate,
  no_major_GBIF_coordinate_flags = !bad_issues
)
progress <- data.frame(stage = "original_download_records",
                       remaining = n_original)
ok <- rep(TRUE, n_original)
for (nm in names(checks)) {
  flag <- checks[[nm]]
  flag[is.na(flag)] <- FALSE
  ok <- ok & flag
  progress <- rbind(progress, data.frame(stage = nm,
                                         remaining = sum(ok)))
}
pres <- utils::read.csv(presence_path, stringsAsFactors = FALSE)
if (nrow(pres) != 10426L ||
    !all(c("decimalLongitude", "decimalLatitude") %in% names(pres))) {
  stop("Archived pilot-presence data have changed unexpectedly.")
}
p_cell <- terra::cellFromXY(
  bio[[1]], as.matrix(pres[, c("decimalLongitude",
                               "decimalLatitude")])
)
if (anyNA(p_cell) || anyDuplicated(p_cell)) {
  stop("Pilot occurrence climatic-cell indexes are invalid.")
}
pre_overlap <- sum(ok & cells %in% p_cell)
ok <- ok & !(cells %in% p_cell)
progress <- rbind(progress,
                  data.frame(stage = "exclude_original_presence_cells",
                             remaining = sum(ok)))

# A species-independent candidate pool: choose one record per
# 5-arcminute predictor cell, prioritize known smaller uncertainty,
# and KEEP this selection provisional pending further QC and M.
ix <- which(ok)
if (!length(ix)) stop("No eligible non-focal records after initial QC.")
sort_unc <- unc[ix]
sort_unc[!is.finite(sort_unc)] <- Inf
id <- get_col("gbifID")
if (!"gbifID" %in% names(D)) id <- get_col("gbifId")
ix <- ix[order(cells[ix], sort_unc, id[ix], na.last = TRUE)]
ix <- ix[!duplicated(cells[ix])]
centers <- terra::xyFromCell(bio[[1]], cells[ix])
picked <- data.frame(
  cell = cells[ix],
  longitude = centers[, 1],
  latitude = centers[, 2],
  source_gbif_id = id[ix],
  source_dataset_key = get_col("datasetKey")[ix],
  taxon_key = get_col("taxonKey")[ix],
  species_key = get_col("speciesKey")[ix],
  basis_of_record = get_col("basisOfRecord")[ix],
  coordinate_uncertainty_m = unc[ix],
  stringsAsFactors = FALSE
)

# Recover the exact historical four-fold structure (no new partition).
e <- readRDS(eval_path)
if (!methods::is(e, "ENMevaluation")) {
  stop("Unexpected ENMeval evaluation object.")
}
g <- as.character(ENMeval::eval.occs.grp(e))
p <- as.data.frame(ENMeval::eval.occs(e))
if (nrow(p) != 10426L || length(g) != 10426L) {
  stop("Archived ENMeval occurrence metadata have changed.")
}
levels <- sort(unique(g))
if (length(levels) != 4L) stop("Expected exactly four original folds.")
folds <- do.call(rbind, lapply(levels, function(k) {
  a <- as.numeric(p[[2]][g == k])
  data.frame(group = k, lo = min(a), hi = max(a),
             median = stats::median(a))
}))
folds <- folds[order(folds$median), , drop = FALSE]
bounds <- vapply(1:3, function(j)
  (folds$hi[j] + folds$lo[j + 1]) / 2, numeric(1))
fold_fn <- function(z) folds$group[
  findInterval(z, c(-Inf, bounds, Inf), rightmost.closed = TRUE)
]
if (!identical(fold_fn(as.numeric(p[[2]])), g)) {
  stop("Reconstruction does not match the archived spatial folds.")
}
picked$fold <- as.character(fold_fn(picked$latitude))
by_fold <- do.call(rbind, lapply(levels, function(k) {
  available <- ix[picked$fold == k]
  data.frame(
    fold = k,
    candidate_unique_5arcmin_cells = length(available),
    retained_records_unknown_uncertainty = sum(!is.finite(unc[available])),
    retained_records_uncertainty_over_10km = sum(unc_high[available]),
    stringsAsFactors = FALSE
  )
}))
rownames(by_fold) <- NULL

# Diagnostics and provisional candidates stay in the LOCAL working folder.
# The candidate cell CSV contains GBIF identifiers, not held-out field data.
progress <- rbind(progress,
                  data.frame(stage = "one_nonfocal_record_per_climate_cell",
                             remaining = nrow(picked)))
utils::write.csv(progress,
                 file.path(outdir, "26_target_group_first_pass_screening.csv"),
                 row.names = FALSE)
utils::write.csv(by_fold,
                 file.path(outdir, "27_target_group_unique_cells_by_fold.csv"),
                 row.names = FALSE)
utils::write.csv(picked,
                 file.path(outdir, "28_target_group_provisional_cells.csv"),
                 row.names = FALSE)
utils::write.csv(data.frame(
  characteristic = c(
    "download_archive_rows", "original_presence_cell_overlap",
    "archive_records_with_uncertainty_gt_10km",
    "archive_records_with_major_coordinate_issues",
    "archived_focal_species_rows", "archived_order_rows",
    "unique_candidate_climate_cells"
  ),
  count = c(
    n_original, pre_overlap, sum(unc_high),
    sum(bad_issues), sum(focal), sum(has_order), nrow(picked)
  )
), file.path(outdir, "29_target_group_additional_audit.csv"),
row.names = FALSE)
writeLines(c(
  paste("GBIF manual download key:", key),
  paste("Public archive:", download_url),
  paste("DOI from public metadata (if available):", doi),
  paste("ZIP MD5:", unname(tools::md5sum(zip_path))),
  paste("Archive size bytes:", file.info(zip_path)$size),
  paste("GBIF archive occurrence member:", selected),
  paste("Archive record count:", n_original),
  "First-pass environmental pixel screening only. No M adopted.",
  "Major GBIF coordinate issue flags excluded; other QC is still required.",
  "Uncertainty >10000m is reported, NOT automatically excluded.",
  "The original 10426 pilot presence cells are excluded.",
  "One record retained per 5-arcminute climate cell for diagnostics only.",
  "Review observation types, spatial bias, taxonomic scope, duplicates,",
  "coordinate-cleaning, sampling protocol comparability and licenses.",
  "The original order-level effort surface might include the focal species.",
  "No Venezuelan field events loaded. No model fit or tuned.",
  paste("terra version:", as.character(utils::packageVersion("terra"))),
  paste("data.table version:",
        as.character(utils::packageVersion("data.table")))
), file.path(outdir, "30_target_group_archive_provenance.txt"))

cat("\n[R21] SOURCE ZIP:", basename(zip_path), "\n")
cat("[R21] DOI from GBIF metadata (may be NA):", doi, "\n")
cat("[R21] Downloaded archive rows:", n_original, "\n")
cat("[R21] Sequential first-pass screen:\n")
print(progress, row.names = FALSE)
cat("\n[R21] Provisional non-focal 5-arcminute cells by original fold:\n")
print(by_fold, row.names = FALSE)
cat("\n[R21] Complete local outputs:\n",
    normalizePath(outdir, winslash = "/"), "\n")
cat("[R21] Candidate cell list is NOT a selected background or a final M.\n")
cat("[R21] No modelling or Venezuelan field data accessed.\n")
