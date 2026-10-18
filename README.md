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

We identify and preserve each screened record by its original GBIF identifier and download-row provenance. Provenance is reconstructed by matching `gbifID` to the archived source TSV, and source-level coordinate-uncertainty information is revalidated independently of spatial-test flags. Among the **56,524** candidates, **12,898** records have no reported coordinate uncertainty. Matching the 63,407-row source TSV by `gbifID` restored original row identifiers for **18,280** candidate records and corrected **541** missing-uncertainty indicators. The corrected tally of 12,898 records without declared uncertainty is based on source values rather than inherited flags from shared coordinates. The reconstruction is implemented in `R/03_restore_GBIF_record_provenance.R`, which updates derived reporting tables without rerunning the CoordinateCleaner tests.

## Independent transfer assessment

We reserve the Venezuelan field observations as an **independent, spatially clustered assessment set**. Field observations are excluded from calibration, feature selection, regularization tuning, model comparison, and the choice of prediction thresholds. We assess transfer by extracting the final South American prediction at confirmed field localities, inspecting continuous suitability values and a pre-specified training-derived threshold. We treat distinct environmental raster cells, rather than multiple collection events in the same cell, as the spatial units for descriptive evaluation.

The independent observations do not provide a representative sample of the entire South American projection region, nor can occurrence-only field confirmations establish regional specificity, general discrimination, or realized colonization risk. We examine whether the Venezuelan environments fall within the calibration domain before interpreting their predictions. Field-level coordinates and unpublished specimen metadata remain outside this public repository. Climate predictors describe the 1970–2000 baseline and are not event-year weather observations.

## Calibration-region occurrence coverage

We quantified occurrence coverage within two exploratory geographical windows. Temperate Europe (12°W–35°E, 35°–72°N) contained **38,347 records** passing the selected CoordinateCleaner tests, representing **10,099 unique 5-arcminute cells**. A broader Western Palaearctic window (12°W–60°E, 30°–72°N) contained **39,493 records** representing **10,427 cells**. The expansion added **1,146 records and 328 cells**. These windows describe the geographical sampling domain and are not treated as established biogeographical accessibility boundaries.

North American occurrences were evaluated separately as a biogeographically distinct comparison dataset (**9,909 screened records; 3,266 cells**). Their origin is considered likely introduced but not conclusively resolved in the literature (Shear, 2016). We do not presume that every North American record represents an unambiguously introduced population. The contrast among Eurasian and North American calibration scenarios is conceptually distinct from transferring predictions to South America.

### Environmental coverage workflow

The `R/06_prepare_climate_and_transfer_diagnostics.R` workflow obtains WorldClim 2.1 BIO1, BIO4, BIO12, and BIO15 at 5-arcminute resolution using `geodata` and `terra`. We align occurrences to climate raster cells, calculate correlation diagnostics, and create a polygon-masked South American environmental layer using Natural Earth country boundaries. A preliminary variable-range comparison is used only to identify environmental conditions requiring careful extrapolation assessment; it is not a fitted model, MESS, or MOP. We also extract the four climatic variables at independent Venezuelan field localities and report the number of distinct confirmed raster cells. These private summaries are kept separate from candidate training data.

To reproduce these environmental coverage diagnostics in RStudio:

```r
source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/06_prepare_climate_and_transfer_diagnostics.R")
```

## Eastward Eurasian occurrence coverage

