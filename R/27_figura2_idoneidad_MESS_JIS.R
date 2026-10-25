# Phalangium opilio | Suitability/MESS figure accompanying the Biotropica submission
# Historical filenames and export identifiers are retained for compatibility.
# R27 | 19 October 2026
# Two panels: (A) original LQ/RM2 climatic suitability, (B) MESS sign.
# A small inset shows THREE independent WorldClim grid cells in Venezuela.
# Uses archived R11/R25 GeoTIFFs and the R26-v3 site extraction CSV.
# Does NOT refit models, choose new thresholds, resample or reproject rasters.
# Reference: western Palaearctic operational RECTANGLE, NOT a validated M.
# Run in RStudio with working directory = Phalangium_opilio_SDM project root.
# source("R/27_figura2_idoneidad_MESS_JIS.R")

needed <- c("terra", "ggplot2", "sf", "rnaturalearth",
            "rnaturalearthdata", "patchwork", "scales")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install missing packages and rerun: install.packages(c(",
       paste(sprintf('"%s"', missing), collapse = ", "), "))")
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
pilot <- file.path(root, "04_resultados_modelo", "pilot_western_palaearctic")
novelty <- file.path(pilot, "transfer_novelty_EXPLORATORY_NOT_FINAL")
site_dir <- file.path(pilot, "26_venezuela_transfer_DIAGNOSTIC_NOT_FINAL")

suit_file <- file.path(pilot,
  "09_pilot_south_america_LQ_rm2_cloglog_NOT_FINAL.tif")
mess_file <- file.path(novelty, "27_sa_MESS_5m_EXPLORATORY.tif")
site_file <- getOption("phalangium.venezuela_extraction_csv",
                      file.path(site_dir, "26_venezuela_site_transfer_values.csv"))
inputs <- c(suit_file, mess_file, site_file)
if (!all(file.exists(inputs))) {
  stop("Required file(s) missing. Supply the private R26 field extraction; see docs/REVIEWER_GUIDE.md.\n",
       paste(inputs[!file.exists(inputs)], collapse = "\n"))
}

out <- file.path(pilot, "publication_style_figures", "Figure2_JIS_MESS")
dir.create(out, showWarnings = FALSE, recursive = TRUE)

# Read original rasters, without modifying their cells or geometry.
suit <- terra::rast(suit_file)
mess_stack <- terra::rast(mess_file)
if (terra::nlyr(suit) != 1L || terra::nlyr(mess_stack) != 5L) {
  stop("Expected single-layer maxnet suitability and 5-layer R25 MESS.")
}
mess <- mess_stack[[5]]  # overall MESS is the 5th R25 layer
if (!isTRUE(terra::is.lonlat(suit)) ||
    !isTRUE(terra::is.lonlat(mess)) ||
    !isTRUE(terra::same.crs(suit, mess))) {
  stop("Rasters require a common longitude/latitude CRS; do not resample.")
}
names(suit) <- "suitability"
names(mess) <- "MESS"
suit_range <- terra::global(suit, fun = "range", na.rm = TRUE)
if (min(as.matrix(suit_range)) < -0.001 ||
    max(as.matrix(suit_range)) > 1.001) {
  stop("Suitability raster does not appear to be cloglog [0,1].")
}

# Read withheld Venezuelan observations only to plot their three *grid cells*.
# No row is used to re-fit, evaluate, select, clamp or alter either raster.
sites <- utils::read.csv(site_file, stringsAsFactors = FALSE,
                         check.names = FALSE)
required_cols <- c("site_id", "longitude", "latitude",
                   "suitability_cloglog", "MESS")
if (!all(required_cols %in% names(sites))) {
  stop("Unexpected R26 CSV. Missing: ",
       paste(setdiff(required_cols, names(sites)), collapse = ", "))
}
xy <- as.matrix(sites[, c("longitude", "latitude")])
if (!nrow(sites) || any(!is.finite(xy))) {
  stop("Invalid Venezuelan site coordinates in R26 output.")
}
if (nrow(sites) != 7L) {
  warning("Expected seven original site records, got ", nrow(sites), ".")
}

# The primary grid for deduplicating observation cells is the same 5' grid
# underlying the maxnet South American climatic suitability raster.
site_cells <- terra::cellFromXY(suit, xy)
if (anyNA(site_cells)) {
  stop("One or more Venezuelan observations are outside the suitability raster.")
}
unique_cells <- unique(site_cells)  # first-seen R26 occurrence order
centres <- terra::xyFromCell(suit, unique_cells)
pts <- data.frame(
  cell = unique_cells,
  longitude = centres[, 1], latitude = centres[, 2],
  label = as.character(seq_along(unique_cells)),
  n_records = tabulate(match(site_cells, unique_cells),
                       nbins = length(unique_cells)),
  stringsAsFactors = FALSE
)
if (nrow(pts) != 3L) {
  stop("Expected three distinct Venezuelan 5' climatic cells, got ",
       nrow(pts), ". Check R26 and coordinate-cell alignment.")
}
cell_localities <- vapply(unique_cells, function(cell) {
  a <- sites$site_id[site_cells == cell]
  a <- unique(sub("\\.[0-9]+$", "", a))
  paste(a, collapse = "; ")
}, character(1))
pts$localities <- cell_localities

# Confirm the R26 values are negative at all Venezuelan records.
if (any(!is.finite(sites$MESS)) || any(sites$MESS >= 0)) {
  warning("Not all R26 site MESS values are negative. Inspect original CSV.")
}

# One continental indicator, not seven overlapping independent symbols.
focus <- data.frame(
  longitude = mean(pts$longitude), latitude = mean(pts$latitude)
)

# The full MESS field is shown by its *sign* to make the 0 boundary obvious.
# MESS >= 0 means no UNIVARIATE range violation (not full multivariate analogy).
dat_a <- terra::as.data.frame(suit, xy = TRUE, na.rm = TRUE)
dat_b <- terra::as.data.frame(mess, xy = TRUE, na.rm = TRUE)
levels_novelty <- c(
  "MESS < 0: outside sampled range",
  "MESS >= 0: within univariate ranges"
)
dat_b$novelty <- factor(
  ifelse(dat_b$MESS < 0, levels_novelty[1], levels_novelty[2]),
  levels = levels_novelty
)

# Borders provide context only; neither raster is resampled/masked/reprojected.
borders <- rnaturalearth::ne_countries(
  scale = 110, continent = "South America", returnclass = "sf")
if (!nrow(borders)) stop("Could not obtain Natural Earth land borders.")
borders <- sf::st_transform(borders, 4326)

map_theme <- ggplot2::theme_minimal(base_family = "serif", base_size = 10) +
  ggplot2::theme(
    panel.grid.major = ggplot2::element_line(colour = "grey87", linewidth = 0.15),
    panel.grid.minor = ggplot2::element_blank(),
    panel.border = ggplot2::element_rect(fill = NA, colour = "grey40", linewidth = 0.4),
    plot.title = ggplot2::element_text(face = "bold", size = 12,
                                      margin = ggplot2::margin(b = 9)),
    axis.title = ggplot2::element_text(size = 9),
    axis.text = ggplot2::element_text(size = 8, colour = "grey20"),
    legend.position = "bottom",
    legend.title = ggplot2::element_text(size = 9, face = "bold"),
    legend.text = ggplot2::element_text(size = 8),
    plot.margin = ggplot2::margin(9, 6, 9, 6)
  )

map_coords <- function() {
  list(
    ggplot2::scale_x_continuous(breaks = seq(-80, -40, 10),
                               labels = function(x) paste0(abs(x), "°W")),
    ggplot2::scale_y_continuous(breaks = seq(-50, 10, 10),
      labels = function(y) ifelse(y < 0, paste0(abs(y), "°S"),
                                  ifelse(y > 0, paste0(y, "°N"), "0°"))),
    ggplot2::coord_sf(crs = sf::st_crs(4326),
                      xlim = c(-82, -34), ylim = c(-56, 13),
                      expand = FALSE, datum = sf::st_crs(4326))
  )
}

# Original R17 colour palette retained: same raster and scale 0-1.
panel_a <- ggplot2::ggplot() +
  ggplot2::geom_raster(data = dat_a,
    ggplot2::aes(x = x, y = y, fill = suitability), interpolate = FALSE) +
  ggplot2::geom_sf(data = borders, fill = NA,
                   colour = "grey25", linewidth = 0.23) +
  ggplot2::geom_point(data = focus,
    ggplot2::aes(x = longitude, y = latitude),
    inherit.aes = FALSE, shape = 21, size = 2.7,
    fill = "white", colour = "black", stroke = 0.7) +
  ggplot2::scale_fill_gradientn(
    colours = c("#650020", "#990020", "#C81A0B", "#E74100",
                "#FB8600", "#FFC536", "#FFF9C4"),
    values = c(0, .15, .30, .45, .62, .80, 1),
    limits = c(0, 1), breaks = c(0, .25, .5, .75, 1),
    name = "Climatic suitability (cloglog)",
    guide = ggplot2::guide_colourbar(
      title.position = "top", barwidth = grid::unit(7.5, "cm"),
      barheight = grid::unit(.35, "cm"))) +
  map_coords() +
  ggplot2::labs(title = "A   Predicted climatic suitability",
                x = "Longitude", y = "Latitude") +
  map_theme

panel_b <- ggplot2::ggplot() +
  ggplot2::geom_raster(data = dat_b,
    ggplot2::aes(x = x, y = y, fill = novelty), interpolate = FALSE) +
  ggplot2::geom_sf(data = borders, fill = NA,
                   colour = "grey25", linewidth = 0.23) +
  ggplot2::geom_point(data = focus,
    ggplot2::aes(x = longitude, y = latitude),
    inherit.aes = FALSE, shape = 21, size = 2.7,
    fill = "white", colour = "black", stroke = 0.7) +
  ggplot2::scale_fill_manual(
    name = "Environmental novelty (MESS sign)",
    values = setNames(c("#BA5359", "#79A69D"), levels_novelty),
    drop = FALSE,
    guide = ggplot2::guide_legend(
      title.position = "top", nrow = 2,
      override.aes = list(colour = NA))) +
  map_coords() +
  ggplot2::labs(title = "B   Environmental novelty",
                x = "Longitude", y = "Latitude") +
  map_theme

# Mérida inset with the source raster grid's REAL 5' cell footprint.
# It depicts cell centres (not seven visually duplicated occurrence points).
resolution <- terra::res(suit)
pts$xmin <- pts$longitude - resolution[1] / 2
pts$xmax <- pts$longitude + resolution[1] / 2
pts$ymin <- pts$latitude - resolution[2] / 2
pts$ymax <- pts$latitude + resolution[2] / 2
zoom_xlim <- range(pts$xmin, pts$xmax) + c(-.08, .08)
zoom_ylim <- range(pts$ymin, pts$ymax) + c(-.08, .08)

zoom <- ggplot2::ggplot() +
  ggplot2::geom_rect(data = pts,
    ggplot2::aes(xmin = xmin, xmax = xmax,
                 ymin = ymin, ymax = ymax),
    fill = "#E7EAF0", colour = "grey40", linewidth = 0.5) +
  ggplot2::geom_point(data = pts,
    ggplot2::aes(x = longitude, y = latitude),
    shape = 21, size = 5.0, stroke = 0.6,
    fill = "#222222", colour = "white") +
  ggplot2::geom_text(data = pts,
    ggplot2::aes(x = longitude, y = latitude, label = label),
    family = "serif", colour = "white", fontface = "bold", size = 3.3) +
  ggplot2::coord_fixed(xlim = zoom_xlim, ylim = zoom_ylim,
                       ratio = 1, expand = FALSE) +
  ggplot2::labs(title = "Venezuelan Andes: 3 climatic cells") +
  ggplot2::theme_void(base_family = "serif") +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(
      fill = "white", colour = "grey25", linewidth = 0.5),
    panel.background = ggplot2::element_rect(fill = "#F9FAFB", colour = NA),
    plot.title = ggplot2::element_text(
      size = 7.4, face = "bold", hjust = 0.5,
      margin = ggplot2::margin(t = 4, b = 5)),
    plot.margin = ggplot2::margin(4, 4, 4, 4)
  )

