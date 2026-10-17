# Climatic suitability of *Phalangium opilio* in South America

**Species distribution modelling | Opiliones: Phalangiidae | South America**

## Study overview

*Phalangium opilio* (Linnaeus, 1758) is a Palaearctic harvestman with established populations beyond its native range. Recent collections from the Venezuelan Andes document its presence in South America and provide a basis for investigating environmental suitability across the continent. We use occurrence records and climatic predictors to develop a reproducible framework for examining the potential geographical extent of suitable conditions in South America.

We distinguish the **model calibration region** from the **projection region**. This distinction is essential for a species introduced beyond its native range: the known Venezuelan records are not treated as a broadly representative sample of its accessible environmental space. We retain the South American field evidence as a separate dataset and use it to contextualize model transfer, rather than conflating field confirmation with independent model evaluation.

## Occurrence data

We use a GBIF taxon-filtered occurrence download for *Phalangium opilio*, comprising **63,407 records from 506 publishing datasets**. We preserve its provenance and the complete filter expression in [`data/README.md`](data/README.md). The original GBIF download is cited using its registered DOI:

> GBIF.org (2026). *GBIF Occurrence Download*. https://doi.org/10.15468/dl.9gn3qv

The downloaded archive contains a tab-separated file with a `.csv` extension; scripts therefore read it using tab delimiters rather than comma delimiters. The source data are versioned by a cryptographic checksum and the DOI, rather than reproduced as an unattributed occurrence compilation.

## Data screening and spatial quality

We use explicit record-level criteria to screen taxonomic assignments, occurrence status, coordinate completeness and plausibility, and reported coordinate uncertainty. Our coordinate-quality workflow is implemented in `CoordinateCleaner` and maintains individual test flags for inspection. Flags denote possible georeferencing problems; they are not interpreted as definitive errors without further examination.

We keep records associated with the Venezuelan manuscript separate from the GBIF calibration records and avoid using the same field observations both for model fitting and for purportedly independent evaluation. Occurrence thinning at the environmental-raster resolution is used to address multiple records within the same climatic grid cell; this does not, by itself, correct uneven collection effort.

## Modelling framework

We structure the ecological niche modelling workflow in R using `terra`, `ENMeval`, and `maxnet`. The environmental framework draws on WorldClim 2.1 climatologies (1970–2000), considering annual mean temperature (BIO1), temperature seasonality (BIO4), annual precipitation (BIO12), and precipitation seasonality (BIO15). Spatially structured evaluation and model-complexity comparisons support parameter selection. Predictions for South America are interpreted as **relative climatic suitability**, not as observed occupancy or a calibrated probability of invasion.

We treat extrapolation beyond calibration environments explicitly when interpreting projections. Landscape disturbance, propagule pressure, dispersal, habitat availability, and biotic interactions may influence establishment independently of climatic suitability.

## Repository contents

| Path | Contents |
| --- | --- |
| `R/01_coordinate_quality_GBIF.R` | Reproducible coordinate-quality screening and record-level flags |
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