We distinguish the historical Eurasian distribution from the **exploratory Western Palaearctic rectangle** used for the initial climate-range diagnostic. Because available distribution accounts extend to northern and central Asia, a longitude limit of 60°E cannot be assumed to delimit the full native or accessible range. We inspected occurrence density and country composition across additional longitude bands with `R/08_eurasian_eastward_coverage.R`. Within the exploratory 30–72°N Eurasian transect, **39,493 screened occurrences (10,427 cells)** fell west of 60°E; **95 occurrences (68 cells)** fell farther east. Eastern records comprised Russia (87), Japan (6), and Kazakhstan (2). The sparsity of GBIF records in eastern Eurasia does not establish absence or inaccessibility. In particular, Suzuki and Tsurusaki (1983) regarded a recent human-mediated introduction as plausible for the Hokkaido population but did not settle its origin, so Japanese occurrences warrant separate biogeographical assessment. The completed `R/09_eastern_eurasia_climatic_coverage.R` analysis aligned **95 screened eastern occurrences to 68 distinct WorldClim cells**. Only **three cells (4.41%)**, all from Russia, exceeded at least one univariate range from the **full Western Palaearctic reference raster**; all three exceeded the BIO4 upper limit (1,488.34 in WorldClim units), reaching an eastern maximum of 1,875.19. The three records originate from the iNaturalist research-grade dataset integrated into GBIF (dataset key `50c9509d-22c7-4a22-a47d-8c48425ef4a7`). They are human observations from Gorno-Altay (2021) and Sakha (2022 and 2025), with coordinate uncertainty reported as 3 m, 2,117 m, and missing, respectively. Their original taxonomic identification and locality metadata are documented as source fields rather than assumed to be independently verified. BIO1, BIO12 and BIO15 showed no such exceedances at eastern occurrence cells. This is a comparison of univariate raster-wide environmental bounds, not a test of climatic niche equivalence, multivariate analogy, native status, or model transfer accuracy. These descriptive checks precede, but do not themselves constitute, an independently justified accessible-area (M) definition (Barve et al., 2011).

## Environmental diagnostic results

WorldClim v2.1 provided BIO1, BIO4, BIO12 and BIO15 at 5-arcminute resolution. Raster-aligned screening retained **10,098** occupied climatic cells in the temperate European diagnostic window and **10,426** in the wider Western Palaearctic diagnostic window. We retain these windows as descriptive geographic references rather than established accessible-area boundaries.

Across a random sample of South American land cells, **16.15%** fell outside the minimum–maximum range of at least one predictor in the exploratory Western Palaearctic reference window. Univariate exceedance was greatest for BIO1 (13.13% of the sample), followed by BIO12 (1.86%) and BIO15 (1.34%); BIO4 showed 0.00% in this sampled comparison. Pairwise Pearson correlations between the four predictors had maximum absolute magnitude |r| = 0.642 (BIO1–BIO15). Variance inflation factors derived from the sampled reference correlation matrix ranged from approximately 1.77 to 2.59.

These results indicate candidate environmental novelty, not failed prediction, unsuitability, or projected occupancy. The full-grid comparison implemented in `R/07_full_grid_transfer_range_audit.R` distinguishes lower and upper exceedance of reference climatic ranges, rather than relying only on the sampled percentage. The analysis deliberately does not inspect held-out Venezuelan sites when developing the model framework.

## Modelling framework

We assess candidate calibration regions using descriptive occurrence coverage across alternative Western Eurasian windows before defining a biogeographically defensible accessible area (M). Such geographic bounding boxes are diagnostic rather than model-training boundaries. Our audit also compares screening based on all selected CoordinateCleaner flags against an exploratory scenario retaining records with only urban-proximity alerts for review. These sensitivity scenarios do not automatically establish occurrence validity.



We structure the ecological niche modelling workflow in R using `terra`, `ENMeval`, and `maxnet`. The environmental framework draws on WorldClim 2.1 climatologies (1970–2000), considering annual mean temperature (BIO1), temperature seasonality (BIO4), annual precipitation (BIO12), and precipitation seasonality (BIO15). Spatially structured evaluation and model-complexity comparisons support parameter selection. Predictions for South America are interpreted as **relative climatic suitability**, not as observed occupancy or a calibrated probability of invasion.

