# ODMAP reporting framework for *Phalangium opilio* in South America

**Manuscript decision (18 October 2026): operational study domain fixed.** The rectangle 12°W–60°E, 30°–72°N is now the **definitive geographical calibration/background domain for the submitted manuscript analysis**; see [`fixed_calibration_domain_decision.md`](fixed_calibration_domain_decision.md) and [`study_calibration_domain_fixed.json`](study_calibration_domain_fixed.json). Fixing these coordinates is a reproducibility decision and does **not** prove that the rectangle constitutes the biogeographically accessible area M. Prior paragraphs that refer to an "exploratory" or "provisional" window describe the historical pilot phase, whose recorded results remain unchanged. The model's moderate, fold-dependent evaluation and uniform background assumptions continue to limit inference. The geographical limits must not be re-optimized to fit the withheld Venezuelan sites. The deposited coordinate-free summary reports negative MESS at three Venezuelan climatic cells, cloglog predictions of 0.558–0.617, and continuous MOP distances of 2.028–2.458. Source GeoTIFFs and R26/R27 scripts are archived; independent end-to-end execution has not been verified.


The study documentation follows the five-component **ODMAP** reporting protocol (Overview, Data, Model, Assessment and Prediction) of Zurell et al. (2020). This framework separates completed model evidence from limitations on inference and provides a traceable description of the study's objectives, assumptions, data, algorithms, evaluation design and transfer.

## Overview

**Objective.** We evaluate the climatic conditions potentially suitable for *Phalangium opilio* in South America in relation to documented records from the Venezuelan Andes. Inference concerns **relative climatic suitability** and does not estimate establishment probability, dispersal rate, propagule pressure, or realized future spread.

**Conceptual model.** We distinguish the operational calibration rectangle, the concept of a biogeographically justified accessible area (*M*), and the South American projection extent. We also distinguish local environment, observation process, and the known distribution of the species. The range of origin offers a basis for transfer, while observations from Venezuela provide a geographically independent check once modelling decisions have been fixed.

**Spatial and temporal resolution.** Predictors comprise WorldClim v2.1 BIO1, BIO4, BIO12 and BIO15 at 5-arcminute resolution, representing the 1970–2000 climate baseline. Presence records come from a reproducible GBIF occurrence download (https://doi.org/10.15468/dl.9gn3qv).

**Algorithms.** `ENMeval` and `maxnet` are used to compare MaxEnt-style penalised occurrence–background models across feature and regularisation settings. Spatially structured hold-out partitions are used to quantify geographic transfer within the calibration domain.

## Data

**Occurrence provenance.** The documented GBIF snapshot contains 63,407 records. Initial filtering retained 56,524 candidates, with 50,403 passing the selected `CoordinateCleaner` geographic checks; 10,426 distinct 5-arcminute climatic cells were used in the first Western Palaearctic pilot. The original source archive is identified by a checksum, download DOI and source-row links; it is obtained separately rather than bundled in this repository.

**Taxonomy and coordinate screening.** We audit occurrence status, taxonomic assignments, coordinate precision, spatial uncertainty and the test-specific `CoordinateCleaner` flags. Coordinate alerts near cities, institutions or coastlines are not assumed to prove location error. We separate one-per-climate-cell thinning from correction of sampling bias.

**Environmental data.** WorldClim v2.1 offers four initial bioclimatic predictors. Environmental correlation and multivariate redundancy are assessed relative to the calibration area. The western Palaearctic rectangle is the fixed operational calibration domain, not a biologically established accessible area.

**Observation process.** We consider the taxon-stratified GBIF sampling-effort products of El-Gabbas (2026), preferably cumulative `Opiliones` observation counts (`n_obs`) and with careful treatment of taxonomy, date, projection geometry and potential inclusion of the target species in the effort proxy. Uniform, effort-weighted and appropriately constructed target-group backgrounds are distinct analytical alternatives. The effort layer is not treated as ecological absence.

## Model

**Model comparison.** The completed evaluation evaluated six feature/regularization combinations (L, LQ and LQH; RM 1 and 2), with 10,426 presence cells, 10,000 uniform background cells and four spatial validation blocks in the fixed western Palaearctic operational rectangle. The run was completed with `ENMeval` 2.0.5 and `maxnet` 0.1.4.

**Accessible area and background.** For the fixed manuscript configuration, calibration background comprises 10,000 uniformly sampled climate-valid cells within the operational western Palaearctic rectangle. This rectangle is not claimed to represent a biogeographically demonstrated accessible area (M). Background weighting is analyzed separately from accessible-area delineation; any comparisons specify the sampling algorithm, random seed, transformation of effort counts and effective sample size.

**Tuning and selection.** We distinguish penalized likelihood fit (AICc), spatial discrimination (validation AUC), presence omission, model complexity and the continuous Boyce index. We avoid choosing a model based on the withheld Venezuelan field observations.

## Assessment

**Internal validation.** Our first latitudinal four-block analysis showed a pronounced fold-specific contrast: mean validation AUC across the six model settings ranged from approximately 0.622 to 0.661, with consistently weaker discrimination in the two central latitude bands. The number and environmental distribution of validation background cells varied substantially across folds. We interpret these as diagnostics of spatially heterogeneous discrimination, not a definitive identification of overfitting.

**Extrapolation.** An earlier full-grid minimum–maximum comparison identified 34,549 of 223,558 valid South American cells (15.454%) outside at least one range of the complete reference raster. The deposited sampled-reference MESS analysis instead identifies 158,611 negative-MESS cells among 223,558 valid cells (70.9485%). These are different diagnostics with different environmental references, not interchangeable estimates. Neither proportion is corrected for geographic cell area or indicates biological absence.

**Independent field evidence.** Seven events from the Venezuelan Andes correspond to six geographic coordinate pairs and three confirmed 5-arcminute climatic cells. These are not used to calibrate, tune, choose thresholds or rank models. Any later field-based assessment is limited by the geographic clustering and low number of independent climatic cells. The public deposit summarizes the three climatic cells; coordinate-bearing event records are excluded from the current branch.

## Prediction

**Output interpretation.** South American maps represent relative climatic suitability for the 1970–2000 climate baseline conditional on model settings, sampled occurrence environments, accessible calibration area and handling of extrapolation. The fixed clamped LQ/RM2 projection is the manuscript's reported model output; visually plausible patterns are not treated as validation.

**Transfer uncertainty.** Reporting distinguishes within-range transfer and extrapolation, clamp settings, alternative model and background configurations, resolution and data uncertainty. Suitability does not imply arrival, survival, reproduction, or demonstrated introduction.

**Reproducibility.** Code, model metrics, package versions, download DOI and explicit methodological choices are published in this repository. The raw source download and coordinate-bearing Venezuelan field occurrences remain separately managed. The source rasters and suitability/MESS figure are deposited; independent end-to-end reproduction has not been verified. Model artefacts are reported as completed results only when the analyses have actually run.

## References

- Zurell D, Franklin J, König C, et al. (2020) A standard protocol for reporting species distribution models. *Ecography* 43: 1261–1277. https://doi.org/10.1111/ecog.04960.
- El-Gabbas A (2026) A global, taxon-stratified, high-resolution sampling-effort dataset from GBIF for bias-aware ecological modelling. *Diversity and Distributions* 32: e70205. https://doi.org/10.1111/ddi.70205.
