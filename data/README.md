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

## Venezuelan site-level transfer diagnostics

The author-supplied [26_venezuela_site_transfer_values.csv](../results/26_venezuela_site_transfer_values.csv) contains seven collection-event rows. It contains coordinate-bearing event data that are publicly accessible in this repository and its original columns are `site_id`, `longitude`, `latitude`, `suitability_cloglog`, `MESS`, `MOP_distance`, `MESS_limiting_variable`, `univariate_extrapolation` and `environmental_context`. These records were withheld from model calibration and tuning. Repeated diagnostic profiles describe shared climatic conditions rather than independent environmental tests.

The deposited event-level file is preserved byte for byte (SHA-256 `dfc66ddb8fe93b6ffd01ab2ea89b9317cfb5499e0d6d3501f529fec3bca8fa2a`). The ranges summarized directly from it are **cloglog 0.558–0.617**, **MESS −18.727 to −18.375** and **MOP 2.028–2.458**. See [the analysis record](../docs/manuscript_transfer_status_2026-10-19.md) for reference scaling, point extraction, locality values and manuscript interpretation.
