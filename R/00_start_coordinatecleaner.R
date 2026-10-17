# Phalangium opilio: reproducible GBIF coordinate screening
# Interactive entry point for RStudio on Windows, macOS, or Linux.
#   source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/00_start_coordinatecleaner.R")
#
# We preserve the original occurrence archive and do not automatically
# discard records flagged by CoordinateCleaner.

if (!interactive()) {
  stop("Run this script in an interactive RStudio session to select the GBIF ZIP.")
}

message("\nPHALANGIUM OPILIO | GBIF coordinate screening\n",
        "Select the original GBIF download (the ZIP containing ",
        "0032625-260928105237408.csv).\n",
        "Do not select the larger project archive.")

zip_in <- file.choose()
zip_in <- normalizePath(zip_in, winslash = "/", mustWork = TRUE)
zip_members <- tryCatch(
  utils::unzip(zip_in, list = TRUE)$Name,
  error = function(e) stop("The selected file is not a valid ZIP: ", conditionMessage(e))
)
gbif_member <- zip_members[grepl("\\.csv$", zip_members, ignore.case = TRUE)]
if (length(gbif_member) != 1L ||
    basename(gbif_member) != "0032625-260928105237408.csv") {
  stop("Please select the ORIGINAL GBIF ZIP containing ",
       "'0032625-260928105237408.csv'. ",
       "It is approximately 7.8 MB, not the full project ZIP.")
}

current_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (basename(current_dir) == "Phalangium_opilio_SDM") {
  project_dir <- current_dir
} else {
  project_dir <- file.path(current_dir, "Phalangium_opilio_SDM")
}
dir.create(file.path(project_dir, "01_datos"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(project_dir, "R"), recursive = TRUE, showWarnings = FALSE)

raw_target <- file.path(project_dir, "01_datos", "gbif_descarga_original.zip")
if (zip_in != normalizePath(raw_target, winslash = "/", mustWork = FALSE)) {
  if (!file.copy(zip_in, raw_target, overwrite = TRUE)) {
    stop("Could not copy the original GBIF ZIP into ", raw_target)
  }
}
if (!file.exists(raw_target)) stop("GBIF ZIP was not saved correctly.")

script_url <- paste0(
  "https://raw.githubusercontent.com/ldelgado-png/",
  "Phalangium-opilio-SDM/main/R/01_coordinate_quality_GBIF.R"
)
local_script <- file.path(project_dir, "R", "01_coordinate_quality_GBIF.R")
message("Retrieving the versioned audit script from GitHub...")
download_success <- tryCatch({
  utils::download.file(script_url, destfile = local_script,
                       mode = "wb", quiet = TRUE)
  TRUE
}, error = function(e) {
  message("Script retrieval failed: ", conditionMessage(e))
  FALSE
})
if (!download_success || !file.exists(local_script) ||
    file.size(local_script) < 1000L) {
  stop("Unable to obtain the GitHub audit script. ",
       "Check your internet connection and retry.")
}

if (!requireNamespace("CoordinateCleaner", quietly = TRUE)) {
  message("Installing CoordinateCleaner from CRAN and its dependencies...")
  utils::install.packages("CoordinateCleaner",
                          repos = "https://cloud.r-project.org")
}
if (!requireNamespace("CoordinateCleaner", quietly = TRUE)) {
  stop("CoordinateCleaner is not available after installation; ",
       "please copy the preceding installation error from the R console.")
}

setwd(project_dir)
message("\nWorking folder: ", normalizePath(getwd(), winslash = "/"))
message("Starting occurrence quality control...\n")
source(local_script, echo = FALSE, encoding = "UTF-8")

summary_file <- file.path("01_datos", "coordinatecleaner", "06_coordinate_quality_summary.csv")
if (file.exists(summary_file)) {
  message("\nQuality-control summary:")
  print(utils::read.csv(summary_file, stringsAsFactors = FALSE),
        row.names = FALSE)
  message("\nShare the console output and the CSV files in: ",
          normalizePath(dirname(summary_file), winslash = "/"))
} else {
  message("\nCheck the files written to 01_datos/coordinatecleaner.")
}
