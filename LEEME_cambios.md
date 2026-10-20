# Archivos preparados para Phalangium-opilio-SDM

Copiar sobre la raíz del repositorio (misma estructura de carpetas) o aplicar `fixes_repositorio.patch` con `git apply`.

**Nuevos:** LICENSE (MIT; cámbiala si prefieres otra), CITATION.cff (faltan versión, fecha y DOI de Zenodo), run_all.R, R/28_export_reproducibility_tables.R, R/29_sensitivity_BIO4_clamping.R, results/model_evaluation_summary.csv, results/venezuela_suitability_percentiles.csv.
**Modificados:** README.md (reproducibilidad, coordenadas públicas, licencia), PUBLICATION_NOTES.txt, .gitignore (nota), data/README.md, docs/study_calibration_domain_fixed.json, docs/methodological_framework.md, R/11 (nota de estado).
**Eliminado:** R/26_venezuela_transfer_diagnostics.R (idéntico al v3).

**Pendiente (no se puede hacer desde aquí):**
1. Ejecutar run_all.R en un checkout limpio y subir results/sessionInfo.txt. run_all.R, R/28 y R/29 NO se han ejecutado (no hay R en este entorno).
2. Ejecutar R/28 y R/29 localmente (necesitan salidas locales de R/11 y WorldClim); revisar la licencia de GBIF antes de subir data/calibration_presence_cells.csv.
3. Crear release v1.0.0, archivarlo en Zenodo, completar CITATION.cff y citar ese DOI/commit en el manuscrito (hoy cita f4f26e5, que no contiene los resultados).
