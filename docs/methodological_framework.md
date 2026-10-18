# Methodological framework

## Study aim

We examine the potential climatic suitability of *Phalangium opilio* in South America in the context of its confirmed occurrence in the Venezuelan Andes. Our inference concerns environmental suitability, not observed occupancy, introduction probability, propagule pressure, or direct ecological impact.

## Data origin and independent field evidence

The GBIF snapshot contains 63,407 records contributed by 506 publishing datasets. Our initial source audit identified no records attributed to South American countries **within this specific download**. We therefore distinguish GBIF calibration records from the independently documented Venezuelan collection localities. This observation about one snapshot must not be interpreted as a general absence of GBIF records from South America.

The manuscript describes seven collection events from Mérida, represented by six coordinate pairs and approximately three 5-arcminute climatic grid cells. Because these sites are geographically clustered, they do not constitute a robust continent-wide independent validation sample.

## Occurrence screening

We screen species assignments, occurrence status, coordinate plausibility, reported uncertainty and source quality flags. We use `CoordinateCleaner` to flag locations associated with capitals, centroids, institutions, GBIF facilities, coordinates at sea, zero coordinates and identical longitude–latitude pairs. We retain test-specific flags for review instead of treating every alert as a confirmed error.

We treat cell-level spatial thinning and sampling-bias correction as distinct operations. In particular, retaining one occurrence per environmental cell does not resolve uneven sampling effort across geographical space.

## Eastward environmental coverage

We contrasted the climatic characteristics of records east of 60°E with the minimum–maximum ranges calculated over the complete environmental raster of the exploratory Western Palaearctic window. We retained 95 screened occurrences in 68 unique 5-arcminute climatic cells (Russia: 60 cells; Japan: 6; Kazakhstan: 2). Three Russian cells (4.41% of eastern cells) exceeded the upper range of BIO4; none exceeded the univariate ranges of BIO1, BIO12, or BIO15. The Western Palaearctic raster-wide BIO4 maximum was 1,488.34 and the eastern-record maximum was 1,875.19 (native WorldClim scale). 

All three outside-range cell representatives derive from iNaturalist human observations. The original GBIF fields report no detailed locality text in the selected occurrence subset; geographic uncertainty is 3 m (Gorno-Altay), 2,117 m (Sakha) or unreported (Sakha). Each carries the source-data issue `TAXON_ID_NOT_FOUND`, which cannot alone be used to infer misidentification. The source-record metadata are retrieved by `gbifID` in `R/10_eastern_outlier_source_review.R`, maintaining an auditable distinction between coordinate-screening flags and taxonomic verification. We interpret these univariate comparisons as descriptive range diagnostics rather than evidence of environmental equivalence. The absence of single-variable range exceedance does not rule out novel combinations of predictors. We maintain separate analytical treatment of eastern Eurasian records until geographic provenance, historical range evidence, and the accessible calibration area are evaluated. Field observations from Venezuela are excluded from calibration, tuning, and scenario selection.

## Climate variables and model evaluation

We formulate the R workflow using `terra`, `ENMeval`, and `maxnet`. Our baseline climatic predictors are WorldClim 2.1 BIO1 (annual mean temperature), BIO4 (temperature seasonality), BIO12 (annual precipitation), and BIO15 (precipitation seasonality), at 5-arcminute resolution.

We distinguish the biogeographically justified accessible area used for calibration from the South American projection region. Spatially structured evaluation and model-complexity selection provide a basis for comparing candidate configurations. We interpret climatic extrapolation and nonanalog environments explicitly when assessing transfers outside the calibration region.

## First spatial-block model assessment

We completed an initial, exploratory calibration with `ENMeval` 2.0.5 and `maxnet` 0.1.4, using 10,426 screened presence cells and 10,000 background cells from the Western Palaearctic reference rectangle. Candidate settings combined feature classes L, LQ, and LQH with regularization multipliers of 1 or 2 (six configurations), evaluated under four spatial blocks (`lat_lat` orientation). `validation.bg = "partition"` was used to compare withheld presences against each spatial fold's background. We calculated validation AUC, CBI, tenth-percentile omission, AICc, and the number of nonzero model coefficients.

