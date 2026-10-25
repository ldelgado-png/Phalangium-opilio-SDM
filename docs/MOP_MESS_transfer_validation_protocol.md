# Environmental transfer diagnostics: MESS and MOP

This document describes the fixed environmental-transfer assessment accompanying the *Phalangium opilio* manuscript submitted to *Biotropica*. Earlier development-stage instructions are retained in the Git commit history, not as outstanding manuscript tasks.

## Calibration and projection

The operational calibration domain is the western Palaearctic rectangle (12°W–60°E, 30°–72°N). It is a documented modelling domain, **not** a biogeographically demonstrated accessible area (*M*). The fitted manuscript projection uses WorldClim 2.1 BIO1, BIO4, BIO12 and BIO15 (5 arcminutes), 10,426 calibration presence cells, 10,000 uniformly sampled background cells, and the fixed maxnet LQ/RM2 configuration with cloglog output and clamping. Venezuelan field observations were excluded from model fitting, tuning and configuration selection.

## Environmental novelty and transfer

The [R25 script](../R/25_exploratory_MESS_MOP_south_america.R) uses 5,000 complete reference environmental cells sampled from the operational calibration rectangle with seed 251018. MESS identifies univariate departures from the sampled reference environments; negative values indicate that at least one predictor lies outside the sampled reference range. The limiting-variable raster identifies the variable responsible for the minimum MESS value.

Continuous MOP is the mean standardized Euclidean distance to the nearest 1% of the 5,000 reference environments (50 cells). Predictor standardization is based on reference-sample means and standard deviations. MOP is an environmental-distance measure, **not** a probability, model-performance metric or calibrated threshold for safe transfer.

The South American MESS summary reports 158,611 negative-MESS cells among 223,558 valid transfer cells (70.9485% of cells). This is a raster-cell percentage, **not** an equal-area estimate of affected land.

## Venezuelan observations

Seven collection events occupy three distinct 5-arcminute climatic cells. The [public coordinate-free summary](../results/venezuela_transfer_cells_public.csv) reports cloglog suitability of 0.558–0.617, MESS of −18.727 to −18.375, and continuous MOP distances of 2.028–2.458. BIO4 is the limiting MESS variable in all three cells. These observations provide geographically separate descriptive transfer evidence but do not constitute an unbiased area-wide validation of predictive performance.

The [R26 script](../R/26_venezuela_transfer_diagnostics_v3.R) extracts values at the independent Venezuelan coordinates without resampling. Its coordinate-bearing input is separately managed and must be supplied explicitly through `options(phalangium.venezuela_sites_csv = "/absolute/path/to/private_field_records.csv")`. The [R27 plotting script](../R/27_figura2_idoneidad_MESS_JIS.R) reads the resulting local extraction for its location overlay. Both use ignored local work directories for coordinate-bearing outputs. The [reviewer guide](REVIEWER_GUIDE.md) distinguishes field re-extraction from the public checks and raster-context calculations, which require no field coordinates.

## Published outputs and manuscript figure

- [Relative climatic suitability GeoTIFF](../04_resultados_modelo/pilot_western_palaearctic/09_pilot_south_america_LQ_rm2_cloglog_NOT_FINAL.tif)
- [MESS GeoTIFF](../04_resultados_modelo/pilot_western_palaearctic/transfer_novelty_EXPLORATORY_NOT_FINAL/27_sa_MESS_5m_EXPLORATORY.tif)
- [MESS limiting-variable GeoTIFF](../04_resultados_modelo/pilot_western_palaearctic/transfer_novelty_EXPLORATORY_NOT_FINAL/28_sa_MESS_limiting_variable_5m_EXPLORATORY.tif)
- [MOP GeoTIFF](../04_resultados_modelo/pilot_western_palaearctic/transfer_novelty_EXPLORATORY_NOT_FINAL/29_sa_MOP_nearest1pct_distance_5m_EXPLORATORY.tif)
- [Archived suitability/MESS figure (PNG)](../figures/Figure_3_Suitability_MESS_JIS.png), [PDF](../figures/Figure_3_Suitability_MESS_JIS.pdf), [600-dpi TIFF](../figures/Figure_3_Suitability_MESS_JIS_600dpi.tif)

Panel A presents relative climatic suitability and panel B presents MESS sign. MOP is reported numerically. Historical filenames containing `pilot`, `EXPLORATORY`, `NOT_FINAL` or `figura2` are preserved to maintain file provenance and existing script references; they do not denote a second manuscript model.

## Interpretation and limitations

Projected climatic suitability must not be interpreted as occurrence probability, establishment, dispersal or realized invasion risk. Negative MESS at the Venezuelan cells demonstrates univariate environmental extrapolation relative to the sampled reference, and warrants caution when interpreting otherwise positive suitability scores. The clustered occurrence data and operational, rather than independently demonstrated, calibration domain constrain inference. No post hoc MOP cutoff or model re-selection was introduced after examining Venezuelan sites.

Additional details are given in the [transfer results](manuscript_transfer_status_2026-10-19.md) and [ODMAP documentation](ODMAP_reporting_framework.md).
