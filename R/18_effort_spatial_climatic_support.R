# Phalangium opilio | Spatial and climatic support of Opiliones sampling effort
#
# Run from the original RStudio project working directory:
# source("https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/18_effort_spatial_climatic_support.R")
#
# Descriptive diagnostic only. No background scenario is established as M;
# no model is fitted, scored, selected, or applied to withheld Venezuelan
# field records. The published El-Gabbas (2026) Opiliones effort raster MAY
# include records of the focal species itself.

# Reuse the completed and checked R/16 input alignment and spatial-fold
# reconstruction, rather than creating new cross-validation partitions.
source(
  "https://raw.githubusercontent.com/ldelgado-png/Phalangium-opilio-SDM/main/R/16_effort_weighting_feasibility.R",
  local = TRUE
)

if (!all(c("BIO1", "BIO4", "BIO12", "BIO15") %in% names(bio))) {
  stop("Unexpected WorldClim predictor names.")
}
vars <- c("BIO1", "BIO4", "BIO12", "BIO15")
climate <- terra::values(bio[[vars]], mat = TRUE)
if (!is.matrix(climate) || ncol(climate) != length(vars) ||
    nrow(climate) != terra::ncell(bio)) {
  stop("Unexpected climate raster dimensions.")
}
colnames(climate) <- vars
if (any(!is.finite(climate[p_cells, , drop = FALSE]))) {
  stop("One or more archived pilot presences have incomplete predictors.")
}
if (anyNA(eff_values[p_cells])) {
  stop("Missing aligned effort on archived pilot presence cells.")
}

# The blocks were defined using calibration coordinates and preserved in
# ENMeval. We use EXACTLY the original fold boundaries reconstructed in R/16.
p_fold <- as.character(assign_fold(p_xy[, 2]))
if (length(p_fold) != length(p_cells) ||
    anyNA(p_fold) ||
    !setequal(unique(p_fold), as.character(fold_levels))) {
  stop("Presences cannot be consistently assigned to the original folds.")
}

# Presence evidence across all four ENMeval latitudinal folds.
presence_audit <- do.call(rbind, lapply(fold_levels, function(g) {
  vals <- eff_values[p_cells[p_fold == g]]
  data.frame(
    fold = as.character(g),
    n_presence_cells = length(vals),
    n_positive_effort = sum(vals > 0),
    n_zero_effort = sum(vals == 0),
    percent_positive_effort = round(100 * mean(vals > 0), 2),
    median_positive_effort = if (any(vals > 0))
      stats::median(vals[vals > 0]) else NA_real_,
    stringsAsFactors = FALSE
  )
}))
rownames(presence_audit) <- NULL

# The original rectangle and buffered alternatives are descriptive hypotheses.
# Exclude ALL calibration-presence pixels when diagnosing candidate backgrounds.
spatial_rows <- list()
climate_rows <- list()
all_cells <- seq_len(terra::ncell(bio))
for (scenario in names(scenario_masks)) {
  candidate_mask <- scenario_masks[[scenario]]
  if (length(candidate_mask) != length(all_cells)) {
    stop("Scenario mask dimensions differ from the climate raster.")
  }
  candidate_mask[p_cells] <- FALSE
  cells <- which(candidate_mask)
  if (!length(cells)) stop("Empty diagnostic background: ", scenario)
  effort <- eff_values[cells]
  if (anyNA(effort) || any(effort < 0)) {
    stop("Unexpected effort values in diagnostic background: ", scenario)
  }
  is_positive <- effort > 0
  if (!any(is_positive)) {
    stop("No recorded order-level effort in ", scenario)
  }
  candidate_fold <- as.character(assign_fold(
    terra::xyFromCell(bio[[1]], cells)[, 2]
  ))
  if (anyNA(candidate_fold)) stop("Missing fold assignments.")

  for (g in as.character(fold_levels)) {
    in_fold <- candidate_fold == g
    eff_g <- effort[in_fold]
    if (!length(eff_g)) stop("Empty fold ", g, " in ", scenario)
    pp <- presence_audit[presence_audit$fold == g, ]
    spatial_rows[[length(spatial_rows) + 1L]] <- data.frame(
      scenario = scenario,
      fold = g,
      n_eligible_background_cells = length(eff_g),
      n_positive_effort_cells = sum(eff_g > 0),
      n_zero_effort_cells = sum(eff_g == 0),
      percent_background_positive_effort = round(
        100 * mean(eff_g > 0), 2
      ),
      percent_presence_positive_effort = pp$percent_positive_effort,
      percentage_point_difference = round(
        pp$percent_positive_effort - 100 * mean(eff_g > 0), 2
      ),
      stringsAsFactors = FALSE
    )
  }

  # Climatic support based on raster values, not a fitted niche model.
  # Quantile overlap is a univariate DESCRIPTIVE statistic and should not
  # be called a multivariate MOP, MESS or calibration-transfer evaluation.
  pos_cells <- cells[is_positive]
  for (v in vars) {
    j <- match(v, vars)
    all_env <- climate[cells, j]
    pos_env <- climate[pos_cells, j]
    pres_env <- climate[p_cells, j]
    if (any(!is.finite(all_env)) || any(!is.finite(pos_env))) {
      stop("Non-finite predictor values in ", scenario, " / ", v)
    }
    mn <- min(pos_env)
    mx <- max(pos_env)
    q <- as.numeric(stats::quantile(
      pos_env, probs = c(0.05, 0.95), na.rm = TRUE, names = FALSE
    ))
    climate_rows[[length(climate_rows) + 1L]] <- data.frame(
      scenario = scenario,
      variable = v,
      n_candidate_background_cells = length(cells),
      n_background_cells_with_positive_effort = length(pos_cells),
      full_candidate_min = min(all_env),
      full_candidate_max = max(all_env),
      positive_effort_min = mn,
      positive_effort_max = mx,
      positive_effort_5pct = q[1],
      positive_effort_95pct = q[2],
      n_presences_outside_positive_effort_range =
        sum(pres_env < mn | pres_env > mx),
      n_presences_outside_positive_effort_central_90pct =
        sum(pres_env < q[1] | pres_env > q[2]),
      percent_candidate_cells_outside_positive_effort_range = round(
        100 * mean(all_env < mn | all_env > mx), 2
      ),
      stringsAsFactors = FALSE
    )
  }
}
spatial_audit <- do.call(rbind, spatial_rows)
climate_audit <- do.call(rbind, climate_rows)
rownames(spatial_audit) <- NULL
rownames(climate_audit) <- NULL

