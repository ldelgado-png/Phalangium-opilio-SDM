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
