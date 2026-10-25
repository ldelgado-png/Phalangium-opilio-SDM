# Reviewer guide

## 1. Inspect the archived evidence

The [README](../README.md) gives the fixed analysis settings and three-cell MESS/MOP results. The [raw evaluation table](../results/initial_spatial_block_ENMeval.csv) contains all six configurations; the map uses the prespecified LQ/RM2 configuration rather than the minimum-AICc configuration. The [artifact manifest](../data/review_artifact_manifest.csv) identifies the four original GeoTIFFs and three figure exports by path, byte size and Git blob SHA-1.

The suitability raster is a clamped cloglog projection. The MESS file contains four predictor-specific scores and an overall fifth layer. Its companion limiting-variable raster uses 1=BIO1, 2=BIO4, 3=BIO12 and 4=BIO15. The MOP raster stores continuous nearest-1%-reference distance. No raster is resampled during field-value extraction or the archive checks.

## 2. Check public tables and file integrity

From the repository root, with R installed:

```bash
Rscript run_all.R
python3 scripts/check_repository.py
```

The R command parses the R scripts and checks public table schemas, event/cell counts, finite values, extrapolation flags, model settings and agreement among deposited summaries. The Python command checks original artifact sizes/hashes, local Markdown links and coordinate-bearing Venezuelan CSVs among tracked files. Python uses its standard library only.

To recompute the evaluation summary and continental raster-context table:

```r
install.packages("terra")
```

```bash
Rscript run_all.R --with-rasters
```

R28 reads the public three-cell table directly. It writes regenerated tables to `local_review/tables/` and compares their numeric values with the deposited tables. The driver records session information and a step log under `local_review/`. A failure stops the run; a session-information file alone is not a successful reproduction record.

## 3. Rebuild the model from source data

Use a separate working copy, since the historical fitting scripts write to the archived model paths. Obtain the exact [GBIF snapshot](https://doi.org/10.15468/dl.9gn3qv), check the SHA-256 in [data provenance](../data/README.md), and place it at:

`01_datos/gbif_descarga_original.zip`

Install the packages used by the relevant stages:

```r
install.packages(c("CoordinateCleaner", "terra", "geodata",
                   "rnaturalearth", "rnaturalearthdata", "sf",
                   "ENMeval", "maxnet", "predicts", "mop", "FNN"))
```

```bash
Rscript run_all.R --rebuild-model
```

This explicitly runs R01 → R03 → R06 → R11 → R25. R06 acquires WorldClim 2.1 at 5 arcminutes and prepares the fixed western Palaearctic and South American stacks. R11 fits six configurations and projects fixed LQ/RM2; R25 calculates MESS/MOP from the independent climate reference. The Venezuelan field data are not read by these stages. Source-data downloads require internet access and fitting is substantially more expensive than archive checks.

The historical documentation reports ENMeval 2.0.5 and maxnet 0.1.4. An exact original session/complete package lockfile was not deposited, so this guide does not assert bitwise refitting across current package versions. Keep the generated session record and compare outputs explicitly before replacing any archived result.

## 4. Re-extract the withheld field records

Field coordinates are managed separately from the current public branch. Use the independently documented Venezuelan records supplied with the manuscript or request them from the corresponding author. R26 requires an explicit local input:

```r
options(phalangium.venezuela_sites_csv = "/absolute/path/to/private_field_records.csv")
source("R/26_venezuela_transfer_diagnostics_v3.R")
source("R/27_figura2_idoneidad_MESS_JIS.R")
```

The R26 input accepts `longitude`/`latitude` or `decimalLongitude`/`decimalLatitude`, with an optional `site_id`. It must contain the independent field events, not GBIF calibration records. Its coordinate-bearing outputs remain in the ignored model-work directory. R27 reads that local extraction; a different extraction path can be supplied through `options(phalangium.venezuela_extraction_csv = "/absolute/path/to/extraction.csv")`.

R29 can be run separately after local calibration outputs and the private extraction exist. It assesses BIO4/clamping sensitivity without choosing a new manuscript model. Its output is local and no unexecuted sensitivity result is attributed to the manuscript.

## 5. Scope of inference

Seven events occupy three climatic cells. All have negative MESS, and BIO4 is the limiting predictor below the sampled reference range. Continuous MOP is 2.028–2.458, with no selected reliability cutoff. The model describes conditional climatic suitability, not occupancy, dispersal or invasion risk. Background and sampling-effort diagnostics are documented alternatives, not fitted replacements for the fixed manuscript model.
