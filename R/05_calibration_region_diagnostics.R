# Phalangium opilio | Candidate calibration-region diagnostics
#
# Run in RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/05_calibration_region_diagnostics.R")
#
# These geographic windows are EXPLORATORY only. They do not delineate
# a biogeographically inferred accessible area (M), and do not imply that
# all occurrences inside a window represent populations of native origin.

input <- file.path(getwd(), "01_datos", "coordinatecleaner",
                   "02_all_candidates_with_CC_flags.csv")
if (!file.exists(input)) {
  message("Select 02_all_candidates_with_CC_flags.csv.")
  input <- file.choose()
}
if (basename(input) != "02_all_candidates_with_CC_flags.csv") {
  stop("Select the full corrected candidate file, not a subset.")
}
out <- dirname(input)
x <- utils::read.csv(input, stringsAsFactors = FALSE, check.names = FALSE)
tests <- c(".val", ".equ", ".zer", ".cap", ".cen",
           ".sea", ".gbf", ".inst")
required <- c("gbifID", "countryCode", "decimalLongitude",
              "decimalLatitude", ".summary", ".source_row",
              ".uncertainty_unreported", tests)
missing <- setdiff(required, names(x))
if (length(missing)) stop("Missing columns: ", paste(missing, collapse = ", "))

for (nm in c(tests, ".summary", ".uncertainty_unreported")) {
  x[[nm]] <- as.logical(x[[nm]])
}
if (nrow(x) != 56524L ||
    anyNA(x$.summary) ||
    sum(x$.summary) != 50403L ||
    sum(x$.uncertainty_unreported) != 12898L) {
  stop("The corrected provenance audit is required. Run the previous R script.")
}

test_bad <- as.data.frame(lapply(x[tests], function(v) is.na(v) | !v))
if (!all((rowSums(test_bad) == 0L) == x$.summary)) {
  stop("The per-test flags conflict with CoordinateCleaner .summary.")
}

lon <- suppressWarnings(as.numeric(x$decimalLongitude))
lat <- suppressWarnings(as.numeric(x$decimalLatitude))
if (any(!is.finite(lon) | !is.finite(lat))) {
  stop("Non-finite longitude or latitude in candidate file.")
}

strict <- x$.summary
nonurban <- setdiff(tests, c(".cap", ".inst"))
urban_only <- !strict & rowSums(test_bad[, nonurban, drop = FALSE]) == 0L
review_urban <- strict | urban_only

# The 5-arcminute geometry is an exploratory global grid aligned to
# longitude -180 and latitude +90. Actual WorldClim raster-cell thinning
# will be repeated with terra::cellFromXY once climatic rasters are loaded.
cell5 <- paste(
  floor((90 - lat) * 12),
  floor((lon + 180) * 12),
  sep = "_"
)
cells <- function(idx) length(unique(cell5[idx]))
positions <- function(idx) {
  length(unique(paste(lon[idx], lat[idx], sep = "|")))
}

regions <- list(
  worldwide_diagnostic = rep(TRUE, nrow(x)),
  temperate_europe_window = lon >= -12 & lon <= 35 &
                            lat >= 35 & lat <= 72,
  western_palaearctic_window = lon >= -12 & lon <= 60 &
                              lat >= 30 & lat <= 72,
  north_america_comparison = lon >= -170 & lon <= -50 &
                             lat >= 15 & lat <= 75
)
rows <- lapply(names(regions), function(nm) {
  area <- regions[[nm]]
  s <- area & strict
  u <- area & review_urban
  data.frame(
    geographic_window = nm,
    longitude_min = if (nm == "worldwide_diagnostic") -180 else
      if (nm == "temperate_europe_window") -12 else
        if (nm == "western_palaearctic_window") -12 else -170,
    longitude_max = if (nm == "worldwide_diagnostic") 180 else
      if (nm == "temperate_europe_window") 35 else
        if (nm == "western_palaearctic_window") 60 else -50,
    latitude_min = if (nm == "worldwide_diagnostic") -90 else
      if (nm == "temperate_europe_window") 35 else
        if (nm == "western_palaearctic_window") 30 else 15,
    latitude_max = if (nm == "worldwide_diagnostic") 90 else
      if (nm == "temperate_europe_window") 72 else
        if (nm == "western_palaearctic_window") 72 else 75,
    records_in_window = sum(area),
    records_without_CC_flags = sum(s),
    records_urban_review = sum(u),
    extra_urban_review = sum(u) - sum(s),
    cells_strict_5min = cells(s),
    cells_urban_review_5min = cells(u),
    extra_cells_urban_review = cells(u) - cells(s),
    distinct_positions_strict = positions(s),
    stringsAsFactors = FALSE
  )
})
tab <- do.call(rbind, rows)
rownames(tab) <- NULL
utils::write.csv(tab, file.path(out, "15_calibration_window_diagnostics.csv"),
                 row.names = FALSE, na = "")

# Optional visual check. This is an occurrence plot, NOT climatic suitability.
figure <- file.path(out, "16_calibration_window_occurrences.png")
grDevices::png(figure, width = 1900, height = 1100, res = 180)
graphics::par(mar = c(4.4, 4.4, 3, 1))
graphics::plot(
  lon[strict], lat[strict], xlim = c(-20, 75), ylim = c(23, 76),
  pch = 16, cex = 0.17,
  col = grDevices::adjustcolor("#455467", alpha.f = 0.16),
  xlab = "Longitude (degrees east)",
  ylab = "Latitude (degrees north)",
  main = "Phalangium opilio | Western Eurasian occurrence coverage"
)
graphics::rect(-12, 35, 35, 72, border = "#247a74", lwd = 2.3)
graphics::rect(-12, 30, 60, 72, border = "#c58829", lwd = 2.3, lty = 2)
graphics::points(
  lon[urban_only], lat[urban_only],
  pch = 16, cex = 0.22,
  col = grDevices::adjustcolor("#a65550", alpha.f = 0.30)
)
graphics::legend(
  "bottomleft",
  legend = c("No CoordinateCleaner flags",
             "Urban-only flags under review",
             "Temperate European window",
             "Western Palaearctic window"),
  col = c("#455467", "#a65550", "#247a74", "#c58829"),
  pch = c(16, 16, NA, NA),
  lty = c(NA, NA, 1, 2),
  lwd = c(NA, NA, 2, 2),
  cex = 0.62, bty = "n"
)
grDevices::dev.off()

# Scientific decisions about M require more than these rectangles.
cat("\nPHALANGIUM OPILIO | CANDIDATE CALIBRATION WINDOWS\n")
print(tab, row.names = FALSE)
cat("\nThese are exploratory geographic windows, NOT finalized M regions.\n")
cat("No climate layers were fitted and no habitat suitability was predicted.\n")
cat("Country boundaries and political records are not assumed to define M.\n")
cat("Descriptive outputs:\n", normalizePath(out, winslash = "/"), "\n")
