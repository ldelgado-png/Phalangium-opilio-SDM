# Taxon-stratified sampling effort in *Phalangium opilio* distribution modelling

## Rationale and evidence

We distinguish the biological distribution of *Phalangium opilio* from spatially heterogeneous observation processes in the Global Biodiversity Information Facility (GBIF). Our initial presence–background maxnet pilot used 10,426 unique Western Palaearctic climatic cells and a random background of 10,000 cells. Spatial four-fold validation yielded marked geographic differences in model discrimination, making a direct assessment of taxon-specific sampling effort particularly relevant.

El-Gabbas (2026) provides global, taxon-stratified sampling-effort raster products derived from GBIF, including descendant-order products for **Opiliones** within Arachnida. The archive includes observation counts (`n_obs`) and recorded species richness (`n_sp`) at approximately 1, 5, 10 and 20 km, with annual and cumulative time slices spanning 1980–2025. These values measure *GBIF-accessible sampling outcomes*, not ecological absence, detection probability, or a perfect measure of field effort.

- Primary effort proxy: `group = "arachnida"`, `descendants = "opiliones"`, `metric = "n_obs"`, `years = "total"`, `resolution = 5`.
- Broader comparison proxy: sampling effort for all Arachnida, applied only with explicit acknowledgement that different arachnid orders may have different detection and reporting processes.
- Recorded species richness (`n_sp`) is an independent diagnostic for taxonomic coverage and should not be conflated with the number of visits or species detections.

Archived products can be accessed via the author-maintained R package `ecokit`:

```r
effort <- ecokit::get_sampling_effort(
  group = "arachnida",
  descendants = "opiliones",
  metric = "n_obs",
  years = "total",
  resolution = 5,
  out_dir = "01_datos/sampling_effort"
)
terra::rast(effort$local_path[1])
```

The original output grid is geographic WGS84 and stores raw counts. Its nominal ~5-km grain differs from WorldClim's 5-arcminute climate grid: direct cell-for-cell indexing would therefore be incorrect. The effort layer must be checked for spatial reference system, actual cell geometry, temporal coverage, missing values and zero-count cells before any area or grid transformation. Latitude-dependent pixel areas also affect interpretation of raw observation counts.

## Observed order-level effort coverage

We aligned the cumulative Opiliones observation-count product from El-Gabbas (2026) to the original 5-arcminute Western Palaearctic climate grid for a descriptive coverage assessment. Positive values appeared in **24,343 of 292,489 (8.32%)** climate-valid grid cells, and **9,693 of 10,426 (92.97%)** screened calibration-presence cells. Another **733** presence cells had zero values. No cells had missing effort values after alignment.

These observed figures demonstrate that the GBIF Opiliones record layer provides strongly heterogeneous spatial coverage. They do not establish the actual sampling effort at every location, identify true absences, or determine whether the focal species contributes disproportionately to the order-level dataset. Strict positive-count weighting would entirely exclude more than 90% of climate-valid reference cells from the background proposal, including climatic cells containing 733 accepted focal-species presences. The suitability of a bias-weighted background therefore depends on a justified calibration domain (M), treatment of zero-count cells, spatially explicit support, and the concentration of sampling probabilities.

We use `R/16_effort_weighting_feasibility.R` to assess candidate weighting concentration, effective candidate-cell support and latitude-fold allocation for the exploratory rectangular, 250-km and 500-km background domains. These alternative domains are geographical sensitivity analyses, not M definitions. No weighted ENMeval models or validated performance improvements are reported on the basis of this preparation stage.

## Observed feasibility of alternative effort weights

The completed `R/16_effort_weighting_feasibility.R` audit provides an independent check of weighting concentration using the original screened presences and climatic background. Only **506 of the 10,000 uniformly sampled pilot background cells (5.06%)** had positive Opiliones effort. In the exploratory rectangular domain, after excluding the 10,426 presence pixels, **14,650 of 282,063 candidate background cells (5.19%)** had positive effort. Under weights proportional to untransformed `n_obs`, Kish's effective candidate-cell count was **631.6 (0.22%)**, with **74.27%** of weight mass carried by the top 1% of cells. The square-root and `log1p(n_obs)` transformations increased effective counts to **8,398.5 (2.98%)** and **7,567.9 (2.68%)**, respectively; `1 + log1p(n_obs)` retained **273,854.1 effective cells (97.09%)** and moved closer to uniform weights. The untransformed weights shifted the four-fold background mass from **39.33, 12.42, 8.82 and 39.43%** (uniform) to **11.86, 13.74, 26.02 and 48.38%**, respectively. These statistics describe candidate probability distributions, not sampled background realizations or model performance. The 250-km and 500-km domains remain geographic sensitivity masks rather than accessible-area definitions.

We use `R/18_effort_spatial_climatic_support.R` to characterize the observational support and univariate climatic representation of cells with positive Opiliones counts across the pre-existing latitude folds and the same three geographic sensitivity domains. Because the underlying GBIF product can contain `P. opilio` observations, the contrast between focal presences and available effort is not an estimate of detection probability or an independent bias-correction assessment.

## Observed spatial and environmental support

