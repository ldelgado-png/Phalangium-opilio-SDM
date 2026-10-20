# Climatic suitability of *Phalangium opilio* in South America

**Species distribution modelling | Opiliones: Phalangiidae | South America**

**Fixed operational calibration domain:** 12°W–60°E, 30°–72°N (western Palaearctic rectangle; WorldClim 2.1 at 5′; BIO1/BIO4/BIO12/BIO15). This is the definitive **operational** domain for the manuscript, but not a biogeographically demonstrated accessible area (`M`). The original 10,426 presence-cell/10,000 uniform-background pilot fit, six configurations and spatial validations are unchanged. The pre-specified clamped LQ/RM2 South American map is the **fixed manuscript projection**, with variable validation AUC (0.622–0.661 across model configurations). The central manuscript evidence is the confirmed Venezuelan field record, not the SDM.

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

The independent observations do not provide a representative sample of the entire South American projection region, nor can occurrence-only field confirmations establish regional specificity, general discrimination, or realized colonization risk. We examine whether the Venezuelan environments fall within the calibration domain before interpreting their predictions. Aggregated transfer diagnostics without private coordinates are provided in [the three-cell CSV](results/venezuela_transfer_cells_public.csv); additional specimen metadata remain in the manuscript. Climate predictors describe the 1970–2000 baseline and are not event-year weather observations.

## Calibration-region occurrence coverage

We quantified occurrence coverage within two exploratory geographical windows. Temperate Europe (12°W–35°E, 35°–72°N) contained **38,347 records** passing the selected CoordinateCleaner tests, representing **10,099 unique 5-arcminute cells**. A broader Western Palaearctic window (12°W–60°E, 30°–72°N) contained **39,493 records** representing **10,427 cells**. The expansion added **1,146 records and 328 cells**. These windows describe the geographical sampling domain and are not treated as established biogeographical accessibility boundaries.

North American occurrences were evaluated separately as a biogeographically distinct comparison dataset (**9,909 screened records; 3,266 cells**). Their origin is considered likely introduced but not conclusively resolved in the literature (Shear, 2016). We do not presume that every North American record represents an unambiguously introduced population. The contrast among Eurasian and North American calibration scenarios is conceptually distinct from transferring predictions to South America.

### Environmental coverage workflow

The `R/06_prepare_climate_and_transfer_diagnostics.R` workflow obtains WorldClim 2.1 BIO1, BIO4, BIO12, and BIO15 at 5-arcminute resolution using `geodata` and `terra`. We align occurrences to climate raster cells, calculate correlation diagnostics, and create a polygon-masked South American environmental layer using Natural Earth country boundaries. A preliminary variable-range comparison is used only to identify environmental conditions requiring careful extrapolation assessment; it is not a fitted model, MESS, or MOP. We also extract the four climatic variables at independent Venezuelan field localities and report the number of distinct confirmed raster cells. These environmental summaries are kept separate from candidate training data. The site-level suitability, MESS and MOP results are reported publicly as a [coordinate-free, three-cell summary](results/venezuela_transfer_cells_public.csv).

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

## Model fitting and spatial cross-validation

We implement a reproducible first-pass `maxnet` calibration in `R/11_pilot_ENMeval_maxnet.R` using `ENMeval`, the four WorldClim predictors, and one screened occurrence per environmental raster cell. We compare six combinations of linear (L), linear–quadratic (LQ) and linear–quadratic–hinge (LQH) features with regularization multipliers 1 and 2. Spatial block cross-validation uses the `lat_lat` orientation and a 10,000-cell random background sample when enough valid cells are available. Model-complexity diagnostics include cross-validated AUC, 10th-percentile omission, CBI and AICc.

For an initial computational benchmark, background is drawn from the climate-valid pixels in the previously documented Western Palaearctic rectangle. We explicitly distinguish this provisional geographical domain from a biogeographically justified accessible calibration area (M). The fixed-a-priori LQ model with regularization multiplier 2 produces the manuscript's South American climatic-suitability projection; this configuration was not selected using Venezuelan occurrences, which remain withheld from all fitting and tuning.

Run this stage in RStudio after the coordinate audit and WorldClim scripts:

```r
source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/11_pilot_ENMeval_maxnet.R")
```

The repository includes model-evaluation tables, scripts and archived prediction products. The model-comparison results below report the completed spatial-block evaluation.

## Initial spatial-block model evaluation

