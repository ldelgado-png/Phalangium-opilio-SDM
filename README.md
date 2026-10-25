# *Phalangium opilio*: climatic suitability and environmental transfer

Data, R scripts, model evaluations and figure exports supporting the manuscript submitted to **Biotropica**:

> A Palaearctic harvestman in the Venezuelan Andes: first Neotropical record and climatic suitability modeling of Phalangium opilio (Opiliones: Phalangiidae)

The repository documents the climatic analysis accompanying the Venezuelan natural-history records. The fixed manuscript model and its archived raster values are preserved. Venezuelan observations were excluded from calibration, tuning and model selection.

## For reviewers

Start with the [reviewer guide](docs/REVIEWER_GUIDE.md). A fresh checkout contains the model-evaluation tables, a coordinate-free three-cell transfer summary, four source GeoTIFFs and the suitability/MESS figure in PNG, PDF and 600-dpi TIFF formats.

```bash
git clone https://github.com/ldelgado-png/Phalangium-opilio-SDM.git
cd Phalangium-opilio-SDM
Rscript run_all.R
```

The default command checks the public archive with base R. To regenerate and compare the derived evaluation and raster-context tables, install `terra` and run:

```bash
Rscript run_all.R --with-rasters
```

Checks and regenerated tables are written to the ignored `local_review/` directory. These commands inspect archived outputs; they do not refit the model. Rebuilding from GBIF and WorldClim is documented separately in the [reviewer guide](docs/REVIEWER_GUIDE.md).

## Analysis reported in the manuscript

| Component | Specification |
| --- | --- |
| Occurrence source | [GBIF.org (2026), DOI:10.15468/dl.9gn3qv](https://doi.org/10.15468/dl.9gn3qv); 63,407 records from 506 datasets |
| Calibration region | Western Palaearctic operational rectangle: 12°W–60°E, 30°–72°N |
| Climatic predictors | WorldClim 2.1 BIO1, BIO4, BIO12 and BIO15; 5 arcminutes; 1970–2000 baseline |
| Calibration samples | 10,426 presence cells; 10,000 uniformly sampled background cells |
| Assessment | Four latitudinal spatial blocks; L, LQ and LQH features × regularization multipliers 1 and 2 |
| Manuscript projection | Prespecified LQ/RM2; cloglog output; clamping enabled; South America |
| Environmental reference | 5,000 sampled climate-valid cells; seed 251018 |
| Continuous MOP | Mean Euclidean distance to the nearest 1% (50) of reference climates, standardized using reference means and sample standard deviations |

The rectangle is a fixed operational reference, not a demonstrated historically accessible area (*M*). Mean validation AUC ranges from 0.622 to 0.661 across the six configurations, with substantial variation among folds. Background-extent and sampling-effort diagnostics document assumptions; they did not replace the fixed model.

## Venezuelan transfer results

The [public table](results/venezuela_transfer_cells_public.csv) groups seven collection events into three climatic cells. Its `cell_id` values are anonymized labels, not raster cell numbers or coordinates.

| Cell label | Events | Cloglog suitability | MESS | Continuous MOP | Limiting predictor |
| --- | ---: | ---: | ---: | ---: | --- |
| 1 | 5 | 0.616830 | −18.375195 | 2.028277 | BIO4 |
| 2 | 1 | 0.608131 | −18.619701 | 2.225173 | BIO4 |
| 3 | 1 | 0.558121 | −18.726749 | 2.457742 | BIO4 |

All three cells have negative MESS, with BIO4 below the sampled reference range. Suitability values therefore describe clamped transfer under non-analog conditions. MOP expresses continuous climatic dissimilarity and supplies no universal reliability threshold. These geographically clustered observations provide descriptive transfer evidence, not a representative continent-wide validation or an estimate of invasion risk.

The archived MESS raster contains 158,611 negative cells among 223,558 valid South American cells (70.9485% of cells, not equal-area land).

## Repository contents

| Material | Location |
| --- | --- |
| Reproduction instructions and input availability | [Reviewer guide](docs/REVIEWER_GUIDE.md), [data provenance](data/README.md) |
| Quality screening and source-record provenance | [R01](R/01_coordinate_quality_GBIF.R), [R03](R/03_restore_GBIF_record_provenance.R) |
| Predictor preparation and model fitting | [R06](R/06_prepare_climate_and_transfer_diagnostics.R), [R11](R/11_pilot_ENMeval_maxnet.R) |
| Model assessment | [Raw ENMeval table](results/initial_spatial_block_ENMeval.csv), [derived summary](results/model_evaluation_summary.csv) |
| MESS/MOP methods and results | [Protocol](docs/MOP_MESS_transfer_validation_protocol.md), [R25](R/25_exploratory_MESS_MOP_south_america.R), [numerical results](docs/manuscript_transfer_status_2026-10-19.md) |
| Public field diagnostics | [Three-cell summary](results/venezuela_transfer_cells_public.csv), [reference scaling](results/26_reference_environment_parameters.csv), [event summary](results/27_venezuela_transfer_summary.csv), [continental context](results/venezuela_suitability_percentiles.csv) |
| Source GeoTIFFs and figure exports | [Artifact manifest](data/review_artifact_manifest.csv), [model outputs](04_resultados_modelo/pilot_western_palaearctic), [figure exports](figures) |
| Local field extraction and plotting | [R26](R/26_venezuela_transfer_diagnostics_v3.R), [R27](R/27_figura2_idoneidad_MESS_JIS.R); require the private field input |
| Public checks and derived tables | [R30](R/30_check_repository.R), [R28](R/28_export_reproducibility_tables.R), [integrity/link checks](scripts/check_repository.py) |
| Reporting framework | [ODMAP](docs/ODMAP_reporting_framework.md), [fixed domain](docs/fixed_calibration_domain_decision.md) |

The two-panel map shows **(A) climatic suitability and (B) MESS sign**. MOP is reported in tables and text. Historical filenames containing `pilot`, `EXPLORATORY`, `NOT_FINAL`, `JIS` or figure numbers remain unchanged for provenance and path compatibility; they identify these same archived outputs. Figure numbering should follow the submitted manuscript.

## Input availability

The current branch excludes coordinate-bearing Venezuelan event tables. Exact localities remain under the authors' publication policy; event-level re-extraction and the figure's location overlay require the field input supplied with the manuscript or obtained from the corresponding author. No coordinates are needed for the public archive checks, numerical summaries or continental raster-context calculations.

The GBIF source archive and WorldClim predictor stacks are obtained separately from the sources and checksum documented in [data/README.md](data/README.md). The fitted model objects, calibration samples and complete original R session are not included in this archive. Full refitting is distinct from checking the deposited products and is not certified by a successful public archive check. R29 provides an optional BIO4/clamping sensitivity workflow; no new sensitivity result is claimed from its presence in the repository.

## Citation and licence

Cite the software using [CITATION.cff](CITATION.cff), identifying the commit used, and cite the GBIF download separately: GBIF.org (2026), https://doi.org/10.15468/dl.9gn3qv. The associated manuscript is submitted to *Biotropica* and has no publication DOI assigned here.

The R and Python code is distributed under the [MIT licence](LICENSE). GBIF records, WorldClim and other source data retain their respective source terms; the code licence does not replace those terms.
