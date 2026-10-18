# Phalangium opilio | Reproducible South American suitability figure
#
# RStudio:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/17_south_america_suitability_figure.R")
#
# Recreates the polished visual appearance from the ORIGINAL maxnet GeoTIFF,
# rather than inferring raster values from an image. Does not fit models or
# inspect withheld Venezuelan field records.
#
# NOTE: the source prediction is the previously generated exploratory
# LQ/RM2 pilot. Publication-style graphical formatting does not turn it
# into an independently validated final model.

packages <- c("terra", "sf", "ggplot2", "rnaturalearth")
missing <- packages[!vapply(packages, requireNamespace,
                            FUN.VALUE = logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install these R packages and rerun: install.packages(c(",
       paste(sprintf('"%s"', missing), collapse = ", "), "))")
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
pilot_dir <- file.path(root, "04_resultados_modelo",
                       "pilot_western_palaearctic")
input <- file.path(pilot_dir,
                   "09_pilot_south_america_LQ_rm2_cloglog_NOT_FINAL.tif")
if (!file.exists(input)) {
  message("Select the original GeoTIFF from the pilot folder.")
  input <- file.choose()
  if (tolower(tools::file_ext(input)) != "tif") {
    stop("Please select the original maxnet prediction GeoTIFF, not a PNG.")
  }
  pilot_dir <- dirname(input)
}
r <- terra::rast(input)
if (terra::nlyr(r) != 1L ||
    !isTRUE(terra::is.lonlat(r))) {
  stop("Expected one geographic climatic-suitability raster.")
}
bounds <- terra::global(r, fun = "range", na.rm = TRUE)
if (any(!is.finite(as.matrix(bounds))) ||
    min(as.matrix(bounds)) < -0.001 ||
    max(as.matrix(bounds)) > 1.001) {
  stop("Expected a continuous suitability surface bounded by 0 and 1.")
}
names(r) <- "suitability"

# The cartographic raster is taken directly from the fitted model. No
# interpolation, rescaling of model values or redrawing by AI occurs.
df <- terra::as.data.frame(r, xy = TRUE, na.rm = TRUE)
if (nrow(df) < 10000L) stop("The prediction raster contains too few pixels.")

# Natural Earth coastlines provide visual context but do not modify values.
countries <- rnaturalearth::ne_countries(
  scale = 110, continent = "South America", returnclass = "sf"
)
if (!nrow(countries)) stop("Unable to retrieve South American boundaries.")
countries <- sf::st_transform(countries, 4326)
coast <- sf::st_sf(geometry = sf::st_union(sf::st_geometry(countries)))

# Gradient matched to the illustrative figure: dark maroon for low relative
# suitability, orange for intermediate, and pale yellow for high.
colours <- c(
  "#650020", "#990020", "#C81A0B", "#E74100",
  "#FB8600", "#FFC536", "#FFF9C4"
)
figure <- ggplot2::ggplot() +
  ggplot2::geom_raster(
    data = df, ggplot2::aes(x = x, y = y, fill = suitability),
    interpolate = FALSE
  ) +
  ggplot2::geom_sf(
    data = coast, inherit.aes = FALSE,
    fill = NA, color = "#242424", linewidth = 0.24
  ) +
  ggplot2::scale_fill_gradientn(
    colours = colours,
    values = c(0, 0.15, 0.30, 0.45, 0.62, 0.80, 1),
    limits = c(0, 1),
    breaks = seq(0.2, 0.8, 0.2),
    na.value = "transparent",
    name = "Climatic\nsuitability",
    guide = ggplot2::guide_colorbar(
      title.position = "top",
      barheight = grid::unit(9.0, "cm"),
      barwidth = grid::unit(0.55, "cm"),
      frame.colour = "#242424",
      ticks.colour = "#242424"
    )
  ) +
  ggplot2::scale_x_continuous(
    breaks = seq(-80, -40, by = 10),
    labels = function(z) paste0(abs(z), "°W")
  ) +
  ggplot2::scale_y_continuous(
    breaks = seq(-50, 10, by = 10),
    labels = function(z) {
      ifelse(z > 0, paste0(z, "°N"),
             ifelse(z < 0, paste0(abs(z), "°S"), "0°"))
    }
  ) +
  ggplot2::coord_sf(
    crs = sf::st_crs(4326),
    xlim = c(-82, -34),
    ylim = c(-56, 13),
    expand = FALSE,
    datum = sf::st_crs(4326)
  ) +
  ggplot2::labs(
    title = expression(italic("Phalangium opilio")),
    subtitle = "Climatic suitability in South America",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_classic(base_family = "serif", base_size = 11) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(
      hjust = 0.5, size = 16,
      margin = ggplot2::margin(b = 2)
    ),
    plot.subtitle = ggplot2::element_text(
      hjust = 0.5, size = 12,
      margin = ggplot2::margin(b = 12)
    ),
    plot.background = ggplot2::element_rect(
      fill = "white", colour = NA
    ),
    panel.background = ggplot2::element_rect(
      fill = "white", colour = NA
    ),
    panel.border = ggplot2::element_rect(
      fill = NA, colour = "#333333", linewidth = 0.35
    ),
    axis.line = ggplot2::element_blank(),
    axis.text = ggplot2::element_text(colour = "#222222", size = 9),
    axis.text.x = ggplot2::element_text(
      margin = ggplot2::margin(t = 4)
    ),
    axis.title = ggplot2::element_text(size = 11),
    legend.title = ggplot2::element_text(
      size = 10, lineheight = 1.0, hjust = 0.5
    ),
    legend.text = ggplot2::element_text(size = 9),
    legend.position = "right",
    legend.box.spacing = grid::unit(0.25, "cm"),
    plot.margin = ggplot2::margin(10, 12, 10, 12)
  )

# Keep publication-style figure files separate from model outputs.
out <- file.path(pilot_dir, "publication_style_figures")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
png_file <- file.path(out, "Phalangium_opilio_South_America.png")
tiff_file <- file.path(out, "Phalangium_opilio_South_America_600dpi.tif")
pdf_file <- file.path(out, "Phalangium_opilio_South_America.pdf")

ggplot2::ggsave(
  png_file, plot = figure,
  width = 8, height = 10.5, units = "in",
  dpi = 600, bg = "white"
)
ggplot2::ggsave(
  tiff_file, plot = figure,
  width = 8, height = 10.5, units = "in",
  dpi = 600, compression = "lzw", bg = "white"
)
ggplot2::ggsave(
  pdf_file, plot = figure,
  width = 8, height = 10.5, units = "in",
  device = "pdf", bg = "white"
)
writeLines(c(
  "Source raster: model-derived maxnet/ENMeval pilot prediction, LQ/RM2.",
  paste("Input:", normalizePath(input, winslash = "/")),
  "Climatic suitability, cloglog scale with clamping enabled.",
  "Figure: South America, WGS84, Natural Earth country union coastline.",
  "Colour scale: relative suitability from 0 to 1.",
  "Publication-style portrait layout: 8 x 10.5 inches, exported at 600 dpi.",
  "The appearance is publication-style; the model is NOT final or validated.",
  "Venezuelan independent observations are not loaded or plotted."
), file.path(out, "figure_provenance.txt"))

# The narrow RStudio Plots pane can compress the aspect ratio visually.
# Open the exported PNG/PDF at full size to judge figure proportions.
print(figure)
message("If the RStudio preview looks cramped, open the exported PNG ",
        "at 100% zoom; the saved figure uses a fixed portrait page.")
cat("\nMap outputs (original raster values preserved):\n")
cat(normalizePath(png_file, winslash = "/"), "\n")
cat(normalizePath(tiff_file, winslash = "/"), "\n")
cat(normalizePath(pdf_file, winslash = "/"), "\n")
cat("Source model remains exploratory pending calibration and validation.\n")
