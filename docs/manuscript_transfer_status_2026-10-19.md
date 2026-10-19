# Manuscript transfer-analysis update (19 October 2026)

**Target journal:** *Journal of Insect Science*.  
**Study:** First record of *Phalangium opilio* in the Venezuelan Andes.  
**Scope:** Documentation of the revised manuscript's South American climatic-suitability and environmental-novelty interpretation. This note does **not** alter model calibration, tuning, predictor rasters, background samples, or code.

## Fixed calibration and projection configuration

- Operational western Palaearctic calibration rectangle: **12°W–60°E, 30°–72°N**, fixed by the authors on 18 October 2026. This is **not** a demonstrated biogeographically accessible area (*M*).
- Occurrences: **10,426** unique 5-arcminute screened presence cells; **10,000** sampled uniform background cells.
- WorldClim 2.1, 5-arcminute predictors: **BIO1, BIO4, BIO12, BIO15**.
- Six evaluated `maxnet` configurations: feature classes **L, LQ, LQH** × regularization multipliers **1 and 2**; four spatially structured latitude folds.
- Mean spatial-validation **AUC 0.622–0.661** across configurations, with high fold-to-fold variability.
- South American illustrative transfer: pre-specified **LQ/RM2** model, **cloglog** output, **clamping** enabled. This was not the top-AICc configuration and was not reselected using Venezuelan occurrences.

## Newly reported Venezuelan transfer diagnostics

The author supplied the revised manuscript summary and an updated two-panel illustration on 19 October 2026. The following are **author-reported results from the local analysis**, not outputs independently reproduced or checked from raw model/raster artifacts in this repository.

| Metric | Reported observation |
| --- | --- |
| Venezuelan collection events | **7** |
| Distinct environmental cells | **3** WorldClim 5-arcminute cells |
| Predicted local suitability | **0.558–0.617** (cloglog) across localities |
| Environmental novelty | **All three** locality cells have **negative MESS** |
| Limiting reported predictor | **BIO4 (temperature seasonality)**, below the reference range in all three locality cells |
| Model-transfer behavior | **Clamping enabled** |
| Regional independent performance | **Not estimable** from these few clustered presence-only events |

The **negative MESS** statements pertain to the **western Palaearctic operational reference** and the environmental samples/implementation used locally; they do not establish novel conditions relative to every possible part of the native range. Likewise, cloglog outputs are **relative suitability predictions**, not occupancy probabilities, demonstration of invasion risk, physiological adaptation, or independent evidence of niche conservatism. The seven events must not be treated as seven independent environmental tests.

The public repository's `R/25_exploratory_MESS_MOP_south_america.R` computes climate-only exploratory MESS/MOP against a fixed reference raster and a reproducible sample of 5,000 reference cells, **without reading Venezuelan localities**. The local calculations that generated the supplied figure and its site-level numbers have **not** been deposited and their exact execution/version/provenance has **not** been independently verified here. In particular, do **not** label author-reported negative MESS as a deposited, independently reproduced R/25 execution, and do **not** claim that MOP site values or continent-wide MOP results are available.

## Revised manuscript interpretation

The model assigns nonzero relative suitability to the known Venezuelan records, but those sites fall outside the sampled western calibration climate for BIO4 and have negative MESS. Under clamping, agreement between the mapped prediction and occurrence positions cannot establish independent geographic discrimination, climatic niche conservatism or adaptation. The transfer identifies candidate areas warranting targeted surveys, with dispersal, habitat and anthropogenic transport evaluated separately.

## Current Figure 3

- **Panel A — Predicted climatic suitability:** South America, LQ/RM2, WorldClim 2.1 BIO1/BIO4/BIO12/BIO15, 5′, cloglog 0–1, clamped.
- **Panel B — Environmental novelty:** sign of MESS relative to the western Palaearctic calibration reference (**MESS < 0** versus **MESS ≥ 0**), with a marker for the Venezuelan study area and inset of its **three** environmental cells.
- The supplied image is identified in the conversation as `Figure_2_Suitability_MESS_JIS.png`, while its **manuscript number is Figure 3**. The image **is not currently archived in this GitHub repository**; numerical raster files and a verified generating script for the combined panel likewise remain to be deposited. Avoid asserting image-level reproducibility until those materials have been inspected.
- Figure 1: habitat photographs; Figure 2: geographical distribution; **Figure 3: suitability + MESS**; Figure 4: live specimens. Older repository documents use different figure numbers and are historical, not current submission numbering.

### Proposed concise legend

> **Figure 3.** Predicted climatic suitability and environmental novelty for *Phalangium opilio* in South America, based on a western Palaearctic-calibrated model. **(A)** Climatic suitability (cloglog, 0–1) predicted using maxnet (LQ features, regularization multiplier 2) and WorldClim 2.1 BIO1, BIO4, BIO12, and BIO15 at 5-arcminute resolution, with clamping enabled. **(B)** Environmental novelty (MESS): red indicates MESS < 0 and green indicates MESS ≥ 0. The white circle marks the Venezuelan study area; the inset shows three climatic cells containing seven collection records. All three cells had negative MESS, with BIO4 below the sampled calibration range.

## Reproducibility record: evidence still required (pendientes técnicos)

- **Pendiente:** depositar y verificar el script exacto, registros de ejecución, versiones de paquetes y rásteres de los que procede la figura combinada y los valores locales.
- **Pendiente:** documentar si el MESS de los sitios se calculó frente a toda la referencia o a una muestra de 5.000 celdas, con su semilla y unidades de BIO4; mantener consistencia entre métodos y leyenda.
- **Pendiente:** verificar los tres valores de idoneidad por celda, sus puntuaciones MESS, la variable limitante y el mapeo de los siete eventos a las tres celdas sin exponer metadatos de campo inéditos innecesarios.
- **Pendiente:** no afirmar que se completó MOP en las localidades hasta disponer de sus salidas y controles de calidad.
- **Pendiente:** corregir en cualquier texto de manuscrito la numeración histórica de figuras y describir la ventana paleártica como dominio operativo, no *M* demostrado.
- **Pendiente:** confirmar el tratamiento uniforme del fondo y que las superficies de sesgo y el fondo target-group no se presenten como modelos finales ejecutados.

## Relevant repository sources

- [Fixed-domain decision](fixed_calibration_domain_decision.md)
- [Original staged transfer protocol](MOP_MESS_transfer_validation_protocol.md) (historical planning status; not a verified local execution report)
- [Climatic novelty script](../R/25_exploratory_MESS_MOP_south_america.R)
- [Initial spatial evaluation data](../results/initial_spatial_block_ENMeval.csv)

## Methodological references

- Elith J, Kearney M, Phillips S. 2010. The art of modelling range-shifting species. *Methods in Ecology and Evolution* 1:330–342. https://doi.org/10.1111/j.2041-210X.2010.00036.x
- Owens HL, Campbell LP, Dornak LL, et al. 2013. Constraints on interpretation of ecological niche models by limited environmental ranges on calibration areas. *Ecological Modelling* 263:10–18. https://doi.org/10.1016/j.ecolmodel.2013.04.011
- Warren DL, Glor RE, Turelli M. 2008. Environmental niche equivalency versus conservatism: quantitative approaches to niche evolution. *Evolution* 62:2868–2883. https://doi.org/10.1111/j.1558-5646.2008.00482.x
- Barve N, Barve V, Jiménez-Valverde A, et al. 2011. The crucial role of the accessible area in ecological niche modeling and species distribution modeling. *Ecological Modelling* 222:1810–1819. https://doi.org/10.1016/j.ecolmodel.2011.02.011