We treat extrapolation beyond calibration environments explicitly when interpreting projections. Landscape disturbance, propagule pressure, dispersal, habitat availability, and biotic interactions may influence establishment independently of climatic suitability.

## Repository contents

| Path | Contents |
| --- | --- |
| `R/00_start_coordinatecleaner.R` | Interactive RStudio entry point for the GBIF coordinate audit |
| `R/01_coordinate_quality_GBIF.R` | Reproducible coordinate-quality screening and record-level flags |
| `R/02_rebuild_coordinate_quality_report.R` | Regenerates screening reports from stored per-record test flags |
| `R/03_restore_GBIF_record_provenance.R` | Verifies record identifiers against the GBIF source and reconstructs provenance fields and screening tables |
| `R/04_geographic_quality_audit.R` | Summarizes coordinate-quality alerts by country and compares conservative and urban-review sensitivity scenarios |
| `R/05_calibration_region_diagnostics.R` | Contrasts exploratory Western Eurasian calibration windows and the representation of occurrence records |
| `R/06_prepare_climate_and_transfer_diagnostics.R` | Prepares WorldClim variables, masks the South American projection region and audits environmental coverage |
| `R/07_full_grid_transfer_range_audit.R` | Calculates full-grid univariate environmental range exceedance, direction of BIO1 extrapolation, and sampled-reference VIF |
| `R/08_eurasian_eastward_coverage.R` | Documents screened occurrences and cell coverage across eastern Eurasian longitude bands |
| `R/09_eastern_eurasia_climatic_coverage.R` | Compares eastern Eurasian climatic cells against Western Palaearctic environmental ranges |
| `R/10_eastern_outlier_source_review.R` | Reconstructs the source-record metadata of BIO4 outliers from the archived GBIF download |
| `data/README.md` | GBIF DOI, download metadata, source archive SHA-256, import specification |
| `docs/methodological_framework.md` | Calibration, transfer, field evidence, and evaluation principles |
| `.gitignore` | Excludes raw archives, provisional occurrence tables, raster products and local files |

The original GBIF download, intermediate tables, unpublished field material, and generated raster outputs are managed independently of this repository. The complete download is citable via its GBIF DOI; source-file licensing remains governed by the contributing datasets.

## Scientific context and references

- GBIF.org (2026). *GBIF Occurrence Download*. https://doi.org/10.15468/dl.9gn3qv
- Zizka, A. et al. (2019). CoordinateCleaner: standardized cleaning of occurrence records from biological collection databases. *Methods in Ecology and Evolution*, 10, 744–751. https://doi.org/10.1111/2041-210X.13152
- Fick, S. E. & Hijmans, R. J. (2017). WorldClim 2: new 1-km spatial resolution climate surfaces for global land areas. *International Journal of Climatology*, 37, 4302–4315. https://doi.org/10.1002/joc.5086
- Kass, J. M. et al. (2021). ENMeval 2.0: redesigned for customizable and reproducible modeling of species’ niches and distributions. *Methods in Ecology and Evolution*, 12, 1602–1608. https://doi.org/10.1111/2041-210X.13628
- Barve, N. et al. (2011). The crucial role of the accessible area in ecological niche modeling and species distribution modeling. *Ecological Modelling*, 222, 1810–1819. https://doi.org/10.1016/j.ecolmodel.2011.02.011
- Shear, W. A. (2016). New Canadian records of *Nemastoma bimaculatum* (Fabricius), and a brief summary of introduced Eurasian harvestmen in North America (Arachnida, Opiliones). *Zootaxa*, 4088, 139–140. https://doi.org/10.11646/zootaxa.4088.1.7
- Suzuki, S. & Tsurusaki, N. (1983). Opilionid fauna of Hokkaido and its adjacent areas. *Journal of the Faculty of Science, Hokkaido University, Series VI Zoology*, 23(2), 195–243. http://hdl.handle.net/2115/27679

The associated field manuscript is maintained separately as a working document and is not reproduced here.