# Put inset over lower-left ocean portion of panel B, preserving main maps.
panel_b_inset <- panel_b + patchwork::inset_element(
  zoom, left = 0.03, bottom = 0.04, right = 0.57, top = 0.40,
  align_to = "panel", on_top = TRUE, clip = TRUE)
figure <- patchwork::wrap_plots(panel_a, panel_b_inset, ncol = 2)

png_out <- file.path(out, "Figure_2_Suitability_MESS_JIS.png")
tif_out <- file.path(out, "Figure_2_Suitability_MESS_JIS_600dpi.tif")
pdf_out <- file.path(out, "Figure_2_Suitability_MESS_JIS.pdf")

# PNG preview; vector PDF; high-resolution, LZW-compressed journal TIFF.
ggplot2::ggsave(png_out, figure,
  width = 15, height = 9, units = "in", dpi = 300, bg = "white")
ggplot2::ggsave(tif_out, figure,
  width = 15, height = 9, units = "in", dpi = 600,
  device = "tiff", compression = "lzw", bg = "white")
ggplot2::ggsave(pdf_out, figure,
  width = 15, height = 9, units = "in", device = "pdf", bg = "white")

utils::write.csv(pts, file.path(out, "Figure_2_Venezuela_cell_keys.csv"),
                 row.names = FALSE)