The lowest AICc occurred for LQH/RM 1 (33 coefficients, mean validation AUC 0.661, mean CBI 0.490, omission 0.110), while LQH/RM 2 yielded the highest mean CBI (0.542; 21 coefficients), and LQ/RM 2 had the lowest tenth-percentile omission (0.084; 4 coefficients). For the LQH/RM 1 configuration, validation AUC standard deviation across folds was 0.228 and validation CBI standard deviation was 0.576. We interpret the marked fold-to-fold variation as evidence of spatial instability in model evaluation, without assigning a unique causal explanation before inspecting block-level results. All summary statistics are traceable to the raw `results/initial_spatial_block_ENMeval.csv`.

A South American exploratory suitability raster was produced from an a priori LQ/RM 2 configuration with clamped predictors. We do not use its visual agreement or disagreement with the known Venezuelan sites for model development: the field occurrences are reserved exclusively for independent transfer assessment. Moreover, the pilot rectangle is not a biogeographically defended accessible area (M); the full model strategy will distinguish calibration-area definition and background-sampling decisions from the fitting algorithm.

## Diagnostic of fold-specific predictive performance

The initial four spatial partitions each held out approximately 2,606 presence cells (2,607, 2,606, 2,607, 2,606), but the validation background counts were 4,947, 1,309, 828 and 2,916. For LQH/RM 1, withheld AUC across folds was 0.9067, 0.4695, 0.4633 and 0.8025; the corresponding CBI scores were 0.996, 0.061, −0.075 and 0.976. Fold 4 had high tenth-percentile omission (0.3104). All six parameter settings showed AUC below 0.5 in folds 2 and 3. This variation is robust to the limited feature-class and regularization settings we evaluated.

The original `block` algorithm builds spatial groups from presence-derived coordinate cutoffs and allocates background cells spatially; equal numbers of presences therefore do not imply balanced numbers of background cells. As evaluation used `validation.bg = "partition"`, discrimination statistics depend on each fold's own geographic and environmental background. We examined the geography and climate of the saved partitions with `R/13_diagnose_spatial_cv_domains.R`: the percentages of held-out presences with at least one predictor beyond the full observed range of the other three folds were 27.00%, 0.27%, 0.08% and 0.96% in folds 1–4. The weakest-performing folds, 2 and 3, thus showed little univariate novelty, and their median presence latitude was within 0.1° of the corresponding background median. Folds 1 and 4 showed much greater separation of presence and background median latitude (6.09° and −3.52°, respectively). This establishes neither a causal explanation for AUC variation nor evidence of niche equivalence, but indicates that background geography warrants sensitivity analysis. The reproducible `R/14_candidate_background_extent_diagnostics.R` compares fold-specific environmental availability in hypothetical 250 and 500 km neighbourhoods of screened occurrences, without refitting models. Such spatially buffered candidate regions are not asserted to be the accessible area (M). The exploratory background rectangle remains distinct from a defended accessible calibration area (M).

## Sampling effort and reproducible SDM reporting

The initial ENMeval/maxnet pilot was fitted with uniformly sampled background cells inside an exploratory Western Palaearctic rectangle. We do not interpret that background design as accounting for the uneven sampling process of GBIF records. The framework of El-Gabbas (2026) provides observation-count (`n_obs`) and recorded-richness (`n_sp`) rasters for the order Opiliones, as well as broader Arachnida layers, at four spatial resolutions and multiple temporal aggregations. We distinguish these proxies from species absences and direct detection probabilities. We evaluate the potential influence of taxonomic composition, inclusion of *P. opilio* in the effort surface, spatial grain, unequal cell areas and temporal coverage when using these products.

The comparative study design separates a uniform background, a background weighted according to Opiliones sampling effort and a target-group background assembled from comparable Opiliones observations excluding the focal species. All comparisons require the same biogeographically justified accessible area, comparable spatial validation and documented background sample sizes. The published `R/15_prepare_opiliones_effort.R` script provides a stand-alone audit of observation-effort coverage prior to implementing the alternative backgrounds; it does not fit or rank models. The detailed background design is described in `docs/sampling_effort_protocol.md`.

We use the ODMAP framework of Zurell et al. (2020) to communicate five components: Overview, Data, Model, Assessment, and Prediction. Study scope, occurrence screening, climate data, accessible area, bias correction, algorithms, partitioning, model diagnostics, extrapolation and transfer uncertainty are documented in `docs/ODMAP_reporting_framework.md`. Independent Venezuelan observations are withheld from all calibration-stage methodological choices.

## Interpretation and reproducibility

We express model output as **relative climatic suitability**, not calibrated occurrence probability or a forecast of realized geographical spread. We report quantitative model performance and mapped predictions only when they are supported by completed, reproducible analyses with traceable input data and evaluation settings.
