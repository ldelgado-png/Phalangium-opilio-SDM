# Fixed operational calibration domain — manuscript decision (18 October 2026)

**Scope of the decision.** The authors choose to **fix** the historical **Western Palaearctic geographic rectangle (12°W–60°E, 30°–72°N)** as the **operational calibration and background domain** for the current *Biotropica* Natural History Field Note. It is held constant for reported pilot results and future MESS/MOP novelty maps. This is a pragmatic, transparent, reproducible **study-design decision**, not a claim that the rectangle has been demonstrated to equal the species' historically accessible area (*M*). The analysis must not use the phrase "biogeographically proven M" or imply that all of the native range or accessible environments are covered.

The frozen boundary geometry is `POLYGON((-12 30,60 30,60 72,-12 72,-12 30))` (EPSG:4326). Its coordinates are reproducible in [`docs/study_calibration_domain_fixed.json`](study_calibration_domain_fixed.json). Because this broad rectangle may include environmentally suitable but historically inaccessible regions and omits parts of eastern Eurasia, domain dependence remains an explicitly acknowledged limitation. The decision should be reported *a priori relative to inspection of the held-out Venezuelan field localities*, not falsely presented as a historical proof of accessibility.

## Archived analyses already supported within the chosen domain

- 10,426 screened, unique 5-arcminute *P. opilio* presence cells.
- 10,000 uniformly sampled background cells (not bias-corrected) from the same climatic study window.
- WorldClim 2.1, 5 arcminutes: BIO1, BIO4, BIO12 and BIO15.
- Six `maxnet` feature/regularization combinations (L, LQ, LQH × regularization multipliers 1, 2), evaluated with four spatially structured latitudinal folds.
- Observed mean validation AUC range **0.622–0.661**, with high fold-to-fold variability. Existing fold-specific results and maps remain unchanged. The LQ/RM2 cloglog/clamped South American prediction was chosen before consulting field site data as the **prespecified descriptive transfer illustration**, not the top-AICc or universally best model.

**Decision explicitly does not imply a completed fit, new evaluation, effective observer-bias correction, or an independent Venezuelan test.** The prior comparative buffer and effort-bias analyses remain exploratory *sensitivity* results, not selected alternative domains for this manuscript. The alternative GBIF target-group background download has not yet been curated; do not present it as a completed fit or an input to the archived baseline.

## Publication positioning

The central result of the **Natural History Field Note** is the independently observed first record and natural-history evidence of *P. opilio* in the Venezuelan Andes. The climatic model is a clearly labelled **secondary, hypothesis-generating illustration**, not the principal basis for the record, and its published assessment must acknowledge moderate/variable spatial discrimination and possible bias from background sampling. A fixed geographical domain improves documentation and reproducibility; it does **not** make this moderate-performing model more accurate or validated.

- **Methods:** provide exact fixed-domain coordinates, presence and uniform background counts, 4 WorldClim variables, ENMeval settings, model-selection description, withheld-field-site protocol, and explicitly say the rectangle is not a demonstrated M.
- **Results:** retain only executed quantitative results (including AUC range and the already produced LQ/RM2 map).
- **Discussion/Figure 4:** describe South American suitability as *conditional on this operational rectangle* and on clamped transfer, not as occurrence, spread, or occupancy. Figure 2 documents habitat photographs; climatic suitability is Figure 4.
- **Novelty assessment:** run `R/25_exploratory_MESS_MOP_south_america.R` with this **fixed operational domain**; do not invent novelty percentages or maps. If MOP/MESS values are executed and quality-checked, add a properly labelled Figure 4 companion panel or supplement. Until then, retain the disclaimer that non-analog climate exposure has not been quantified.
- **External locality assessment:** the seven Venezuelan collection events are withheld from all model design, range definition and novelty decisions. **After final freeze only**, extract cloglog suitability and novelty measures by unique coordinates and distinct predictor-grid cells, reporting clustering and limited independent evidential weight. The existing manuscript records seven events, six coordinates and approximately three 5′ cells.

## Remaining submission gates

The user has approved the **fixed geographical limits**, not retroactive fabrication of model-selection robustness or transfer validation. Minimal readiness checks are: successfully execute/check MESS/MOP if the manuscript will claim novelty results; decide whether to retain the secondary model as exploratory or conduct a clearly specified uniform-vs-effort background sensitivity refit (an uncurated target-group alternative cannot be claimed); verify figure/raster provenance and citations; confirm Biotropica limits. Do not reopen the geographic rectangle to optimize agreement with Venezuelan sites.

**Decision adopted:** fixed operational domain. **M biogeographical equivalence:** not established. **New results:** none generated by documenting this decision.