Our first completed `ENMeval` 2.0.5 / `maxnet` 0.1.4 analysis evaluated **six feature-class/regularization combinations** using **10,426** climate-cell occurrences and **10,000** background cells from the exploratory Western Palaearctic domain. We used four spatial blocks (`lat_lat` orientation) and evaluated validation AUC and continuous Boyce index (CBI), tenth-percentile omission, and AICc. The completed analysis took approximately 82 minutes.

| Configuration | Validation AUC (mean ± SD) | Validation CBI (mean ± SD) | Tenth-percentile omission | Delta AICc | Coefficients |
| :-- | --: | --: | --: | --: | --: |
| L, RM 1 | 0.622 ± 0.180 | 0.172 ± 0.813 | 0.090 | 5,213.6 | 4 |
| LQ, RM 1 | 0.652 ± 0.221 | 0.395 ± 0.672 | 0.088 | 2,731.9 | 7 |
| LQH, RM 1 | 0.661 ± 0.228 | 0.490 ± 0.576 | 0.110 | 0.0 | 33 |
| L, RM 2 | 0.622 ± 0.180 | 0.198 ± 0.796 | 0.092 | 5,306.4 | 4 |
| LQ, RM 2 | 0.648 ± 0.215 | 0.419 ± 0.637 | 0.084 | 3,856.4 | 4 |
| LQH, RM 2 | 0.654 ± 0.222 | 0.542 ± 0.544 | 0.103 | 571.9 | 21 |

The lowest AICc and highest mean validation AUC occurred for LQH/RM 1, whereas LQH/RM 2 attained the highest mean validation CBI and LQ/RM 2 the lowest tenth-percentile omission. We therefore distinguish information-criterion support from spatial predictive performance rather than treating one metric as a definitive ranking. Mean training–validation AUC differences ranged from 0.245 to 0.269, and substantial variation among spatial folds warrants fold-level interpretation.

For transparent reproducibility, the original 19-column evaluation table is provided at [`results/initial_spatial_block_ENMeval.csv`](results/initial_spatial_block_ENMeval.csv); `R/12_review_pilot_block_cv.R` extracts individual-fold scores and partition sample sizes directly from the locally preserved ENMeval evaluation object, without refitting.

Our manuscript South American projection uses the **fixed LQ/RM 2 configuration** with clamping enabled. It illustrates relative climatic suitability only, not occurrence probability, establishment, or an independently validated projection. Notably, the apparent suitability of portions of southern South America may reflect climatic similarity to the calibration domain; interpretation also requires accessible-area, sampling-bias, extrapolation, and dispersal considerations. Venezuelan field observations were not accessed for training, parameter selection, or model evaluation.

### Sensitivity of the background geographical domain

We compared the pilot rectangular background with two hypothetical spatial neighbourhoods (250 and 500 km around screened presence cells), holding the original 10,426 presence cells and 10,000 background samples per scenario constant. Under the original rectangular background, the percentages of background samples assigned to folds 1–4 were **49.47%, 13.09%, 8.28%, and 29.16%**. These changed to **24.66%, 16.09%, 14.62%, and 44.63%** under the 250-km neighbourhood, and **33.05%, 15.22%, 12.77%, and 38.96%** under the 500-km neighbourhood.

The 250-km setting increased fold 3's background size from 828 to 1,462 cells, although it concentrated almost 45% of background samples in fold 4. In fold 2, the median BIO4 value of background cells declined from 928.8 in the rectangle to 785.8 at 250 km, compared with a presence median of approximately 646.3. These changes demonstrate **strong dependence of available calibration environments on background extent**; they do not demonstrate an improvement in model discrimination or establish either buffer as the true accessible area (M).

The complete twelve-row aggregate diagnostic is archived in [`results/background_extent_fold_comparison.csv`](results/background_extent_fold_comparison.csv). The analysis is reproduced in `R/14_candidate_background_extent_diagnostics.R`. The subsequent taxon-specific effort assessment is formulated independently, prior to any effort-weighted fit.

### Geographic consistency across validation folds

We examined the 24 fold-specific evaluations obtained from the completed four-block pilot. Every setting attained validation AUC below 0.5 in folds 2 and 3, while folds 1 and 4 performed more favorably. Under LQH/RM 1, the four validation AUC values were **0.907, 0.470, 0.463, and 0.803**, with corresponding CBI values **0.996, 0.061, −0.075, and 0.976**. Tenth-percentile omission ranged from **0.036** in fold 3 to **0.310** in fold 4. The six configurations exhibited a similarly structured pattern rather than a difference restricted to one feature-class setting.

