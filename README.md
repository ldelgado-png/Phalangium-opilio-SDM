# Climatic suitability of *Phalangium opilio* in South America

**Species distribution modelling | Opiliones: Phalangiidae | South America**

## Study overview

*Phalangium opilio* (Linnaeus, 1758) is a Palaearctic harvestman with established populations beyond its native range. Recent collections from the Venezuelan Andes document its presence in South America and provide a basis for investigating environmental suitability across the continent. We use occurrence records and climatic predictors to develop a reproducible framework for examining the potential geographical extent of suitable conditions in South America.

We distinguish the **model calibration region** from the **projection region**. This distinction is essential for a species introduced beyond its native range: the known Venezuelan records are not treated as a broadly representative sample of its accessible environmental space. We retain the South American field evidence as a separate dataset and use it to contextualize model transfer, rather than conflating field confirmation with independent model evaluation.

## Occurrence data

We use a GBIF taxon-filtered occurrence download for *Phalangium opilio*, comprising **63,407 records from 506 publishing datasets**. We preserve its provenance and the complete filter expression in [`data/README.md`](data/README.md). The original GBIF download is cited using its registered DOI:

> GBIF.org (2026). *GBIF Occurrence Download*. https://doi.org/10.15468/dl.9gn3qv

The downloaded archive contains a tab-separated file with a `.csv` extension; scripts therefore read it using tab delimiters rather than comma delimiters. The source data are versioned by a cryptographic checksum and the DOI, rather than reproduced as an unattributed occurrence compilation.

## Running the coordinate-quality workflow

We provide a one-command interactive entry point for RStudio on Windows, macOS, and Linux:

```r
source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/00_start_coordinatecleaner.R")
```

After starting the script, select the **original GBIF occurrence ZIP** corresponding to [doi:10.15468/dl.9gn3qv](https://doi.org/10.15468/dl.9gn3qv). The entry point creates a local project folder, stores the unchanged source ZIP, installs CoordinateCleaner when required, retrieves the audit script and writes per-record flags and tabulated summaries. It does not automatically exclude records flagged by CoordinateCleaner.

The console prints the output directory containing `06_coordinate_quality_summary.csv` and `03_records_for_review.csv`. These files document coordinate-quality tests and can be used to audit the eventual calibration dataset.

## Data screening and spatial quality

We use explicit record-level criteria to screen taxonomic assignments, occurrence status, coordinate completeness and plausibility, and reported coordinate uncertainty. Our coordinate-quality workflow is implemented in `CoordinateCleaner` and maintains individual test flags for inspection. Flags denote possible georeferencing problems; they are not interpreted as definitive errors without further examination.

We keep records associated with the Venezuelan manuscript separate from the GBIF calibration records and avoid using the same field observations both for model fitting and for purportedly independent evaluation. Occurrence thinning at the environmental-raster resolution is used to address multiple records within the same climatic grid cell; this does not, by itself, correct uneven collection effort.

## Occurrence-quality screening

Our initial screening used R 4.6.1 and `CoordinateCleaner` 3.0.1. We applied taxonomic, occurrence-status, coordinate, and reported-uncertainty criteria to the 63,407 GBIF records. Initial filters excluded **6,883** records, leaving **56,524** candidates encompassing **38,244 distinct coordinate pairs**. CoordinateCleaner flagged **6,121 occurrence records** (3,778 distinct tested positions); **50,403** occurrence records passed the selected coordinate tests. Retaining at most one occurrence per 5-arcminute grid cell produced **14,065** exploratory cells.

These statistics describe occurrence screening and raster-cell thinning rather than ecological niche model performance. Coordinate warnings are retained at record level, and we distinguish geographic-quality screening from sampling-effort bias and from biogeographic accessibility.

We identify and preserve each screened record by its original GBIF identifier and download-row provenance. Provenance is reconstructed by matching `gbifID` to the archived source TSV, and source-level coordinate-uncertainty information is revalidated independently of spatial-test flags. Among the **56,524** candidates, **12,898** records have no reported coordinate uncertainty. The reconstruction is implemented in `R/03_restore_GBIF_record_provenance.R`, which updates derived reporting tables without rerunning the CoordinateCleaner tests.

## Modelling framework

We structure the ecological niche modelling workflow in R using `terra`, `ENMeval`, and `maxnet`. The environmental framework draws on WorldClim 2.1 climatologies (1970–2000), considering annual mean temperature (BIO1), temperature seasonality (BIO4), annual precipitation (BIO12), and precipitation seasonality (BIO15). Spatially structured evaluation and model-complexity comparisons support parameter selection. Predictions for South America are interpreted as **relative climatic suitability**, not as observed occupancy or a calibrated probability of invasion.

We treat extrapolation beyond calibration environments explicitly when interpreting projections. Landscape disturbance, propagule pressure, dispersal, habitat availability, and biotic interactions may influence establishment independently of climatic suitability.

## Repository contents

| Path | Contents |
| --- | --- |
| `R/00_start_coordinatecleaner.R` | Interactive RStudio entry point for the GBIF coordinate audit |
| `R/01_coordinate_quality_GBIF.R` | Reproducible coordinate-quality screening and record-level flags |
| `R/02_rebuild_coordinate_quality_report.R` | Regenerates screening reports from stored per-record test flags |
| `R/03_restore_GBIF_record_provenance.R` | Verifies record identifiers against the GBIF source and reconstructs provenance fields and screening tables |
| `data/README.md` | GBIF DOI, download metadata, source archive SHA-256, import specification |
| `docs/methodological_framework.md` | Calibration, transfer, field evidence, and evaluation principles |
| `.gitignore` | Excludes raw archives, provisional occurrence tables, raster products and local files |

The original GBIF download, intermediate tables, unpublished field material, and generated raster outputs are managed independently of this repository. The complete download is citable via its GBIF DOI; source-file licensing remains governed by the contributing datasets.

## Scientific context and references

- GBIF.org (2026). *GBIF Occurrence Download*. https://doi.org/10.15468/dl.9gn3qv
- Zizka, A. et al. (2019). CoordinateCleaner: standardized cleaning of occurrence records from biological collection databases. *Methods in Ecology and Evolution*, 10, 744–751. https://doi.org/10.1111/2041-210X.13152
- Fick, S. E. & Hijmans, R. J. (2017). WorldClim 2: new 1-km spatial resolution climate surfaces for global land areas. *International Journal of Climatology*, 37, 4302–4315. https://doi.org/10.1002/joc.5086
- Kass, J. M. et al. (2021). ENMeval 2.0: redesigned for customizable and reproducible modeling of species’ niches and distributions. *Methods in Ecology and Evolution*, 12, 1602–1608. https://doi.org/10.1111/2041-210X.13628

The associated field manuscript is maintained separately as a working document and is not reproduced here.