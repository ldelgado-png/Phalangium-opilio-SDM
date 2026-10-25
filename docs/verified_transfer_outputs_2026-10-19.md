# Verified local transfer outputs — 19 October 2026

The author-supplied archive `Phalangium_opilio_GitHub_final.zip` contains the original site extraction table `26_venezuela_site_transfer_values.csv`, summary `27_venezuela_transfer_summary.csv`, scripts `26_venezuela_transfer_diagnostics_v3.R` and `27_figura2_idoneidad_MESS_JIS.R`, and the raster products for suitability, MESS, and MOP. The source files were inspected on 19 October 2026; this does not imply that the scripts were independently re-executed.

The public, coordinate-free aggregation is [venezuela_transfer_cells_public.csv](../results/venezuela_transfer_cells_public.csv). Seven collection events occupy three 5-arcminute cells (5, 1, and 1 events). Clamped LQ/RM2 cloglog suitability ranges from 0.558121 to 0.616830. All three cells have negative MESS (-18.727 to -18.375) and BIO4 as the limiting predictor. The MOP nearest-1%-reference distances are 2.028277, 2.225173 and 2.457742, respectively. These distances are continuous environmental dissimilarity metrics, **not** a calibrated threshold, probability, or independent validation of the model.

The supplied full-area diagnostic summary reports 158,611 MESS-negative cells among 223,558 valid South American transfer cells (70.9485% **of cells, not land area**). MESS used 5,000 sampled reference cells, seed 251018, WorldClim 2.1 BIO1, BIO4, BIO12 and BIO15; MOP used the mean standardized Euclidean distance to the nearest 1% (50) reference samples, cross-checked with maximum absolute difference 0 in the reported local audit. The calibration rectangle (12°W–60°E, 30°–72°N) is an operational domain, **not a demonstrated accessible area M**.

The original source files retain historical labels such as `EXPLORATORY` and `NOT_FINAL`. These labels describe the filenames and historical workflow, not an alternative model selected after inspection of the Venezuelan records. The archived combined suitability/MESS exports retain historical figure numbers; manuscript numbering follows the submitted version.

## Reproducibility boundary

The source suitability, MESS, MOP and limiting-variable GeoTIFFs, the exact R26/R27 scripts, and the suitability/MESS exports (PNG, PDF and 600-dpi TIFF) are deposited in this repository. Private coordinate-bearing site tables are deliberately excluded. The fixed manuscript model and transfer diagnostics can be inspected from the published files; reproducing the site overlay from scratch requires access to the withheld coordinate-bearing input. Independent end-to-end execution has not been verified.

## Peer-review update — 25 October 2026

The numerical outputs and original raster/figure bytes are preserved. Current documentation identifies the Biotropica submission and the coordinate-free public review route. [R28](../R/28_export_reproducibility_tables.R) now reads the public three-cell summary, and [run_all.R](../run_all.R) separates archive checks from explicit model rebuilding and stops on an unsuccessful step. These checks do not certify a complete refit from raw occurrences.
