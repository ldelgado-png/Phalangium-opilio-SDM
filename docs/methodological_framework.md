# Methodological framework

## Study aim

We examine the potential climatic suitability of *Phalangium opilio* in South America in the context of its confirmed occurrence in the Venezuelan Andes. Our inference concerns environmental suitability, not observed occupancy, introduction probability, propagule pressure, or direct ecological impact.

## Data origin and independent field evidence

The GBIF snapshot contains 63,407 records contributed by 506 publishing datasets. Our initial source audit identified no records attributed to South American countries **within this specific download**. We therefore distinguish GBIF calibration records from the independently documented Venezuelan collection localities. This observation about one snapshot must not be interpreted as a general absence of GBIF records from South America.

The manuscript describes seven collection events from Mérida, represented by six coordinate pairs and approximately three 5-arcminute climatic grid cells. Because these sites are geographically clustered, they do not constitute a robust continent-wide independent validation sample.

## Occurrence screening

We screen species assignments, occurrence status, coordinate plausibility, reported uncertainty and source quality flags. We use `CoordinateCleaner` to flag locations associated with capitals, centroids, institutions, GBIF facilities, coordinates at sea, zero coordinates and identical longitude–latitude pairs. We retain test-specific flags for review instead of treating every alert as a confirmed error.

We treat cell-level spatial thinning and sampling-bias correction as distinct operations. In particular, retaining one occurrence per environmental cell does not resolve uneven sampling effort across geographical space.

## Eastward environmental coverage

We contrasted the climatic characteristics of records east of 60°E with the minimum–maximum ranges calculated over the complete environmental raster of the exploratory Western Palaearctic window. We retained 95 screened occurrences in 68 unique 5-arcminute climatic cells (Russia: 60 cells; Japan: 6; Kazakhstan: 2). Three Russian cells (4.41% of eastern cells) exceeded the upper range of BIO4; none exceeded the univariate ranges of BIO1, BIO12, or BIO15. The Western Palaearctic raster-wide BIO4 maximum was 1,488.34 and the eastern-record maximum was 1,875.19 (native WorldClim scale). 

We interpret these univariate comparisons as descriptive range diagnostics rather than evidence of environmental equivalence. The absence of single-variable range exceedance does not rule out novel combinations of predictors. We maintain separate analytical treatment of eastern Eurasian records until geographic provenance, historical range evidence, and the accessible calibration area are evaluated. Field observations from Venezuela are excluded from calibration, tuning, and scenario selection.

## Climate variables and model evaluation

We formulate the R workflow using `terra`, `ENMeval`, and `maxnet`. Our baseline climatic predictors are WorldClim 2.1 BIO1 (annual mean temperature), BIO4 (temperature seasonality), BIO12 (annual precipitation), and BIO15 (precipitation seasonality), at 5-arcminute resolution.

We distinguish the biogeographically justified accessible area used for calibration from the South American projection region. Spatially structured evaluation and model-complexity selection provide a basis for comparing candidate configurations. We interpret climatic extrapolation and nonanalog environments explicitly when assessing transfers outside the calibration region.

## Interpretation and reproducibility

We express model output as **relative climatic suitability**, not calibrated occurrence probability or a forecast of realized geographical spread. We report quantitative model performance and mapped predictions only when they are supported by completed, reproducible analyses with traceable input data and evaluation settings.