The four held-out folds contained 2,607, 2,606, 2,607, and 2,606 occurrence cells but their validation backgrounds consisted of 4,947, 1,309, 828, and 2,916 cells, respectively. ENMeval's `block` method partitions presence coordinates approximately evenly and assigns background cells according to their geographical positions relative to the occurrence-derived cutoffs. Furthermore, the pilot specified `other.settings$validation.bg = "partition"`, so spatial validation scores compare held-out presences to geographically corresponding held-out background cells, not all background cells. Background extent and predictor distributions may therefore affect the apparent discrimination of individual blocks.

We quantified each fold's geography and climatic coverage from the original ENMeval object with `R/13_diagnose_spatial_cv_domains.R`. All four validation folds form contiguous latitudinal bands, spanning approximately 31.86–45.94°N, 45.94–50.13°N, 50.13–53.14°N and 53.14–69.51°N. Among held-out presences, the percentages with at least one environmental predictor outside the full minimum–maximum range of the other three folds were **27.00%, 0.27%, 0.08%, and 0.96%**, respectively. Thus, low validation AUC in folds 2 and 3 was not associated with substantial *univariate* climate-range novelty. The median latitudes of presences and their fold-specific background differed by about +6.09°, +0.07°, −0.01°, and −3.52° (presence minus background), respectively. These contrasts suggest investigating potential geographic and environmental confounding of presence–background discrimination rather than attributing the spatial instability solely to overfitting or extrapolation.

We quantify the effects of alternative background extents with `R/14_candidate_background_extent_diagnostics.R`, which contrasts the original rectangular background with **hypothetical** 250 and 500 km neighbourhoods of the screened occurrence cells. The resulting masks and background samples are geographical sensitivity scenarios only, not independently justified accessible areas (M), and no new AUCs can be inferred without refitting and evaluating the models. We do not infer that the spatial variation uniquely demonstrates model overfitting; model complexity, unequal environmental coverage, and geographically biased sampling all remain relevant. No Venezuelan field evidence informed any of these comparisons.

## Sampling-effort bias and transparent reporting

We follow the taxon-specific sampling-effort framework of El-Gabbas (2026) and the ODMAP reporting standard of Zurell et al. (2020). The El-Gabbas dataset provides observation-count and recorded-richness rasters for **Opiliones**, enabling a more taxonomically appropriate assessment than an undifferentiated biodiversity effort surface. We use the cumulative observation-count product (1980–2025, approximately 5-km resolution) as the primary proxy for the spatial intensity of GBIF reporting in the focal order, while recognising that the observations may include records of the focal species itself.

Our analytical framework distinguishes a geographically uniform background from effort-weighted and independently assembled target-group backgrounds within a common, biogeographically justified calibration area. We retain the original unweighted ENMeval fit as a documented benchmark, rather than treating its spatial variation as a reason to select a more complex model. We also differentiate **5-km effort data** from **5-arcminute WorldClim predictors** and document all alignment and weighting choices, zero-count interpretation and temporal mismatches. The completed preparatory diagnostic in `R/15_prepare_opiliones_effort.R` aligned the author-archived `n_obs` product to WorldClim using a descriptive local mean of source cells. Within the pilot Western Palaearctic environmental rectangle, **24,343 of 292,489 climate-valid cells (8.32%)** had positive Opiliones effort values, while **9,693 of 10,426 calibrated presence cells (92.97%)** had positive effort and **733 presence cells (7.03%)** were assigned effort zero. No aligned cells were missing values. This spatial contrast is consistent with heterogeneous reporting intensity, but cannot by itself separate observational bias from underlying species distribution or contributions of the focal species to the Opiliones effort layer. Importantly, zero raster value does not imply biological absence or evidence of no visits.

The observed audit is archived in [`results/opiliones_effort_coverage_audit.csv`](results/opiliones_effort_coverage_audit.csv). We analyse the effective sampling support, weight concentration and allocation across existing spatial folds for several descriptive positive/zero handling transformations and the earlier background-extent sensitivity masks in `R/16_effort_weighting_feasibility.R`. This diagnostic does not estimate any new model scores, choose a weighting scheme, or assert a defended accessible area M.

