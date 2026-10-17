# Phalangium opilio: country-level spatial-quality audit
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/04_geographic_quality_audit.R")
# Requires corrected CoordinateCleaner output from the preceding scripts.

input <- file.path(getwd(), "01_datos", "coordinatecleaner",
                   "02_all_candidates_with_CC_flags.csv")
if (!file.exists(input)) {
  message("Select 02_all_candidates_with_CC_flags.csv")
  input <- file.choose()
}
if (basename(input) != "02_all_candidates_with_CC_flags.csv")
  stop("Incorrect file selected.")
d <- dirname(input)
x <- read.csv(input, check.names = FALSE, stringsAsFactors = FALSE)
tests <- c(".val", ".equ", ".zer", ".cap", ".cen", ".sea", ".gbf", ".inst")
req <- c("gbifID", "countryCode", "decimalLongitude", "decimalLatitude",
         "coordinateUncertaintyInMeters", ".summary",
         ".uncertainty_unreported", tests)
if (length(setdiff(req, names(x))))
  stop("Missing columns: ", paste(setdiff(req, names(x)), collapse = ", "))
for (j in c(tests, ".summary", ".uncertainty_unreported"))
  x[[j]] <- as.logical(x[[j]])
if (anyNA(x$.summary)) stop("Invalid CC summary.")
if (nrow(x) != 56524L || sum(x$.summary) != 50403L ||
    sum(x$.uncertainty_unreported) != 12898L)
  stop("Please run 03_restore_GBIF_record_provenance.R first.")

cc <- as.data.frame(lapply(x[tests], function(y) is.na(y) | !y))
stopifnot(all((rowSums(cc) == 0L) == x$.summary))
country <- ifelse(is.na(x$countryCode) | x$countryCode == "",
                  "UNSPECIFIED", as.character(x$countryCode))
cell <- paste(floor((90 - as.numeric(x$decimalLatitude)) * 12),
              floor((as.numeric(x$decimalLongitude) + 180) * 12),
              sep = "_")
by_country <- lapply(split(seq_len(nrow(x)), country), function(ii) {
  jj <- ii[x$.summary[ii]]
  data.frame(countryCode = country[ii[1]], candidates = length(ii),
             pass_CC = length(jj), flagged_CC = sum(!x$.summary[ii]),
             pct_flagged = round(100 * mean(!x$.summary[ii]), 1),
             cells_pass_CC = length(unique(cell[jj])),
             missing_uncertainty = sum(x$.uncertainty_unreported[ii]),
             sea = sum(cc$.sea[ii]), capitals = sum(cc$.cap[ii]),
             centroids = sum(cc$.cen[ii]),
             institutions = sum(cc$.inst[ii]))
})
countries <- do.call(rbind, by_country)
countries <- countries[order(-countries$candidates), , drop = FALSE]
rownames(countries) <- NULL

patterns <- apply(cc, 1, function(row) {
  if (!any(row)) "none" else paste(names(cc)[row], collapse = "+")
})
combinations <- as.data.frame(table(patterns), stringsAsFactors = FALSE)
combinations <- combinations[order(-combinations$Freq), , drop = FALSE]
names(combinations) <- c("cc_flags", "n")

sea <- x[cc$.sea, , drop = FALSE]
unc <- suppressWarnings(as.numeric(sea$coordinateUncertaintyInMeters))
sea$review_priority <- ifelse(is.na(unc), "uncertainty_missing",
                              ifelse(unc <= 100, "at_most_100m", "above_100m"))
other <- setdiff(tests, c(".cap", ".inst"))
urban_only <- !x$.summary & rowSums(cc[other]) == 0
sensitivity <- data.frame(
  scenario = c("no_CC_flags", "urban_only_flags_added_for_review"),
  records = c(sum(x$.summary), sum(x$.summary | urban_only)),
  unique_cells = c(length(unique(cell[x$.summary])),
                   length(unique(cell[x$.summary | urban_only])))
)
write.csv(countries, file.path(d, "10_quality_by_country.csv"), row.names = FALSE)
write.csv(combinations, file.path(d, "11_flag_combinations.csv"), row.names = FALSE)
write.csv(sea, file.path(d, "12_sea_records_for_review.csv"), row.names = FALSE)
write.csv(sensitivity, file.path(d, "13_urban_flag_sensitivity.csv"), row.names = FALSE)

cat("\n15 countries with most GBIF candidate records:\n")
print(head(countries, 15), row.names = FALSE)
cat("\n15 countries with most sea alerts:\n")
print(head(countries[order(-countries$sea), ], 15), row.names = FALSE)
cat("\nExploratory urban-alert sensitivity (NOT final selection):\n")
print(sensitivity, row.names = FALSE)
cat("\nSea alerts with reported uncertainty <=100 m:",
    sum(cc$.sea & !is.na(suppressWarnings(as.numeric(x$coordinateUncertaintyInMeters))) &
        suppressWarnings(as.numeric(x$coordinateUncertaintyInMeters)) <= 100), "\n")
cat("\nAudit tables stored at:", normalizePath(d, winslash = "/"), "\n")
