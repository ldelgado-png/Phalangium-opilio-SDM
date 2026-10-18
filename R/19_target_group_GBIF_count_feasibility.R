# Phalangium opilio | Independent target-group availability preflight
#
# Run from the project root in RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/19_target_group_GBIF_count_feasibility.R")
#
# Revision v3 replaces the occ_count() wrapper with an equivalent
# zero-record occ_search(limit=0) metadata query to avoid the repeated
# client-side multi-value validation exception.
# This preflight retrieves only LIVE GBIF occurrence COUNTS (not records)
# for Opiliones and Phalangium opilio using matching search filters.
# It does not produce a target-group background or define an accessible M.
# It does not read, tune to, or assess Venezuelan field occurrences.
#
# GBIF recommends its citable asynchronous download API, not paged
# occurrence searches, for subsequent research-grade target-group data.
# https://docs.ropensci.org/rgbif/articles/getting_occurrence_data.html

message("[R19 v3] GBIF target-group count feasibility using occ_search(limit=0)")
for (pkg in c("rgbif", "ENMeval")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Install missing package: install.packages('", pkg, "')")
  }
}
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
pilot <- file.path(root, "04_resultados_modelo",
                   "pilot_western_palaearctic")
eval_file <- file.path(pilot, "07_ENMeval_pilot_evaluation.rds")
if (!file.exists(eval_file)) {
  stop("Cannot find archived pilot evaluation at: ", eval_file)
}
outdir <- file.path(root, "01_datos", "sampling_effort")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# The four partitions are retrieved from the SAVED ENMeval model,
# not inferred from the Venezuelan sites or redefined for the preflight.
evaluation <- readRDS(eval_file)
if (!methods::is(evaluation, "ENMevaluation")) {
  stop("Unexpected archived ENMeval evaluation object.")
}
occ <- as.data.frame(ENMeval::eval.occs(evaluation))
group <- as.character(ENMeval::eval.occs.grp(evaluation))
if (nrow(occ) != 10426L || length(group) != 10426L) {
  stop("Archived pilot has unexpected occurrence/fold counts.")
}
latitude <- as.numeric(occ[[2]])
if (any(!is.finite(latitude))) stop("Invalid calibration latitude.")
fold_ids <- sort(unique(group))
if (length(fold_ids) != 4L) stop("Expected four pilot spatial folds.")
fold_bounds <- do.call(rbind, lapply(fold_ids, function(g) {
  y <- latitude[group == g]
  data.frame(fold = g, minlat = min(y), maxlat = max(y),
             median = stats::median(y), stringsAsFactors = FALSE)
}))
fold_bounds <- fold_bounds[order(fold_bounds$median), ,
                          drop = FALSE]
cutoffs <- vapply(1:3, function(i) {
  (fold_bounds$maxlat[i] + fold_bounds$minlat[i + 1L]) / 2
}, numeric(1))
if (any(diff(c(30, cutoffs, 72)) <= 0)) {
  stop("Invalid latitude boundaries in the saved pilot.")
}
check_fold <- fold_bounds$fold[findInterval(
  latitude, c(-Inf, cutoffs, Inf),
  rightmost.closed = TRUE
)]
if (!identical(check_fold, group)) {
  stop("Reconstructed blocks disagree with the saved pilot fold IDs.")
}

# Taxonomic keys are verified dynamically against the GBIF backbone.
taxon_key <- function(name, required_rank) {
  res <- rgbif::name_backbone(name = name)
  key <- res$usageKey
  rank <- as.character(res$rank)
  if (length(key) != 1L || is.na(key) ||
      length(rank) != 1L || is.na(rank) ||
      toupper(rank) != required_rank ||
      identical(as.character(res$matchType), "NONE")) {
    stop("Unexpected GBIF taxonomy match for ", name,
         ". Inspect rgbif::name_backbone() manually.")
  }
  as.character(key)
}
order_key <- taxon_key("Opiliones", "ORDER")
focal_key <- taxon_key("Phalangium opilio", "SPECIES")
cat("\nGBIF TAXONOMY (live backbone)\n")
cat("Opiliones taxonKey:", order_key, "\n")
cat("Phalangium opilio taxonKey:", focal_key, "\n")

