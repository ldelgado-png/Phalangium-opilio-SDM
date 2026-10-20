# Venezuelan climatic transfer diagnostics

**Updated:** 19 October 2026.  
**Target journal:** *Journal of Insect Science*.  
**Public data:** [venezuela_transfer_cells_public.csv](../results/venezuela_transfer_cells_public.csv), a coordinate-free summary of seven field events grouped into three climatic cells. The original coordinate-bearing event table is not publicly deposited.

## Calibration and projection

The fixed operational calibration rectangle is **12°W–60°E, 30°–72°N**. It is an operational environmental reference rather than a demonstrated biogeographical accessible area (*M*). Calibration uses **10,426** presence cells, **10,000** uniform-background cells and WorldClim 2.1 **BIO1, BIO4, BIO12 and BIO15** at **5 arcminutes**. Six maxnet configurations (L, LQ, LQH × regularization multipliers 1 and 2) were evaluated in four latitude blocks. Mean spatial-validation AUC ranges from **0.622 to 0.661** across configurations. The manuscript projection uses the prespecified **LQ/RM2** configuration with **cloglog output and clamping**. Venezuelan observations were withheld from calibration and model selection.

## Reference method

[R25](../R/25_exploratory_MESS_MOP_south_america.R) samples a target of **5,000** complete reference climates using seed **251018** and the four predictors in the order BIO1, BIO4, BIO12, BIO15. Continuous MOP is the mean Euclidean distance to the nearest **1%** of reference climates after centering and scaling each predictor with the reference sample's mean and sample standard deviation. With 5,000 complete rows, this uses **50** nearest reference climates. The script checks its exact nearest-neighbour implementation against `mop::mop_distance`. MOP distances are unbounded continuous dissimilarities; they are not occupancy probabilities or a normalized 0–1 similarity index. No post hoc cutoff was selected at the Venezuelan sites.

[R26](../R/26_venezuela_transfer_diagnostics.R) archives the v3 point-extraction workflow. It reads suitability, overall MESS, MOP distance and the limiting-variable raster independently at the original coordinates. It does not resample rasters or refit the model.

## Deposited numerical results

| Locality group | Collection events | Cloglog suitability | MESS | MOP distance | Limiting variable |
| --- | ---: | ---: | ---: | ---: | --- |
| Escagüey and Moconoque | 5 | 0.616830 | -18.375195 | 2.028277 | BIO4 |
| La Toma | 1 | 0.608131 | -18.619701 | 2.225173 | BIO4 |
| La Musui | 1 | 0.558121 | -18.726749 | 2.457742 | BIO4 |

The seven rows contain three distinct joint diagnostic profiles, consistent with the manuscript's report of **three** climatic cells. Native raster-cell identifiers are not included in the supplied CSV, so this deposit does not independently reconstruct cell geometry. Multiple collection events sharing the same environment are not independent environmental replicates.

Across the events, **cloglog suitability is 0.558–0.617**, **MESS is −18.727 to −18.375**, and **MOP distance is 2.028–2.458**. Every MESS value is negative and BIO4 is the limiting variable in all seven rows. The manuscript identifies the departure as BIO4 below the sampled reference range. La Musui has the greatest MOP distance among the Venezuelan sites.

## Interpretation

MOP describes relative multivariate climatic dissimilarity from the sampled reference. Negative MESS identifies at least one predictor outside its sampled univariate range. The MOP distances distinguish the climatic context of the Venezuelan localities without supplying an independent test of model discrimination or a universal cutoff for transfer reliability. Under clamping, correspondence between predicted suitability and observed occurrences does not by itself establish niche conservatism, physiological adaptation, occupancy elsewhere or invasion risk.

## Manuscript Results

Climatic suitability modeling. Across the six evaluated model configurations, mean spatial-validation AUC ranged from 0.622 to 0.661, with considerable variation among spatial folds. The selected LQ/RM2 model identified areas of relatively high predicted climatic suitability in the southern cone of South America and along portions of the Andean cordillera (Fig. 3). At the Venezuelan collection localities, predicted cloglog suitability ranged from 0.558 to 0.617. The seven collection records corresponded to only three unique 5-arcminute climatic grid cells, all of which exhibited negative Multivariate Environmental Similarity Surface (MESS) values. Temperature seasonality (BIO4) was below the range represented in the western Palaearctic calibration region in all three cells. MESS scores ranged from −18.727 to −18.375. Continuous MOP distances were 2.028 at Escagüey and Moconoque, 2.225 at La Toma, and 2.458 at La Musui (range 2.028–2.458). Thus, although the model assigned moderate relative suitability to the Venezuelan localities, these predictions were obtained under clamping in environmentally non-analog conditions. Venezuelan occurrence records were excluded from model calibration and evaluation. 

## Manuscript Discussion addition

The higher MOP distance at La Musui indicates greater multivariate climatic dissimilarity from the sampled reference than at the other Venezuelan localities. MOP therefore complements the negative MESS values by describing differences among sites, while its magnitude alone does not establish a threshold for reliable model transfer.

## Figure numbering

The current manuscript uses **Figure 1: habitats; Figure 2: geographical distribution; Figure 3: suitability and MESS; Figure 4: live specimens**. Figure 3A maps clamped LQ/RM2 relative suitability and Figure 3B maps MESS sign. MOP is reported numerically in Results and discussed in the text; this update does not change the two-panel figure or claim that it displays MOP.

## Data provenance

The supplied CSV was checked for seven complete, finite numerical rows, nonnegative MOP, suitability within 0–1, negative MESS and agreement with the extrapolation flags. The locality values and reported ranges were summarized directly from that file. The CSV is preserved byte for byte. Its SHA-256 is `dfc66ddb8fe93b6ffd01ab2ea89b9317cfb5499e0d6d3501f529fec3bca8fa2a`. Environmental rasters, the reference sample and model fits were not rerun during this deposit. This record supersedes earlier statements that site-level MOP values were unavailable.

## Methodological references


- Elith J, Kearney M, Phillips S. 2010. The art of modelling range-shifting species. *Methods in Ecology and Evolution* 1:330–342. https://doi.org/10.1111/j.2041-210X.2010.00036.x
- Owens HL, Campbell LP, Dornak LL, et al. 2013. Constraints on interpretation of ecological niche models by limited environmental ranges on calibration areas. *Ecological Modelling* 263:10–18. https://doi.org/10.1016/j.ecolmodel.2013.04.011
- Warren DL, Glor RE, Turelli M. 2008. Environmental niche equivalency versus conservatism: quantitative approaches to niche evolution. *Evolution* 62:2868–2883. https://doi.org/10.1111/j.1558-5646.2008.00482.x
- Barve N, Barve V, Jiménez-Valverde A, et al. 2011. The crucial role of the accessible area in ecological niche modeling and species distribution modeling. *Ecological Modelling* 222:1810–1819. https://doi.org/10.1016/j.ecolmodel.2011.02.011