Using the original four spatial blocks, we found positive Opiliones effort at **92.87%, 92.90%, 92.67%, and 93.44%** of pilot presences, respectively, but only **2.91%, 8.54%, 10.83%, and 5.15%** of eligible candidate background cells in the initial exploratory rectangle (`R/18_effort_spatial_climatic_support.R`). Among all candidate background cells, **4.40%** fell outside the BIO1 range of the effort-positive subset, **2.81%** outside BIO4, **8.31%** outside BIO12, and **0.14%** outside BIO15. All 10,426 calibration presences remained within those separate univariate ranges. These are descriptive coverage diagnostics; they cannot establish multivariate environmental representativeness or whether a bias correction improves model transfer.

We use `R/19_target_group_GBIF_count_feasibility.R` only to assess the availability of live GBIF Opiliones records besides the focal species in the exploratory geographical window and its four original spatial blocks. Current GBIF counts differ in provenance and filtering from the El-Gabbas effort raster and do not constitute a verified target-group background. Any actual target-group background will require a separately citable GBIF download, removal of `P. opilio`, taxonomic and coordinate screening, spatial thinning, and a biogeographically justified common M.

## Observed availability of independent target-group records

The `R/19_target_group_GBIF_count_feasibility.R` preflight was completed using live GBIF occurrence counts (1980–2025, coordinates available and occurrence status present) in the historical western Palaearctic exploratory rectangle. Of **313,521 Opiliones records**, **43,449 (13.858%)** were attributed to `Phalangium opilio`; a preliminary **270,072-record difference** concerns other taxa. The four latitudinal folds had **33,565**, **33,720**, **117,055**, and **85,732** non-focal records, respectively. The complete output is archived in `results/gbif_target_group_count_feasibility.csv`. This count difference establishes that the order-level data pool is sizeable, but it does not quantify independent collection effort, valid target-group taxa, vetted background localities, or unique predictor-grid cells.

The exploratory rectangle is **not** an independently justified accessible area (M). Sampling effort can be taxonomically and spatially heterogeneous even after exclusion of the focal species. `R/20_prepare_target_group_download.R` constructs and saves a traceable GBIF download predicate combining Opiliones and explicit exclusion of the focal species under the GBIF Backbone checklist. The default is a **dry run** with no automatic data retrieval. A request for the separately citable occurrence download requires a deliberate local opt-in; credentials should be handled through the user's local environment. The acquired data, if requested, still require independent quality control, verification of comparable collection processes, duplicate and climatic-cell screening, and restriction to a justified M. No modelling or independent Venezuelan evaluation follows automatically from this availability result.

## Bias-aware modelling comparisons

The methodological comparison is designed to distinguish three concepts:

1. **Uniform-background reference** — sample background cells within the same explicitly justified accessible calibration area (M) without observation-effort weights.
2. **Sampling-effort-weighted background** — sample background locations in that *same* M proportional to a clearly documented, positive transformation of the Opiliones observation-count surface. Record the transformation, spatial aggregation/interpolation method, support of zeros, seed and number of sampled background cells.
3. **Target-group background** — when records are sufficiently available, draw background from other Opiliones occurrences that plausibly share the focal species' observation process, excluding records of *P. opilio*. Define and audit this target-group data set independently of the focal species sample.

Comparisons need the same predictor set, a justified accessible area, and explicit evaluation partitions. We preserve spatially structured evaluation and report the performance and spatial predictions of each bias-treatment scenario. Apparent improvements are not proof that bias is removed.

### Interpretation safeguards

The published Opiliones count raster can include *P. opilio* itself; where this species makes up a substantial share of records, an order-level effort surface could be partly endogenous to the response. We therefore examine this possibility and avoid presenting the order-level raster as an independent measure of observation effort without qualification. We also distinguish observational intensity from taxonomic richness, environmental accessibility and confirmed species absence.

The cumulative 1980–2025 effort layer and the 1970–2000 WorldClim climatic normals cover different periods, and the focal GBIF occurrence snapshot was downloaded in 2026. These time windows require explicit reporting and, where possible, temporal sensitivity assessment. Sampling effort is used to structure calibration background only within M; it is not included as an explanatory climatic predictor in the South American transfer surface.

Known Venezuelan field localities remain independent: they are excluded from predictor selection, model tuning, background weighting, model selection and training-derived threshold definition. Their role is limited to evaluation of the completed transfer predictions.

## Reporting standard

We organize the final species distribution modelling report according to ODMAP (Overview, Data, Model, Assessment, Prediction; Zurell et al. 2020), with full citations and documented processing decisions. The archived bias products, version of `ecokit`, selected effort raster, taxonomic filter, spatial resolution, temporal aggregation, weighting transformation and sampling seed belong in the model's reproducibility metadata.

## References

- El-Gabbas A (2026) A global, taxon-stratified, high-resolution sampling-effort dataset from GBIF for bias-aware ecological modelling. *Diversity and Distributions* 32: e70205. https://doi.org/10.1111/ddi.70205. Dataset: https://doi.org/10.5281/zenodo.17591681; associated software: https://github.com/elgabbas/ecokit.
- Zurell D et al. (2020) A standard protocol for reporting species distribution models. *Ecography* 43: 1261–1277. https://doi.org/10.1111/ecog.04960.
