# ODMAP reporting framework for *Phalangium opilio* in South America

The study documentation follows the five-component **ODMAP** reporting protocol (Overview, Data, Model, Assessment and Prediction) of Zurell et al. (2020). This framework separates completed exploratory model evidence from requirements for definitive inference and provides a traceable description of the study's objectives, assumptions, data, algorithms, evaluation design and transfer.

## Overview

**Objective.** We evaluate the climatic conditions potentially suitable for *Phalangium opilio* in South America in relation to documented records from the Venezuelan Andes. Inference concerns **relative climatic suitability** and does not estimate establishment probability, dispersal rate, propagule pressure, or realized future spread.

**Conceptual model.** We distinguish the calibration domain, a biologically justified accessible area (M), from the South American projection extent. We also distinguish local environment, observation process, and the known distribution of the species. The range of origin offers a basis for transfer, while observations from Venezuela provide a geographically independent check once modelling decisions have been fixed.

**Spatial and temporal resolution.** Predictors comprise WorldClim v2.1 BIO1, BIO4, BIO12 and BIO15 at 5-arcminute resolution, representing the 1970–2000 climate baseline. Presence records come from a reproducible GBIF occurrence download (https://doi.org/10.15468/dl.9gn3qv).

**Algorithms.** `ENMeval` and `maxnet` are used to compare MaxEnt-style penalised occurrence–background models across feature and regularisation settings. Spatially structured hold-out partitions are used to quantify geographic transfer within the calibration domain.

## Data

**Occurrence provenance.** The documented GBIF snapshot contains 63,407 records. Initial filtering retained 56,524 candidates, with 50,403 passing the selected `CoordinateCleaner` geographic checks; 10,426 distinct 5-arcminute climatic cells were used in the first Western Palaearctic pilot. The original source archive is stored and identified by a checksum, download DOI and source-row links.

**Taxonomy and coordinate screening.** We audit occurrence status, taxonomic assignments, coordinate precision, spatial uncertainty and the test-specific `CoordinateCleaner` flags. Coordinate alerts near cities, institutions or coastlines are not assumed to prove location error. We separate one-per-climate-cell thinning from correction of sampling bias.

**Environmental data.** WorldClim v2.1 offers four initial bioclimatic predictors. Environmental correlation and multivariate redundancy are assessed relative to the calibration area. The Western Palaearctic rectangular extent was an initial exploratory domain, not a biologically established accessible area.

**Observation process.** We consider the taxon-stratified GBIF sampling-effort products of El-Gabbas (2026), preferably cumulative `Opiliones` observation counts (`n_obs`) and with careful treatment of taxonomy, date, projection geometry and potential inclusion of the target species in the effort proxy. Uniform, effort-weighted and appropriately constructed target-group backgrounds are distinct analytical alternatives. The effort layer is not treated as ecological absence.

## Model

**Computational pilot.** The first completed benchmark evaluated six feature/regularization combinations (L, LQ and LQH; RM 1 and 2), with 10,426 presence cells, 10,000 uniform background cells and four spatial validation blocks in the Western Palaearctic exploratory rectangle. The run was completed with `ENMeval` 2.0.5 and `maxnet` 0.1.4.

**Accessible area and background.** Calibration background is defined relative to an independently justified accessibility scenario rather than solely by the rectangular bounding extent of occurrence coordinates. Background weighting is analyzed separately from accessible-area delineation; any comparisons specify the sampling algorithm, random seed, transformation of effort counts and effective sample size.

**Tuning and selection.** We distinguish penalized likelihood fit (AICc), spatial discrimination (validation AUC), presence omission, model complexity and the continuous Boyce index. We avoid choosing a model based on the withheld Venezuelan field observations.

## Assessment

**Internal validation.** Our first latitudinal four-block analysis showed a pronounced fold-specific contrast: mean validation AUC across the six model settings ranged from approximately 0.622 to 0.661, with consistently weaker discrimination in the two central latitude bands. The number and environmental distribution of validation background cells varied substantially across folds. We interpret these as diagnostics of spatially heterogeneous discrimination, not a definitive identification of overfitting.

**Extrapolation.** Full-grid comparison against the initial Western Palaearctic environmental rectangle found 34,549 of 223,558 South American climate-valid land cells (15.454%) outside at least one univariate environmental range. This is a descriptive warning, not a formal multivariate environmental similarity statistic or a claim of environmental unsuitability.

**Independent field evidence.** Seven events from the Venezuelan Andes correspond to six geographic coordinate pairs and three confirmed 5-arcminute climatic cells. These are not used to calibrate, tune, choose thresholds or rank models. Any later field-based assessment is limited by the geographic clustering and low number of independent climatic cells. Their records and unpublished metadata are not distributed through this public repository.

## Prediction

**Output interpretation.** South American maps represent relative climatic suitability for the 1970–2000 climate baseline conditional on model settings, sampled occurrence environments, accessible calibration area and handling of extrapolation. A plotted pilot projection is not a final model output, and visually plausible patterns are not treated as validation.

**Transfer uncertainty.** Reporting distinguishes within-range transfer and extrapolation, clamp settings, alternative model and background configurations, resolution and data uncertainty. Suitability does not imply arrival, survival, reproduction, or demonstrated introduction.

**Reproducibility.** Code, model metrics, package versions, download DOI and explicit methodological choices are published in this repository. The raw source download and the field occurrences remain separately managed. Model artefacts are reported as completed results only when the analyses have actually run.

## References

- Zurell D, Franklin J, König C, et al. (2020) A standard protocol for reporting species distribution models. *Ecography* 43: 1261–1277. https://doi.org/10.1111/ecog.04960.
- El-Gabbas A (2026) A global, taxon-stratified, high-resolution sampling-effort dataset from GBIF for bias-aware ecological modelling. *Diversity and Distributions* 32: e70205. https://doi.org/10.1111/ddi.70205.