The completed `R/16_effort_weighting_feasibility.R` audit provides an independent check of weighting concentration using the original screened presences and climatic background. Only **506 of the 10,000 uniformly sampled pilot background cells (5.06%)** had positive Opiliones effort. In the exploratory rectangular domain, after excluding the 10,426 presence pixels, **14,650 of 282,063 candidate background cells (5.19%)** had positive effort. Under weights proportional to untransformed `n_obs`, Kish's effective candidate-cell count was **631.6 (0.22%)**, with **74.27%** of weight mass carried by the top 1% of cells. The square-root and `log1p(n_obs)` transformations increased effective counts to **8,398.5 (2.98%)** and **7,567.9 (2.68%)**, respectively; `1 + log1p(n_obs)` retained **273,854.1 effective cells (97.09%)** and moved closer to uniform weights. The untransformed weights shifted the four-fold background mass from **39.33, 12.42, 8.82 and 39.43%** (uniform) to **11.86, 13.74, 26.02 and 48.38%**, respectively. These statistics describe candidate probability distributions, not sampled background realizations or model performance. The 250-km and 500-km domains remain geographic sensitivity masks rather than accessible-area definitions.

We examine these contrasts further by original validation fold and climate variable in `R/18_effort_spatial_climatic_support.R` without refitting a model. The observed R/16 outputs are archived as [pilot-sample support](results/effort_support_pilot_samples.csv), [candidate weight concentration](results/effort_weighting_concentration.csv), and [fold-specific weight mass](results/effort_weight_mass_by_fold.csv) tables.

The completed `R/18_effort_spatial_climatic_support.R` audit found positive Opiliones effort in 92.67–93.44% of pilot presence cells across the original four validation folds but in only 2.91–10.83% of eligible background cells in the exploratory rectangle. Relative to the full candidate background, the effort-positive subset omitted 4.40% of cells outside its BIO1 range, 2.81% outside BIO4, 8.31% outside BIO12, and 0.14% outside BIO15. All 10,426 calibration presences nevertheless fell within those univariate ranges. These observations do not establish multivariate coverage or a defensible accessible area. Tables: [`results/effort_presence_by_fold.csv`](results/effort_presence_by_fold.csv), [`results/effort_spatial_support_by_fold.csv`](results/effort_spatial_support_by_fold.csv), and [`results/effort_climate_range_audit.csv`](results/effort_climate_range_audit.csv).

The subsequent `R/20_prepare_target_group_download.R` dry run completed successfully: the locally printed GBIF predicate comprised `TAXON_KEY = 907` for Opiliones, the negation of `TAXON_KEY = 5776654` for *P. opilio*, `OCCURRENCE_STATUS = PRESENT`, `HAS_COORDINATE = true`, years 1980–2025, and the counter-clockwise exploratory rectangle WKT `POLYGON((-12 30,60 30,60 72,-12 72,-12 30))`. The predicate was saved locally for review. **No GBIF occurrence download was submitted**; no DOI, vetted target-group data, final accessible area (M), or additional fitted models resulted from this step.

The GBIF count preflight completed successfully in `R/19_target_group_GBIF_count_feasibility.R`. Inside the **exploratory Western Palaearctic rectangle** (12°W–60°E, 30°N–72°N; 1980–2025; coordinate-bearing records), the live GBIF search API returned **313,521 Opiliones records**, of which **43,449 were attributed to *P. opilio* (13.858%)**. The arithmetic difference is **270,072 records from other taxa**, distributed across the four original spatial blocks as **33,565**, **33,720**, **117,055**, and **85,732**. All block totals reconcile exactly to the rectangular total. The raw preflight table is archived in [`results/gbif_target_group_count_feasibility.csv`](results/gbif_target_group_count_feasibility.csv). These are occurrence-record counts, not independent observer visits, vetted localities or distinct climatic grid cells. A current GBIF download may differ from this live snapshot. We cannot use this rectangle as a justified accessible area (M) merely because it contains records.

To support a separately citable and species-excluded source dataset, `R/20_prepare_target_group_download.R` writes an inspectable GBIF query for Opiliones **excluding *P. opilio*** with matched geography, event years, coordinate availability and the GBIF Backbone taxonomic checklist. It defaults to a dry run: no GBIF occurrence download is requested and no credentials are read until the user explicitly opts in locally. The eventual candidate pool must undergo taxonomic and geographic quality assessment, removal of duplicate records and climatic-cell repetitions, and restriction to a biogeographically defended M before any background fitting or model comparison.

