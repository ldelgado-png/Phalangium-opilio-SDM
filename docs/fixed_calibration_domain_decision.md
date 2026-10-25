# Fixed operational calibration domain

The manuscript submitted to **Biotropica** uses the western Palaearctic rectangle **12°W–60°E, 30°–72°N** as its fixed calibration and background domain. The recorded geographical decision dates to 18 October 2026. Boundary geometry and model settings are recorded in [study_calibration_domain_fixed.json](study_calibration_domain_fixed.json).

This operational environmental reference is distinct from a historically demonstrated accessible area (*M*). It omits eastern Eurasia and may include climates or regions not historically accessible to the species. Its limits were not optimized against the withheld Venezuelan observations.

## Fixed analysis

- 10,426 screened presence cells and 10,000 uniformly sampled background cells.
- WorldClim 2.1 BIO1, BIO4, BIO12 and BIO15, at 5 arcminutes.
- Six maxnet configurations: L, LQ and LQH features with regularization multipliers 1 and 2.
- Four latitudinal validation blocks, with fold-specific background partitions.
- Prespecified LQ/RM2 South American projection, cloglog output and clamping.
- MESS/MOP reference: 5,000 sampled complete climates, seed 251018; nearest 1% for continuous MOP.

The six configurations have mean validation AUC 0.622–0.661. LQ/RM2 is the fixed projection configuration; it is not the minimum-AICc configuration. The [raw evaluation table](../results/initial_spatial_block_ENMeval.csv) preserves all six settings.

## Transfer assessment

Seven Venezuelan collection events correspond to three climatic cells. The [public three-cell results](../results/venezuela_transfer_cells_public.csv) give cloglog suitability 0.558–0.617, MESS −18.727 to −18.375 and continuous MOP distance 2.028–2.458. BIO4 is the limiting predictor below the sampled reference range. These are descriptive transfer diagnostics under non-analog conditions.

The combined map displays suitability (A) and MESS sign (B); MOP is reported numerically. Historical figure numbers in source filenames are identifiers of archived exports, not a prescribed manuscript sequence.

## Supporting diagnostics

Background buffers and sampling-effort analyses document dependence on environmental availability and the observation process. They did not replace the fixed uniform-background fit. The target-group preparation scripts and optional BIO4/clamping refits do not establish new manuscript results without execution and assessment.

The natural-history evidence supports the occurrence record. Climatic projections provide conditional environmental context and survey hypotheses; they do not demonstrate niche conservatism, predict spread or establish ecological impacts. See the [reviewer guide](REVIEWER_GUIDE.md) for the public reproduction route and separately managed field inputs.