# Spatial and temporal filters apply equally to both GBIF counts.
# Geometry is a bounding box in longitude, latitude order.
# The rectangle is the HISTORICAL PILOT GEOGRAPHIC WINDOW, not M.
west <- -12
east <- 60
bands <- data.frame(
  domain = c("pilot_rectangle",
             paste0("pilot_fold_", fold_bounds$fold)),
  fold = c("all", as.character(fold_bounds$fold)),
  minlat = c(30, 30, cutoffs),
  maxlat = c(72, cutoffs, 72),
  stringsAsFactors = FALSE
)
# occ_count() (rgbif >= 3.7.6) requires ONE WKT geometry string:
# a numeric c(west, south, east, north) is interpreted as multiple filters
# and triggers the error "Multiple values ... are not supported".
# Vertices must be longitude-latitude pairs in counter-clockwise order.
bbox_as_wkt <- function(bounds) {
  b <- as.numeric(bounds)
  if (length(b) != 4L || any(!is.finite(b)) ||
      b[1] >= b[3] || b[2] >= b[4] ||
      b[1] < -180 || b[3] > 180 ||
      b[2] < -90 || b[4] > 90) {
    stop("Invalid west, south, east, north bounding box.")
  }
  sprintf(
    paste0("POLYGON((", 
           "%.9f %.9f,%.9f %.9f,%.9f %.9f,",
           "%.9f %.9f,%.9f %.9f))"),
    b[1], b[2], b[3], b[2], b[3], b[4],
    b[1], b[4], b[1], b[2]
  )
}
get_gbif_count <- function(key, bounds) {
  # Get only occurrence-count metadata; no records are downloaded.
  # The occ_count() wrapper rejects multi-valued arguments before sending
  # a request, and an identical runtime error persisted on this workflow
  # despite passing only one WKT string. Calling the documented equivalent
  # occ_search(limit = 0)$meta$count avoids that wrapper-level check.
  query <- list(
    taxonKey = as.character(key),
    hasCoordinate = TRUE,
    occurrenceStatus = "PRESENT",
    year = "1980,2025",
    geometry = bbox_as_wkt(bounds),
    limit = 0L
  )
  lengths <- vapply(query, length, integer(1))
  if (any(lengths != 1L)) {
    stop("GBIF count query must have scalar arguments: ",
         paste(names(lengths), lengths, collapse = "; "))
  }
  count <- do.call(rgbif::occ_search, query)$meta$count
  if (length(count) != 1L || !is.finite(count) ||
      count < 0 || count != floor(count)) {
    stop("Unexpected live GBIF count for taxon key ", key)
  }
  as.numeric(count)
}
out <- vector("list", nrow(bands))
for (i in seq_len(nrow(bands))) {
  region <- bands[i, ]
  box <- c(west, region$minlat, east, region$maxlat)
  message("GBIF preflight ", i, "/", nrow(bands),
          ": ", region$domain, " (1980-2025)...")
  # Two count requests with identical filters, never search-page sampling.
  order_n <- get_gbif_count(order_key, box)
  Sys.sleep(0.5)
  focal_n <- get_gbif_count(focal_key, box)
  Sys.sleep(0.5)
  if (focal_n > order_n) {
    stop("Focal count exceeds order count: check taxon-key hierarchy.")
  }
  out[[i]] <- data.frame(
    domain = region$domain,
    fold = region$fold,
    west = west, east = east,
    south = region$minlat, north = region$maxlat,
    order_taxon_key = order_key,
    focal_taxon_key = focal_key,
    years = "1980-2025",
    order_count = order_n,
    focal_count = focal_n,
    difference_order_minus_focal = order_n - focal_n,
    focal_percentage_of_order = if (order_n > 0)
      round(100 * focal_n / order_n, 3) else NA_real_,
    stringsAsFactors = FALSE
  )
}
counts <- do.call(rbind, out)
rownames(counts) <- NULL
counts_file <- file.path(
  outdir, "23_gbif_target_group_count_feasibility.csv"
)
utils::write.csv(counts, counts_file, row.names = FALSE)
writeLines(c(
  "GBIF target-group feasibility: live count preflight only.",
  paste("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("rgbif version:", as.character(utils::packageVersion("rgbif"))),
  paste("Order key:", order_key),
  paste("Focal key:", focal_key),
  "Search filter: coordinates TRUE; occurrenceStatus PRESENT; event years 1980-2025.",
  "Geography: rectangle lon -12 to 60, lat 30 to 72; four saved pilot bands.",
  "GBIF geometry serialized as one counter-clockwise WKT POLYGON per domain.",
  "Count method: rgbif::occ_search(limit=0)$meta$count; no records downloaded.",
  "This rectangle is NOT the species' accessible calibration region M.",
  "Counts are live GBIF records, not counts in the 2026 GBIF DOI snapshot.",
  "Counts do not equal independent sampling visits, species richness,",
  "non-focal independent sites, or suitable target-group climatic cells.",
  "Difference order minus focal is a preliminary count difference only.",
  "The order includes other Opiliones with heterogeneous reporting histories.",
  "This preflight excludes neither spatial nor taxonomic quality flags.",
  "A research-grade target-group background requires a separately citable",
  "GBIF download, quality control, species exclusion and climate-grid thinning.",
  "No presence or background points are downloaded by this script.",
  "No model was fitted or selected; Venezuelan field data were not read."
), file.path(outdir,
             "23_gbif_target_group_preflight_provenance.txt"))
cat("\nGBIF OPILIONES TARGET-GROUP AVAILABILITY — COUNTS ONLY\n")
print(counts, row.names = FALSE)
cat("\nSaved:", normalizePath(counts_file, winslash = "/"), "\n")
cat("No sampled target-group background, final M or fitted model.\n")
