# Protocol: transfer novelty (MESS/MOP) and independent Venezuelan assessment

**Status:** methodological plan; **not executed**. **No final calibration area (M) has yet been defended, and no final model is frozen.** The existing Western Palaearctic rectangular window and LQ/RM2 South America prediction are **exploratory**. This protocol must not be read as new modelling results.

## Scientific aim and manuscript figure

The manuscript's **Figure 2** is a photographic plate depicting habitats in Mérida, Venezuela. Its existing **Figure 4**, not Figure 2, illustrates the exploratory climatic-suitability surface for South America. The additional environmental-novelty assessment should accompany **Figure 4** (e.g., a paired MOP/map panel or supplementary material); the figure legend must distinguish climatic suitability from transfer reliability.

## Literature and provenance

- Owens, H. L. et al. (2013). Constraints on interpretation of ecological niche models by limited environmental ranges on calibration areas. *Ecological Modelling* **263**, 10–18. https://doi.org/10.1016/j.ecolmodel.2013.04.011
- Cobos, M. E., Owens, H. L., Soberón, J. & Peterson, A. T. (2024). Detailed multivariate comparisons of environments with mobility oriented parity. *Frontiers of Biogeography* **17**, e132916. https://doi.org/10.21425/fob.17.132916
- For a documented current R implementation, see CRAN **mop**: https://cran.r-project.org/package=mop (the `mop()` function takes environmental calibration/reference conditions and transfer conditions as `SpatRaster` or matrices).
- For MESS interpretation, cite the original MESS reference, Elith, Kearney & Phillips (2010), alongside Owens et al. (2013), when the procedure is finalized.

## Existing project inputs (climate only)

- `01_datos/climate_diagnostics/16_worldclim_western_window_5m.tif`: exploratory western Palaearctic **rectangle**, not a validated M.
- `01_datos/climate_diagnostics/17_worldclim_south_america_5m.tif`: South American projection predictors.
- Both use WorldClim 2.1 at 5 arcminutes; aligned predictor names `BIO1`, `BIO4`, `BIO12`, `BIO15`, native units and the same raster layers.
- `04_resultados_modelo/pilot_western_palaearctic/09_pilot_south_america_LQ_rm2_cloglog_NOT_FINAL.tif`: pilot visualization only, **not** the frozen model.

The prior `R/07_full_grid_transfer_range_audit.R` calculated a predictor-wise range-exceedance map; it is **not** equivalent to a formal MESS or MOP analysis.

## Executable Stage-A exploratory implementation (prepared, NOT executed)

`R/25_exploratory_MESS_MOP_south_america.R` is now available to run in the researcher's local RStudio using only the two archived climate stacks (WorldClim 2.1, BIO1/BIO4/BIO12/BIO15, 5 arcminutes). It does **not** read the Venezuelan occurrences, any model object or any pilot suitability prediction.

- A reproducible sample of up to **5,000** complete environmental cells is drawn from the **original western Palaearctic rectangle**, seed `251018`. This is **not** M, and the sample does not claim exhaustive coverage of the reference's extrema. Sample means and standard deviations define Euclidean distance scaling *without using the transfer domain*.
- `predicts::mess` calculates **raster-wide MESS** plus per-variable scores. Negative MESS indicates at least one out-of-range predictor relative to the **sampled** western-reference climate; the script writes a strict-extrapolation flag and a limiting-variable raster.
- MOP distance is defined as the mean **standardized Euclidean environmental distance to the closest 1%** (at least one, rounded upward) of reference cells, computed for the **complete South American predictor raster**. The R implementation uses `FNN::get.knnx` to search exact kd-tree neighbours within small, disk-backed `terra::app` chunks and cross-checks a small, independent sample of transfer climate cells against `mop::mop_distance`. The metric is continuous; it must **not** be interpreted as an established numeric cutoff for safely analogous transfer. Large within-range MOP distances can indicate novel multivariate combinations missed by strict single-variable tests.
- Outputs are stored locally under `04_resultados_modelo/pilot_western_palaearctic/transfer_novelty_EXPLORATORY_NOT_FINAL/`, with GeoTIFFs, PNG preview, sampled-reference statistics, version numbers, provenance and a simple count of extrapolative land cells. These **cell percentages are not area-corrected** because geographic rasters have unequal cell areas by latitude.
- All run outputs are **pending**; nothing in this protocol implies that the user's RStudio executed it. No calibration or model-selection change has occurred.

The script requires locally installed `terra`, `predicts`, `mop`, and `FNN`, and checks them before doing any work. In a later sensitivity assessment, repeat with several reference sample sizes/seeds and finally with a defended M; keep all map legends explicitly labelled **EXPLORATORY**.

