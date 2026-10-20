# *Phalangium opilio* in South America: climatic suitability and environmental transfer

Reproducible data, code, model diagnostics and figures supporting the manuscript on the first documented Venezuelan records of *Phalangium opilio* (Opiliones: Phalangiidae), prepared for *Journal of Insect Science*.

## Study scope

The occurrence records from the Venezuelan Andes document the species' presence in South America. Climatic modelling provides complementary environmental context; it does not independently demonstrate establishment, predict dispersal or quantify invasion risk. The Venezuelan observations were excluded from model calibration, tuning and model selection.

## Occurrence data and environmental predictors

The GBIF source download comprises 63,407 records from 506 publishing datasets: [GBIF occurrence download, DOI:10.15468/dl.9gn3qv](https://doi.org/10.15468/dl.9gn3qv). Record-level taxonomic, occurrence-status, coordinate and uncertainty screening is implemented in the archived R workflows. CoordinateCleaner flags are treated as indications for review, not automatic proof of erroneous georeferencing. One presence per climate cell was retained for calibration.

Environmental predictors are WorldClim 2.1 BIO1, BIO4, BIO12 and BIO15 at 5-arcminute resolution, representing the 1970–2000 baseline. The fixed **operational calibration domain** is 12°W–60°E, 30°–72°N in the western Palaearctic. This geographic rectangle is not claimed to represent a biogeographically demonstrated accessible area (*M*). The projection region is South America.

## Model calibration and assessment

The completed analysis used 10,426 calibration presence cells and 10,000 uniformly sampled background cells. Six `maxnet` configurations (L, LQ and LQH feature classes, each with regularization multipliers 1 and 2) were evaluated using four spatial blocks in `ENMeval`. Mean validation AUC ranged from 0.622 to 0.661 across configurations, with substantial between-fold variation. The manuscript uses the **fixed LQ/RM2** model, projected with **clamping** and **cloglog** output. This configuration was not selected using the Venezuelan observations.

The use of a uniform background, the operational calibration rectangle and the spatial heterogeneity of validation results limit inference. Alternative background and effort diagnostics are retained as sensitivity documentation; they do not replace the fixed manuscript model.

## Environmental transfer: MESS and MOP

The MESS/MOP reference comprises 5,000 sampled climate-valid cells from the operational calibration rectangle (random seed 251018). MESS identifies univariate environmental departures from the sampled reference. Continuous MOP measures mean standardized Euclidean distance to the nearest 1% (50 cells) of reference climates; it is not a calibrated transfer threshold.

Seven Venezuelan collection events correspond to three climatic cells. The [coordinate-free results](results/venezuela_transfer_cells_public.csv) report cloglog suitability of 0.558–0.617, MESS of −18.727 to −18.375, and continuous MOP distances of 2.028–2.458; BIO4 is the limiting MESS predictor at all three cells. The full-area diagnostic reports 158,611 MESS-negative cells among 223,558 valid South American raster cells (70.9485% of cells, not equal-area land). Negative MESS indicates extrapolation, so predicted suitability at these sites must be interpreted cautiously.

The Venezuelan records provide geographically separate, spatially clustered descriptive evidence; three climate cells do not support a representative area-wide model-validation claim.

## Reproducibility and repository contents

| Material | Repository location |
| --- | --- |
| Coordinate-quality entry point | [R/00_start_coordinatecleaner.R](R/00_start_coordinatecleaner.R) |
| Model calibration and evaluation | [R/11_pilot_ENMeval_maxnet.R](R/11_pilot_ENMeval_maxnet.R), [evaluation table](results/initial_spatial_block_ENMeval.csv) |
| Environmental novelty analysis | [R/25_exploratory_MESS_MOP_south_america.R](R/25_exploratory_MESS_MOP_south_america.R) |
| Venezuelan site extraction | [R/26_venezuela_transfer_diagnostics_v3.R](R/26_venezuela_transfer_diagnostics_v3.R) |
| Two-panel figure generation | [R/27_figura2_idoneidad_MESS_JIS.R](R/27_figura2_idoneidad_MESS_JIS.R) |
| Public transfer results | [Three-cell CSV](results/venezuela_transfer_cells_public.csv), [reference parameters](results/26_reference_environment_parameters.csv), [summary](results/27_venezuela_transfer_summary.csv) |
| Source GeoTIFFs | [Suitability](04_resultados_modelo/pilot_western_palaearctic/09_pilot_south_america_LQ_rm2_cloglog_NOT_FINAL.tif), [MESS](04_resultados_modelo/pilot_western_palaearctic/transfer_novelty_EXPLORATORY_NOT_FINAL/27_sa_MESS_5m_EXPLORATORY.tif), [limiting predictor](04_resultados_modelo/pilot_western_palaearctic/transfer_novelty_EXPLORATORY_NOT_FINAL/28_sa_MESS_limiting_variable_5m_EXPLORATORY.tif), [MOP](04_resultados_modelo/pilot_western_palaearctic/transfer_novelty_EXPLORATORY_NOT_FINAL/29_sa_MOP_nearest1pct_distance_5m_EXPLORATORY.tif) |
| Manuscript Figure 3 | [PNG](figures/Figure_3_Suitability_MESS_JIS.png), [PDF](figures/Figure_3_Suitability_MESS_JIS.pdf), [TIFF, 600 dpi](figures/Figure_3_Suitability_MESS_JIS_600dpi.tif) |
| Methods and reporting | [Transfer diagnostics](docs/MOP_MESS_transfer_validation_protocol.md), [numerical results](docs/manuscript_transfer_status_2026-10-19.md), [ODMAP](docs/ODMAP_reporting_framework.md) |

The manuscript figure sequence is **Figure 1: habitats; Figure 2: geographical distribution; Figure 3: climatic suitability (A) and MESS sign (B); Figure 4: specimens**. MOP is reported in the text and tabular results, not as a panel in Figure 3.

Historical script and raster filenames containing `pilot`, `EXPLORATORY`, `NOT_FINAL` or `figura2` are retained for provenance and path compatibility. They do not imply a different selected model or a pending analysis.

**Reproducibility boundary.** The published code, source rasters, figures and coordinate-free summaries support inspection and reuse of the reported analysis. R26 and the complete R27 site overlay require an unpublished coordinate-bearing Venezuelan input table. This table is deliberately withheld; independent end-to-end re-execution has not been verified. The public cell summary is not a substitute for those original coordinates.

## Citation and scientific interpretation

When reusing the occurrence data, cite [GBIF.org (2026), DOI:10.15468/dl.9gn3qv](https://doi.org/10.15468/dl.9gn3qv), alongside the manuscript and any relevant software or environmental-data sources. The distinction between modelled climatic suitability and observed occurrence, and between operational calibration geography and biogeographical accessibility, should be preserved in derivative analyses.
