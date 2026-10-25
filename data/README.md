# GBIF occurrence data and source provenance

We use the GBIF taxon-filtered snapshot for *Phalangium opilio* (Linnaeus, 1758), created on **17 October 2026 at 18:59:05** (time zone unspecified in the supplied download metadata).

| Attribute | Value |
| --- | --- |
| DOI | https://doi.org/10.15468/dl.9gn3qv |
| Total occurrence records | 63,407 |
| Publishing datasets | 506 |
| Compressed size | 7.8 MB reported; 7,793,071 bytes locally |
| Download format | Simple tab-separated values (TSV) |
| File stored in ZIP | `0032625-260928105237408.csv` |
| SHA-256 of original ZIP | `e70a54358230723888c787503e0415db822cbae1bebeea33f977b5dab2613fe8` |

The underlying file has a `.csv` extension but uses **tab delimiters**. Our R script reads it accordingly.

The GBIF search filter, transcribed from the download receipt, is:

```json
{
  "TaxonKey": ["is one of (Phalangium opilio [Catalogue of Life])"]
}
```

**Data citation:** GBIF.org (2026). *GBIF Occurrence Download*. https://doi.org/10.15468/dl.9gn3qv

For reproducible coordinate screening, obtain the archive corresponding to the DOI and place it at `01_datos/gbif_descarga_original.zip` in your working directory. Run:

```r
install.packages("CoordinateCleaner")
source("R/01_coordinate_quality_GBIF.R")
```

The script writes individual flags and screening summaries to `01_datos/coordinatecleaner/`. We cite the DOI and preserve a source checksum rather than bundling heterogeneous GBIF source datasets under a single redistribution license.

## Public Venezuelan transfer data

[venezuela_transfer_cells_public.csv](../results/venezuela_transfer_cells_public.csv) contains three anonymized climatic-cell rows representing seven collection events. `cell_id` is a sequential label, not a spatial raster identifier. No coordinate column or geographic grid index is included.

| Column | Meaning |
| --- | --- |
| `cell_id` | Anonymized cell label (1–3) |
| `n_events` | Collection events represented by that cell (5, 1, 1) |
| `suitability_cloglog` | Fixed LQ/RM2 clamped cloglog prediction |
| `MESS` | Overall environmental similarity score (negative in all three cells) |
| `MOP_distance` | Mean standardized Euclidean distance to the nearest 1% of reference climates |
| `MESS_limiting_variable` | Predictor with the smallest MESS component; BIO4 in these cells |
| `univariate_extrapolation` | Whether overall MESS is below zero |

The [reference parameters](../results/26_reference_environment_parameters.csv) document MOP centering/scaling and sampled ranges. The [event summary](../results/27_venezuela_transfer_summary.csv) summarizes all seven events; the [continental-context table](../results/venezuela_suitability_percentiles.csv) summarizes the three cells. Events sharing a cell are not independent climatic replicates.

Coordinate-bearing Venezuelan field tables are excluded from the current branch until publication. R26/R27 require an explicit private field input for site-level extraction/overlays, as explained in the [reviewer guide](../docs/REVIEWER_GUIDE.md). Public table checks and R28 use only the coordinate-free summary.

## Archived outputs and source inputs

The [artifact manifest](review_artifact_manifest.csv) records the original GeoTIFF and figure bytes by Git blob SHA-1 and file size. Those objects are unchanged during the peer-review documentation update. Historical filenames are retained so existing script references remain valid.

The raw GBIF archive, WorldClim predictor stacks, fitted model objects and calibration sample files are not bundled here. The [reviewer guide](../docs/REVIEWER_GUIDE.md) distinguishes checking deposited outputs, rebuilding from public source data and re-extracting separately supplied field records.
