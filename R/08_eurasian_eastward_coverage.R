# Phalangium opilio | Eurasian occurrence coverage beyond 60 degrees E
# RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/08_eurasian_eastward_coverage.R")
#
# Descriptive audit only. Longitude bands are NOT native-range boundaries or M.
# No Venezuelan field observations or climate-model predictions are used.

file <- file.path(getwd(), "01_datos", "coordinatecleaner",
                  "02_all_candidates_with_CC_flags.csv")
if (!file.exists(file)) {
  message("Select 02_all_candidates_with_CC_flags.csv")
  file <- file.choose()
}
if (basename(file) != "02_all_candidates_with_CC_flags.csv") {
  stop("Select the complete corrected CoordinateCleaner candidate file.")
}
out <- dirname(file)
x <- utils::read.csv(file, stringsAsFactors = FALSE,
                     check.names = FALSE, na.strings = c("", "NA"))
required <- c("gbifID", "countryCode", "basisOfRecord", "decimalLongitude",
              "decimalLatitude", ".summary", ".uncertainty_unreported")
missing <- setdiff(required, names(x))
if (length(missing)) stop("Missing fields: ", paste(missing, collapse = ", "))

x$.summary <- as.logical(x$.summary)
x$.uncertainty_unreported <- as.logical(x$.uncertainty_unreported)
if (nrow(x) != 56524L || anyNA(x$.summary) ||
    sum(x$.summary) != 50403L ||
    sum(x$.uncertainty_unreported) != 12898L) {
  stop("Unexpected candidate totals. Run the provenance restoration first.")
}
lon <- suppressWarnings(as.numeric(x$decimalLongitude))
lat <- suppressWarnings(as.numeric(x$decimalLatitude))
if (any(!is.finite(lon) | !is.finite(lat))) {
  stop("Coordinates missing in the corrected candidate file.")
}
country <- as.character(x$countryCode)
country[is.na(country) | !nzchar(country)] <- "UNSPECIFIED"
status <- x$.summary
cell <- paste(floor((lon + 180) * 12), floor((90 - lat) * 12), sep = "_")
position <- paste(lon, lat, sep = "|")

# A strictly DESCRIPTIVE transect through temperate Eurasia;
# both latitude and longitude cutoffs are exploratory, NOT biologically
# established accessible-area limits.
regions <- list(
  Europe_to_60E = lon >= -12 & lon < 60 & lat >= 30 & lat <= 72,
  East_60_to_90E = lon >= 60 & lon < 90 & lat >= 30 & lat <= 72,
  East_90_to_120E = lon >= 90 & lon < 120 & lat >= 30 & lat <= 72,
  East_120_to_160E = lon >= 120 & lon < 160 & lat >= 30 & lat <= 72,
  East_160_to_180E = lon >= 160 & lon <= 180 & lat >= 30 & lat <= 72,
  Broad_Eurasia_12W_180E = lon >= -12 & lon <= 180 &
                           lat >= 30 & lat <= 72
)
sum_regions <- do.call(rbind, lapply(names(regions), function(label) {
  idx <- which(regions[[label]])
  clean <- idx[status[idx]]
  data.frame(
    region = label,
    n_candidates = length(idx),
    n_without_CC_flags = length(clean),
    n_unique_positions = length(unique(position[clean])),
    n_unique_5min_cells = length(unique(cell[clean])),
    n_missing_uncertainty = sum(x$.uncertainty_unreported[idx]),
    n_countries = length(unique(country[clean])),
    stringsAsFactors = FALSE
  )
}))
rownames(sum_regions) <- NULL

east <- lon >= 60 & lon <= 180 & lat >= 30 & lat <= 72
groups <- split(which(east), country[east])
by_country <- do.call(rbind, lapply(names(groups), function(k) {
  idx <- groups[[k]]
  clean <- idx[status[idx]]
  data.frame(
    countryCode = k,
    n_candidates = length(idx),
    n_without_CC_flags = length(clean),
    n_unique_5min_cells = length(unique(cell[clean])),
    westernmost_clean_longitude = if (length(clean)) min(lon[clean]) else NA,
    easternmost_clean_longitude = if (length(clean)) max(lon[clean]) else NA,
    min_clean_latitude = if (length(clean)) min(lat[clean]) else NA,
    max_clean_latitude = if (length(clean)) max(lat[clean]) else NA,
    stringsAsFactors = FALSE
  )
}))
by_country <- by_country[order(-by_country$n_without_CC_flags,
                               by_country$countryCode), , drop = FALSE]
rownames(by_country) <- NULL

utils::write.csv(sum_regions,
                 file.path(out, "31_eurasian_longitude_coverage.csv"),
                 row.names = FALSE)
utils::write.csv(by_country,
                 file.path(out, "32_eastern_eurasia_by_country.csv"),
                 row.names = FALSE)

fig <- file.path(out, "33_eurasian_coverage_diagnostic.png")
grDevices::png(fig, width = 1600, height = 930, res = 170)
graphics::par(mar = c(4.3, 4.5, 3.5, 1))
n <- status & lon >= -12 & lon <= 180 & lat >= 30 & lat <= 72
graphics::plot(lon[n], lat[n], pch = 16, cex = 0.25,
               col = grDevices::adjustcolor("steelblue4", alpha.f = .30),
               xlim = c(-15, 182), ylim = c(28, 75),
               xlab = "Longitude (degrees east)",
               ylab = "Latitude (degrees north)",
               main = "Phalangium opilio: Eurasian occurrence coverage (GBIF)")
graphics::abline(v = c(60, 90, 120, 160), lty = 2, col = "grey45")
graphics::mtext("Exploratory longitude bands; not a calibrated accessible area",
                side = 3, line = 0.2, cex = 0.65)
grDevices::dev.off()

cat("\nPHALANGIUM OPILIO | EURASIAN COVERAGE DIAGNOSTICS\n")
print(sum_regions, row.names = FALSE)
cat("\nCountries with screened occurrences east of 60 E (top 20):\n")
print(utils::head(by_country, 20), row.names = FALSE)
cat("\nOutput directory: ",
    normalizePath(out, winslash = "/", mustWork = TRUE), "\n")
cat("This is an audit of GBIF records, not a delineation of native range or M.\n")
cat("Venezuelan field localities were not read.\n")
