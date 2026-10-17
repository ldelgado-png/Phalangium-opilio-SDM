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
  error = function(e) stop("The selected file is not a valid ZIP: ",
                           conditionMessage(e))
)

# Accept both the original 7.8 MB GBIF ZIP and the complete project ZIP.
# The latter contains a second, nested ZIP under 01_datos/.
source_member <- "0032625-260928105237408.csv"
if (length(zip_members) == 1L &&
    basename(zip_members) == source_member) {
  gbif_zip <- zip_in
  message("Recognized the original GBIF ZIP.")
} else {
  nested <- zip_members[grepl(
    "(^|/)01_datos/gbif_descarga_original\\.zip$", zip_members
  )]
  if (length(nested) != 1L) {
    stop(
      "This ZIP contains neither the original GBIF file nor the complete ",
      "project archive. Select '0032625-260928105237408 (1).zip' ",
      "(7.8 MB), or 'Phalangium_opilio_SDM_etapa_02.zip' ",
      "(the complete project package)."
    )
  }
  message("Recognized the complete project ZIP; extracting only ",
          "the embedded original GBIF ZIP...")
  tmp_extract <- tempfile(pattern = "gbif_input_")
  dir.create(tmp_extract)
  utils::unzip(zip_in, files = nested, exdir = tmp_extract,
               junkpaths = TRUE, overwrite = TRUE)
  gbif_zip <- file.path(tmp_extract, "gbif_descarga_original.zip")
  if (!file.exists(gbif_zip)) {
    stop("Could not extract the embedded original GBIF ZIP.")
  }
  inner_members <- tryCatch(
    utils::unzip(gbif_zip, list = TRUE)$Name,
    error = function(e) stop("The embedded GBIF ZIP is invalid: ",
                             conditionMessage(e))
  )
  if (length(inner_members) != 1L ||
      basename(inner_members) != source_member) {
    stop("The embedded ZIP does not contain the expected GBIF TSV.")
  }
}
size_bytes <- file.info(gbif_zip)$size
if (!is.na(size_bytes) && size_bytes != 7793071) {
  warning("The ZIP differs in size from the archived GBIF download. ",
          "Confirm that it corresponds to DOI 10.15468/dl.9gn3qv.")
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
if (gbif_zip != normalizePath(raw_target, winslash = "/", mustWork = FALSE)) {
  if (!file.copy(gbif_zip, raw_target, overwrite = TRUE)) {
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