## Stage A — environmental transfer diagnostics (without Venezuelan sites)

1. Defend and freeze the calibration area **M** using biogeographical evidence and accessible-area sensitivity analysis, **never referencing Venezuelan sites**. If preliminary diagnostics are performed using the current rectangle, label all maps `EXPLORATORY / NOT M`.
2. Harmonize the four bioclimatic layers across reference and projected regions; verify CRS, native WorldClim units, cell dimensions, layer ordering, NA masks, and comparable predictor definitions.
3. Define reference environments using **available environmental cells throughout M**, not only occupied points. Do not infer M from environmental similarity to the held-out sites.
4. Calculate **MESS** (identify negative values and contributing variables for strict one-variable extrapolation) and **MOP** (quantify multivariate environmental analogy and map strict extrapolation according to the selected documented implementation).
5. Choose and report environmental sampling strategy for MOP (all available pixels vs sampled calibration pixels, random seed, cell count, standardization, computational controls). Check memory before materializing full rasters, process in chunks when possible.
6. Archive and map novelty surfaces for the **entire** South American projection, with maps and provenance independently of any specific Venezuelan localities. Interpret regions of negative MESS or zero MOP as transfer-risk flags, not biological evidence of absence or distribution limits.

## Stage B — frozen model and final independent transfer report

1. Finalize and **freeze** the biogeographically justified M, sampling-bias correction/background, predictors, spatial-block partitions, model settings, fitted-model object, output scale (e.g. cloglog), clamping/extrapolation behavior, suitability raster and any classification threshold **without using the Venezuelan records**. Archive a unique script/version, a model-object hash and selection rationale.
2. **Only after freezing:** open the withheld Venezuelan field-event table and extract predicted climatic suitability, MESS, MOP and environmental-variable values at each **unique** geographic coordinate from the frozen rasters using `terra::extract` with an explicitly documented nearest-cell policy. If a site is near a grid boundary, assess positional uncertainty separately and **do not retune models or thresholds**.
3. Record event-to-coordinate and coordinate-to-raster-cell duplicates; the draft manuscript reports **seven field events, six coordinate pairs and approximately three distinct 5-arcminute predictor cells**. Therefore, compute summaries at **unique climate-cell level** as well as event level and avoid treating seven events as statistically independent suitability tests.
4. Report the site's coordinate/cell identifier, raw `cloglog` suitability (0–1), MESS score and the variable determining the minimum MESS score, MOP (including strict-extrapolation flag), and a straightforward interpretation of environmental analogy. Preserve each event in the private audit table; publish coordinates only in accordance with the manuscript's existing specimen data policy.
5. Describe the seven clustered field events as **limited independent transfer evidence**, not sufficient alone for an unbiased area-wide validation metric or definitive invasion forecast. No change to the model is permitted after viewing the site-level results; subsequent exploratory modifications must be labeled post hoc and externally validated elsewhere.

## Required manuscript outputs after verified execution

- Methods: calibrated environmental domain and data/bias background protocol, MESS/MOP algorithms/package versions, reference-sampling parameters, masking and clamping policy, and procedure for blinded-to-site model freeze.
- Results: distribution of strict-extrapolation/novelty scores across the projected region (percent of valid pixels with supporting area units when justified) and, separately, the held-out Venezuelan sites after model lock.
- Discussion: clarify conditional reliability of suitability predictions in analogous versus non-analog environments and the limitations of locally clustered independent occurrences.
- Figure 4 addendum or supplement: South American suitability raster alongside MOP novelty/strict-extrapolation map; clearly separate **relative suitability** from **extrapolation risk**.

## Pending tasks (Spanish)

- **Pendiente 1:** delimitar y justificar M independientemente de las localidades venezolanas; resolver alternativas de fondo (uniforme, superficie de esfuerzo de Opiliones, grupo objetivo).
- **Pendiente 2:** congelar el modelo, variables, clamping y umbrales antes de explorar las localidades venezolanas.
- **Pendiente 3:** ejecutar MESS y MOP sobre matrices/rásteres comparables, con parámetros y versiones registrados; la primera ejecución en la ventana rectangular solo podrá ser exploratoria.
- **Pendiente 4:** una vez congelado el modelo, extraer valores de idoneidad/MESS/MOP por sitio y por celda climática única; interpretar la baja independencia espacial.
- **Pendiente 5:** preparar un panel de MOP para Figura 4 o material suplementario. No afirmar resultados antes de ejecutar los análisis.

**Ethical design constraint:** Never inspect or use the seven Venezuelan collection events for selection of M, predictor variables, background, effort bias, tuning, model configuration, extrapolation settings or thresholds. Their sole role is independent post-freeze evaluation.