mess_count <- terra::global(!is.na(mess), "sum", na.rm = TRUE)[1,1]
negative_count <- terra::global(mess < 0, "sum", na.rm = TRUE)[1,1]
source_desc <- c(
  "Phalangium opilio suitability/MESS figure, Biotropica submission; historical export filenames retained.",
  "A: ORIGINAL LQ/RM2 pilot cloglog GeoTIFF, clamping enabled.",
  "B: sign of the overall MESS (5th layer from R25); not a MOP map.",
  "MESS < 0 = at least one predictor outside the sampled reference ranges.",
  "MESS >= 0 does NOT guarantee full multivariate environmental analogy.",
  "R25 reference: 5000 random climate-valid cells, seed 251018,",
  "from western Palaearctic rectangle 12W-60E, 30N-72N; NOT proven M.",
  "Venezuelan records: 7 observations mapped as 3 distinct 5' climatic cells.",
  "The single continental marker locates the study area, not one record.",
  "Inset numbered circles identify climatic cells (see key CSV).",
  paste0("Total MESS-valid South American cells: ", mess_count),
  paste0("MESS-negative cells: ", negative_count),
  "Rasters were not resampled, modified, interpolated or refitted.",
  "Conditional climatic suitability; field correspondence is descriptive transfer evidence.",
  paste("Suitability source:", normalizePath(suit_file, winslash="/")),
  paste("MESS source:", normalizePath(mess_file, winslash="/")),
  paste("Sites source:", normalizePath(site_file, winslash="/")),
  paste("terra version:", as.character(utils::packageVersion("terra"))),
  paste("ggplot2 version:", as.character(utils::packageVersion("ggplot2")))
)
writeLines(source_desc, file.path(out, "Figure_2_provenance.txt"), useBytes = TRUE)

cat("\n[R27] FIGURE 2 CREATED (exploratory suitability + MESS sign)\n")
cat("[R27] Seven Venezuelan records represented by", nrow(pts),
    "distinct climatic cells.\n")
print(pts[, c("label", "n_records", "localities")], row.names = FALSE)
cat("[R27] MESS-negative South American cells:", negative_count, "/",
    mess_count, "(", round(100*negative_count/mess_count, 2), "%).\n", sep = "")
cat("[R27] PNG: ", normalizePath(png_out, winslash="/"), "\n", sep="")
cat("[R27] TIFF 600 dpi: ", normalizePath(tif_out, winslash="/"), "\n", sep="")
cat("[R27] PDF: ", normalizePath(pdf_out, winslash="/"), "\n", sep="")
cat("[R27] No model refit or evidence of predictive validation.\n")
print(figure)