p_file <- file.path(effort_dir, "19_presence_effort_by_fold.csv")
s_file <- file.path(effort_dir, "20_spatial_support_by_fold.csv")
c_file <- file.path(effort_dir, "21_effort_climate_range_audit.csv")
utils::write.csv(presence_audit, p_file, row.names = FALSE)
utils::write.csv(spatial_audit, s_file, row.names = FALSE)
utils::write.csv(climate_audit, c_file, row.names = FALSE)

# The chart compares positive GBIF effort in observed presences with the
# original rectangle's available background, separately by latitude block.
fig <- file.path(effort_dir, "22_effort_fold_support_diagnostic.png")
original_spatial <- spatial_audit[
  spatial_audit$scenario == "original_rectangle", , drop = FALSE
]
original_spatial <- original_spatial[match(
  as.character(fold_levels), original_spatial$fold
), , drop = FALSE]
plot_data <- rbind(
  "Calibration presences" =
    original_spatial$percent_presence_positive_effort,
  "Candidate background" =
    original_spatial$percent_background_positive_effort
)
grDevices::png(fig, width = 1800, height = 1150, res = 180)
op <- graphics::par(mar = c(5.2, 5.4, 4.0, 1.3), xpd = NA)
tryCatch({
  graphics::barplot(
    plot_data, beside = TRUE,
    names.arg = paste("Fold", as.character(fold_levels)),
    ylim = c(0, 110),
    col = c("gray35", "gray75"),
    border = "white",
    ylab = "Cells with positive Opiliones effort (%)",
    main = "Sampling-effort support by original validation fold",
    cex.main = 1.05,
    cex.axis = 1.0,
    cex.names = 1.0,
    legend.text = TRUE,
    args.legend = list(x = "topright", bty = "n", cex = 0.9)
  )
}, finally = {
  graphics::par(op)
  grDevices::dev.off()
})

writeLines(c(
  "Opiliones sampling-effort spatial/climate support diagnostic.",
  paste("Source script: R/18_effort_spatial_climatic_support.R"),
  "Reference: El-Gabbas (2026), https://doi.org/10.1111/ddi.70205.",
  "Effort layer: Arachnida/Opiliones n_obs, cumulative 1980-2025.",
  "5 km-source averaged for 5-arcminute WorldClim diagnostic support.",
  "WorldClim v2.1: BIO1, BIO4, BIO12, BIO15; reference 1970-2000.",
  "All background candidates exclude archived pilot presence pixels.",
  "The original rectangular area and buffers are NOT validated accessible areas M.",
  "Presence-support climate bounds are descriptive, not ecological limits.",
  "Order-level n_obs may contain the focal Phalangium opilio records.",
  "Neither a bias-correction method nor final M nor model is selected.",
  "Venezuelan field observations were not read or used."
), file.path(effort_dir, "effort_spatial_climate_audit_provenance.txt"))

cat("\nPRESENCE EFFORT BY ORIGINAL SPATIAL FOLD\n")
print(presence_audit, row.names = FALSE)
cat("\nELIGIBLE BACKGROUND EFFORT BY DOMAIN AND SPATIAL FOLD\n")
print(spatial_audit, row.names = FALSE)
cat("\nUNIVARIATE ENVIRONMENTAL SUPPORT OF EFFORT-POSITIVE CELLS\n")
print(climate_audit, row.names = FALSE)
cat("\nSaved three CSVs and a fold-support PNG under:\n",
    normalizePath(effort_dir, winslash = "/", mustWork = TRUE), "\n")
cat("No model fit, no final M, and no Venezuelan field assessment.\n")