A user-provided manual GBIF occurrence archive is identified by download key **0033385-260928105237408** ([public archive URL](https://api.gbif.org/v1/occurrence/download/request/0033385-260928105237408.zip)). The archive itself has **not yet been inspected or verified in this repository**; its original predicate, record count, taxonomic coverage and DOI must not be inferred from the earlier GBIF search preflight. The reproducible next step is `R/21_audit_manual_GBIF_target_group.R`, which retrieves or opens that ZIP on the researcher's machine, checks available metadata and archive columns, independently excludes `P. opilio`, examines occurrence status, date, coordinates and major GBIF coordinate issues, and reports provisional non-focal 5-arcminute climate-cell support across the original validation folds. The source ZIP, full occurrence-level records and interim candidate-cell table remain local. No model is fitted, no final M is assigned, and the Venezuelan field observations are never accessed.

The user reported that the manually requested ZIP had already reached **19.7 GB while still downloading**. This is not a verified archive size or record count and may indicate broader download filters or a more extensive format than intended. The occurrence-level audit in `R/21_audit_manual_GBIF_target_group.R` is now protected by a conservative **1-GiB archive / one-million-record preflight gate** and refuses automatic processing if metadata are missing or a local ZIP is incomplete. `R/22_check_GBIF_download_metadata.R` requests **only the public GBIF metadata JSON**, without the ZIP, to inspect the actual predicate, format, record total, compressed size and DOI. The reported large download is **not evidence that the target-group dataset has been quality-controlled**, and no model is refitted.

**Critical provenance correction (GBIF manual archive `0033385-260928105237408`).** The public download metadata were independently inspected by the researcher with `R/22v3_GBIF_metadata_without_ZIP.R`. They report **SUCCEEDED**, `SIMPLE_CSV`, **1,249,731,175 occurrences**, **127.392 GiB compressed**, and DOI **10.15468/dl.tn6jvu**. Its actual predicate includes the 1980–2025 year limits and the intended polygon but **does not require membership in Opiliones** or the original positive `TAXON_KEY = 907` taxon. Instead, it includes a `NOT IN TAXON_KEY 7WCJP` exclusion under Catalogue of Life eXtended (checklist `7ddf754f-d193-4cc9-b351-99906754a03b`). The `PRESENT` and `HAS_COORDINATE` filters are also absent. This archive **MUST NOT** be described or used as the intended nonfocal Opiliones dataset; its DOI documents the incorrectly scoped request, not a source for modelling.

The corrected candidate query is published as [`docs/GBIF_corrected_target_group_predicate.json`](docs/GBIF_corrected_target_group_predicate.json) and generated as a prefilled GBIF website form by `R/23_prepare_corrected_manual_GBIF_link.R`. It explicitly **includes Opiliones**, excludes `Phalangium opilio`, constrains `PRESENT` and coordinate-bearing records, and preserves the previously audited temporal and exploratory geographical filters, all under the same GBIF Backbone taxonomy. This script only **prepares** a manual website link and does not submit a download. The corrected request remains unsubmitted; validate its human-readable predicates and estimated total on the GBIF site before proceeding. `R/21_audit_manual_GBIF_target_group.R` was also updated to accept the interpreted `order = Opiliones` when a completed SIMPLE_CSV download uses a different taxonomic checklist rather than relying solely on numeric GBIF Backbone order keys.

**Manual download predicate dry run completed (R/23).** The researcher's RStudio output confirms that `R/23_prepare_corrected_manual_GBIF_link.R` wrote a local JSON with the intended positive Opiliones key `907`, focal-species exclusion key `5776654`, GBIF Backbone checklist, 1980–2025 year bounds, `PRESENT`, required coordinates and the exploratory rectangle WKT. **This confirms local request construction, not successful application of the filters by the GBIF website. No corrected download has been submitted and no occurrence-level analysis has been completed.** The user-reported saved JSON path was under `Documentos/01_datos/...` rather than inside `Phalangium_opilio_SDM/01_datos/...`, indicating that the RStudio working directory was not the project root. R/23 now warns about this to prevent future misplaced output files; the generated website link itself is unaffected. Before submitting a new manual `SIMPLE_CSV` download, verify in the website preview that the positive Opiliones filter is retained, and independently verify the request metadata after submission.

**GBIF website route correction.** The researcher's R/23 predicate generation succeeded and the JSON is stored in the project. The generated link previously used `/occurrence/download/request/about?predicate=...`, which opens the **About** tab instead of the **Create** form. `R/23_prepare_corrected_manual_GBIF_link.R` now uses `/occurrence/download/request?predicate=...`. This is a navigation fix only: the predicate content is unchanged, no website submission is confirmed, and no download has been initiated. GBIF's official documentation confirms that taxonomic `equals` predicates can carry a `checklistKey`, while submitting a download through its web interface may require a signed-in account. Before submitting, inspect the full predicate as interpreted by the site, in particular positive membership in Opiliones and the focal-species exclusion.

**Local verification of the incorrectly scoped archive.** The researcher subsequently confirmed that the downloaded local file was named `0033385-260928105237408.zip` and occupied **35.26 GiB on disk**. This identifies it as the already-excluded request (metadata report **127.392 GiB**, **1,249,731,175** records), not a corrected Opiliones dataset. The discrepancy between the local file size and GBIF-reported size has **not** been resolved, so file completeness is unknown. The exclusion is justified by the **verified absence of a positive Opiliones filter**, regardless of file completeness. Do not unzip or ingest this archive. No corrected download or occurrence-level target-group analysis has yet taken place.

**GBIF visual predicate verification (18 October 2026).** A screenshot of the GBIF **Create → Filter** predicate editor independently confirms that the replacement manual request retains positive **Opiliones** and `NOT Phalangium opilio`, both displayed under *GBIF Backbone Taxonomy*, together with `PRESENT`, `HAS_COORDINATE = Yes`, years ≥1980 and ≤2025, and the intended provisional western Palaearctic WKT rectangle. The researcher can therefore continue to select `SIMPLE_CSV` and review the final request. **This is website-interface verification only: no replacement request has yet been submitted, downloaded or checked against its new public API metadata.** To guard against another excessive request, `R/24_verify_new_GBIF_target_group_download.R` checks the future GBIF download key, submitted predicates, GBIF Backbone checklist identifiers, completed status, file format, record count, DOI and ZIP size *without downloading occurrence data*. It rejects the known unsuitable archive and any request not meeting a conservative 1-GiB/one-million-row safety gate. Further quality control and a justified M remain necessary.

**MESS/MOP results.** [The public three-cell summary](results/venezuela_transfer_cells_public.csv) reports cell-level values without disclosing private event coordinates. It records cloglog suitability 0.558–0.617, MESS −18.727 to −18.375 and continuous MOP distances 2.028–2.458. [R/25](R/25_exploratory_MESS_MOP_south_america.R) defines the climate-reference calculation; [R/26](R/26_venezuela_transfer_diagnostics_v3.R) extracts each diagnostic independently at the Venezuelan coordinates without resampling. Continuous MOP is the mean Euclidean distance to the nearest 1% of reference climates after reference-only standardization. The source rasters and plotting scripts are deposited; independent re-execution has not been verified. The [current analysis record](docs/manuscript_transfer_status_2026-10-19.md) supersedes the status statements in the [historical staged protocol](docs/MOP_MESS_transfer_validation_protocol.md). Current manuscript numbering is habitat Figure 1, distribution Figure 2, suitability/MESS Figure 3, and specimens Figure 4.

We structure the scientific record according to **ODMAP: Overview, Data, Model, Assessment, Prediction**. The respective documentation is provided in [`docs/ODMAP_reporting_framework.md`](docs/ODMAP_reporting_framework.md) and [`docs/sampling_effort_protocol.md`](docs/sampling_effort_protocol.md). This documentation distinguishes observed model results from the analytical designs used for model development. The known Venezuelan occurrences remain withheld from calibration, background selection, tuning, and threshold choice.

## Reproducible suitability figure

**Current manuscript Figure 3 (deposited as PNG, PDF and 600-dpi TIFF in [`figures/`](figures/)):** panel A maps clamped LQ/RM2 relative suitability; panel B maps MESS sign and locates the three Venezuelan climatic cells. For the concise English legend and the archived site-level results, see [19 October manuscript transfer update](docs/manuscript_transfer_status_2026-10-19.md). The combined figure's plotting script is [`R/27_figura2_idoneidad_MESS_JIS.R`](R/27_figura2_idoneidad_MESS_JIS.R), which retains its historical Figure 2 filename. The four input GeoTIFFs are deposited under `04_resultados_modelo/pilot_western_palaearctic/`. Re-running R26 requires the researcher's private Venezuelan input table, so full independent end-to-end regeneration is not possible from public data alone.

We reproduce the South American geographic visualisation directly from the original model-derived GeoTIFF rather than redrawing or inferring raster values from an illustrative image. The script `R/17_south_america_suitability_figure.R` exports a portrait-layout (8 × 10.5 inches) publication-style PNG, a 600-dpi LZW-compressed TIFF, and a PDF while preserving the underlying suitability values and recording source provenance. The split title and compact color bar improve readability; exported files should be inspected at their native dimensions rather than judged from a small RStudio preview. The displayed map represents the fixed **LQ/RM 2 manuscript configuration**; transferability remains subject to the documented environmental-novelty limitations.

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
| `R/11_pilot_ENMeval_maxnet.R` | Performs initial maxnet tuning with spatial-block cross-validation and saves baseline suitability raster previews |
| `R/12_review_pilot_block_cv.R` | Extracts per-fold validation metrics and calibration/background group counts from the saved evaluation object |
| `R/13_diagnose_spatial_cv_domains.R` | Compares geographic extent, environmental distributions and reference-climate coverage among validation folds |
| `R/14_candidate_background_extent_diagnostics.R` | Tests hypothetical presence-neighbourhood background masks and fold-level environmental coverage without refitting |
| `R/15_prepare_opiliones_effort.R` | Retrieves and audits the cumulative GBIF Opiliones sampling-effort raster without refitting models |
| `R/16_effort_weighting_feasibility.R` | Examines observation-effort support, candidate weight concentration and spatial-fold allocation across sensitivity domains |
| `R/17_south_america_suitability_figure.R` | Reproduces the cartographic South American pilot map directly from the archived model GeoTIFF, exporting PNG/PDF/TIFF at 600 dpi |
| `R/18_effort_spatial_climatic_support.R` | Audits positive Opiliones sampling-effort support by original spatial fold and climate predictor without refitting |
| `R/19_target_group_GBIF_count_feasibility.R` | Checks current GBIF Opiliones and focal-species record counts in the original exploratory calibration region, without downloading occurrences |
| `R/20_prepare_target_group_download.R` | Prepares a reviewed, species-excluded Opiliones GBIF occurrence download predicate; submitting requires explicit local opt-in and credentials |
| `R/21_audit_manual_GBIF_target_group.R` | Inspects the user-provided GBIF ZIP, audits non-focal Opiliones records and calculates provisional climate-cell support without model fitting |
| `R/22v3_GBIF_metadata_without_ZIP.R` | Current cache-independent GBIF metadata preflight; prints download filters, format, count, ZIP size and DOI without downloading occurrence files |
| `R/23_prepare_corrected_manual_GBIF_link.R` | Generates a manually reviewable GBIF download request with positive Opiliones filter and explicitly excluded focal species |
| `R/24_verify_new_GBIF_target_group_download.R` | Inspects the NEW completed manual GBIF request for correct positive/negative taxonomic predicates, archived metadata and safe archive size; never downloads the ZIP |
| `R/25_exploratory_MESS_MOP_south_america.R` | Streams preliminary full-area MESS and MOP climate-transfer diagnostics from rasters only; no held-out Venezuelan sites or model refits |
| `R/26_venezuela_transfer_diagnostics.R` | Extracts suitability, MESS, MOP and the MESS limiting variable independently at each Venezuelan site, without raster resampling |
| `results/initial_spatial_block_ENMeval.csv` | Complete observed six-configuration ENMeval summary statistics |
| `results/background_extent_fold_comparison.csv` | Observed fold-level background composition for three exploratory sampling extents |
| `results/opiliones_effort_coverage_audit.csv` | Observed cumulative Opiliones sampling-effort coverage of climate and occurrence cells |
| `results/effort_support_pilot_samples.csv` | Observed order-level effort support of pilot presence and uniform background samples |
| `results/effort_weighting_concentration.csv` | Measured candidate weight concentration under five effort transforms across three exploratory domains |
| `results/effort_weight_mass_by_fold.csv` | Observed candidate probability mass across the original four spatial blocks |
| `results/effort_presence_by_fold.csv` | Order-level effort coverage among calibration presences in the four spatial folds |
| `results/effort_spatial_support_by_fold.csv` | Effort-positive candidate background cells by domain and spatial fold |
| `results/effort_climate_range_audit.csv` | Univariate climate range differences between full and effort-positive candidate backgrounds |
| `results/gbif_target_group_count_feasibility.csv` | Completed live GBIF order/focal/nonfocal count preflight and original four block totals |
| `data/README.md` | GBIF DOI, download metadata, source archive SHA-256, import specification |
| `docs/methodological_framework.md` | Calibration, transfer, field evidence, and evaluation principles |
| `docs/sampling_effort_protocol.md` | Taxon-specific GBIF observation-effort proxies and bias-aware background design |
| `docs/ODMAP_reporting_framework.md` | Overview, Data, Model, Assessment and Prediction reporting framework |
| `docs/GBIF_corrected_target_group_predicate.json` | Version-controlled scoped manual GBIF query using GBIF Backbone keys for Opiliones and focal exclusion |
| `docs/MOP_MESS_transfer_validation_protocol.md` | Historical staged transfer-novelty and independent-site protocol; not proof of executed local analysis |
| `docs/manuscript_transfer_status_2026-10-19.md` | Current MOP/MESS/suitability results, reference method, manuscript text and Figure 3 interpretation |
| `results/venezuela_transfer_cells_public.csv` | Original seven-event output with coordinates, cloglog suitability, MESS, continuous MOP distance and limiting variable |
| `.gitignore` | Excludes raw archives, provisional occurrence tables, raster products and local files |

The original GBIF download, intermediate tables, unpublished field material, and generated raster outputs are managed independently of this repository. The complete download is citable via its GBIF DOI; source-file licensing remains governed by the contributing datasets.

## Use of artificial intelligence

We used OpenAI's ChatGPT to assist with drafting and editing scientific English, developing and debugging R scripts, organizing reproducibility documentation, and refining figure layout. AI-generated suggestions were treated as editorial and computational assistance, not as independent scientific evidence. Numerical results reported in this repository are drawn from R analyses and their recorded outputs, rather than generated by a language model. The original model-derived GeoTIFFs, not AI-rendered illustrations, provide the data underlying reproducible suitability maps. We remain responsible for checking source data, code, references, analytical choices, interpretations, and the final research outputs.

## Scientific context and references

- GBIF.org (2026). *GBIF Occurrence Download*. https://doi.org/10.15468/dl.9gn3qv
- Zizka, A. et al. (2019). CoordinateCleaner: standardized cleaning of occurrence records from biological collection databases. *Methods in Ecology and Evolution*, 10, 744–751. https://doi.org/10.1111/2041-210X.13152
- Fick, S. E. & Hijmans, R. J. (2017). WorldClim 2: new 1-km spatial resolution climate surfaces for global land areas. *International Journal of Climatology*, 37, 4302–4315. https://doi.org/10.1002/joc.5086
- Kass, J. M. et al. (2021). ENMeval 2.0: redesigned for customizable and reproducible modeling of species’ niches and distributions. *Methods in Ecology and Evolution*, 12, 1602–1608. https://doi.org/10.1111/2041-210X.13628
- Barve, N. et al. (2011). The crucial role of the accessible area in ecological niche modeling and species distribution modeling. *Ecological Modelling*, 222, 1810–1819. https://doi.org/10.1016/j.ecolmodel.2011.02.011
- El-Gabbas, A. (2026). A global, taxon-stratified, high-resolution sampling-effort dataset from GBIF for bias-aware ecological modelling. *Diversity and Distributions*, 32, e70205. https://doi.org/10.1111/ddi.70205
- Zurell, D. et al. (2020). A standard protocol for reporting species distribution models. *Ecography*, 43, 1261–1277. https://doi.org/10.1111/ecog.04960
- Shear, W. A. (2016). New Canadian records of *Nemastoma bimaculatum* (Fabricius), and a brief summary of introduced Eurasian harvestmen in North America (Arachnida, Opiliones). *Zootaxa*, 4088, 139–140. https://doi.org/10.11646/zootaxa.4088.1.7
- Suzuki, S. & Tsurusaki, N. (1983). Opilionid fauna of Hokkaido and its adjacent areas. *Journal of the Faculty of Science, Hokkaido University, Series VI Zoology*, 23(2), 195–243. http://hdl.handle.net/2115/27679


## Manuscript-ready deposited assets (19 October 2026)

- [Figure 3, PNG](figures/Figure_3_Suitability_MESS_JIS.png), [PDF](figures/Figure_3_Suitability_MESS_JIS.pdf), [600-dpi TIFF](figures/Figure_3_Suitability_MESS_JIS_600dpi.tif).
- [R26 site diagnostics](R/26_venezuela_transfer_diagnostics_v3.R) and [R27 combined figure](R/27_figura2_idoneidad_MESS_JIS.R).
- [Coordinate-free site-cell results](results/venezuela_transfer_cells_public.csv), [reference parameters](results/26_reference_environment_parameters.csv), and [transfer summary](results/27_venezuela_transfer_summary.csv).
- Input suitability, MESS, MESS-limiting-variable, and MOP GeoTIFFs in [`04_resultados_modelo/pilot_western_palaearctic/`](04_resultados_modelo/pilot_western_palaearctic/).

**Reproduction boundary:** R27's historical local input path expects a coordinate-bearing CSV generated by R26, which is deliberately not public. The published figure and raster outputs can be inspected independently, but exact recreation of the site overlay requires access to the private site coordinates. The manuscript figure number is **Figure 3**, despite historical Figure 2 names in the plotting script.
