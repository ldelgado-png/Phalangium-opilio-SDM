# Phalangium opilio | R26 - Venezuelan independent-site transfer diagnostics
# 2026-10-19 (v3). IMPORTANT: fixed operational rectangle is NOT a validated accessible M.
# v3: fixes terra::extract(matrix) call (no ID argument); each raster
# is independently extracted at exact site coordinates; pixel-grid
# alignment is unnecessary for point extraction. NEVER resamples rasters.
# Run from the local Phalangium_opilio_SDM project directory in RStudio.
# Before sourcing, set the actual independent Venezuelan CSV file path:
# options(phalangium.venezuela_sites_csv = "C:/.../independent_venezuela_sites.csv")
# This script never refits, tunes or selects a model and never modifies R25 outputs.
# Required CSV fields: longitude and latitude OR decimalLongitude and decimalLatitude.
# Optional identifier field: site_id, locality, or gbifID.

if (!requireNamespace("terra", quietly=TRUE)) stop("Install missing package: terra")
root <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
pilot <- file.path(root,"04_resultados_modelo","pilot_western_palaearctic")
nov <- file.path(pilot,"transfer_novelty_EXPLORATORY_NOT_FINAL")
out <- file.path(pilot,"26_venezuela_transfer_DIAGNOSTIC_NOT_FINAL")
dir.create(out, recursive=TRUE, showWarnings=FALSE)
files <- c(
  suitability=file.path(pilot,"09_pilot_south_america_LQ_rm2_cloglog_NOT_FINAL.tif"),
  mess=file.path(nov,"27_sa_MESS_5m_EXPLORATORY.tif"),
  mop=file.path(nov,"29_sa_MOP_nearest1pct_distance_5m_EXPLORATORY.tif"),
  driver=file.path(nov,"28_sa_MESS_limiting_variable_5m_EXPLORATORY.tif")
)
missing <- files[!file.exists(files)]
if(length(missing)) stop("R26 requires R11 and R25 rasters. Missing: ", paste(missing, collapse="; "))
sitefile <- getOption("phalangium.venezuela_sites_csv", NULL)
if(is.null(sitefile) || length(sitefile)!=1L || !file.exists(sitefile)) stop(
  "Explicitly set options(phalangium.venezuela_sites_csv='FULL_PATH_TO_INDEPENDENT_CSV'). ",
  "This safeguard prevents accidentally using training/GBIF calibration records.")
sites <- read.csv(sitefile, stringsAsFactors=FALSE, check.names=FALSE)
lon_name <- intersect(c("longitude","decimalLongitude","lon","longitud"), names(sites))
lat_name <- intersect(c("latitude","decimalLatitude","lat","latitud"), names(sites))
if(!length(lon_name)||!length(lat_name)) stop("CSV requires longitude/latitude or decimalLongitude/decimalLatitude")
lon <- suppressWarnings(as.numeric(sites[[lon_name[1]]]))
lat <- suppressWarnings(as.numeric(sites[[lat_name[1]]]))
if(!nrow(sites) || any(!is.finite(lon)|!is.finite(lat))) stop("Missing/nonfinite site coordinates")
# Broad Venezuela geographical guard; manually review geographic/biological provenance.
if(any(lon < -74.5 | lon > -59.0 | lat < 0.0 | lat > 13.0)) stop("Some coordinates fall outside the broad Venezuelan bounding region. Audit inputs")
ids <- intersect(c("site_id","locality","gbifID","localidad"), names(sites))
site_id <- if(length(ids)) as.character(sites[[ids[1]]]) else sprintf("VE_%03d",seq_len(nrow(sites)))
site_id[is.na(site_id)|!nzchar(site_id)] <- sprintf("VE_%03d",which(is.na(site_id)|!nzchar(site_id)))
if(anyDuplicated(site_id)) site_id <- make.unique(site_id)
r <- lapply(files, terra::rast)
if(terra::nlyr(r$mess)!=5L) stop("Expected R25 MESS raster with 5 layers; final overall MESS is fifth")
r$mess <- r$mess[[5]]
# These are four independent point extractions, NOT raster algebra.
# The rasters may have different extents, origins or grid dimensions.
# This does not affect extracting values at the same WGS84 coordinates.
# Record every source grid's native geometry to make this explicit.
geometry <- do.call(rbind, lapply(names(r), function(nm) {
  z <- r[[nm]]
  if (terra::nlyr(z) != 1L || !isTRUE(terra::is.lonlat(z))) {
    stop("Expected a single-layer geographic raster: ", nm)
  }
  if (!isTRUE(terra::same.crs(r$suitability, z))) {
    stop("Raster CRS differs: ", nm,
         ". Do not silently reinterpret coordinates or resample rasters.")
  }
  ex <- terra::ext(z)
  rr <- terra::res(z)
  data.frame(raster=nm, source=normalizePath(files[[nm]],winslash="/"),
             xmin=terra::xmin(z), xmax=terra::xmax(z),
             ymin=terra::ymin(z), ymax=terra::ymax(z),
             res_x=rr[1], res_y=rr[2],
             nrow=terra::nrow(z), ncol=terra::ncol(z),
             stringsAsFactors=FALSE)
}))
utils::write.csv(geometry, file.path(out,"25_R26_input_raster_geometry.csv"),
                 row.names=FALSE)
cat("[R26-v3] Input raster grids inspected; independent point extraction ",
    "does NOT require the same grid origin or extent.\n",sep="")
print(geometry[,c("raster","xmin","xmax","ymin","ymax","res_x","res_y")],
      row.names=FALSE)
# Deliberately no terra::resample(), terra::project(SpatRaster) or
# pixel-to-pixel raster operations are performed.
rg <- terra::global(r$suitability,"range",na.rm=TRUE)
if(!all(is.finite(as.matrix(rg))) || min(as.matrix(rg)) < -.001 || max(as.matrix(rg)) > 1.001) stop("Suitability values outside [0,1]")
xy <- cbind(lon,lat)
# terra::extract(SpatRaster, matrix) does NOT accept ID=FALSE.
# The returned table must have one value column for a single-layer raster.
extract_one <- function(x, label) {
  extracted <- terra::extract(x, xy)
  if (nrow(extracted) != nrow(xy) || ncol(extracted) != 1L) {
    stop("Unexpected extraction shape for ", label,
         ": expected ", nrow(xy), " rows and 1 value column; got ",
         nrow(extracted), " rows and ", ncol(extracted), " columns.")
  }
  as.numeric(extracted[[1]])
}
suit <- extract_one(r$suitability, "suitability")
mess <- extract_one(r$mess, "mess")
mop <- extract_one(r$mop, "mop")
driver <- extract_one(r$driver, "driver")
extraction_counts <- vapply(list(suitability=suit, mess=mess, mop=mop,
                                 driver=driver),
                            function(v) sum(is.finite(v)), integer(1))
cat("[R26-v3] Non-missing extracted values per raster:\n")
print(extraction_counts)
if (any(extraction_counts == 0L)) {
  stop("At least one raster returned NO valid values at the Venezuelan ",
       "sites. Check the raster extents, coordinates and CRS; no ",
       "resampling has been attempted.")
}
if (any(extraction_counts < nrow(sites))) {
  warning("One or more sites have NA in at least one source raster. ",
          "Inspect the CSV output and check ocean/coastal or NA cells.")
}
key <- c("BIO1","BIO4","BIO12","BIO15")
driver_name <- rep(NA_character_,length(driver))
ok <- !is.na(driver) & driver %in% seq_along(key)
driver_name[ok] <- key[as.integer(driver[ok])]
tab <- data.frame(site_id=site_id, longitude=lon,latitude=lat,
  suitability_cloglog=suit,MESS=mess,MOP_distance=mop,
  MESS_limiting_variable=driver_name,
  univariate_extrapolation=ifelse(is.na(mess),NA,mess<0),
  environmental_context=ifelse(is.na(mess)|is.na(mop)|is.na(suit),
    "outside_valid_raster_or_missing",ifelse(mess<0,"univariate_novelty","within_univariate_ranges")),
  stringsAsFactors=FALSE)
write.csv(tab,file.path(out,"26_venezuela_site_transfer_values.csv"),row.names=FALSE,na="")
if(all(is.na(tab$suitability_cloglog))) stop("All site suitability values are missing; inspect raster and coordinate order")
# Do not produce an external AUC from presence-only records or describe threshold-free suitability as occupancy.
summary <- data.frame(
  sites=nrow(tab),sites_complete=sum(complete.cases(tab[,c("suitability_cloglog","MESS","MOP_distance")])),
  sites_MESS_negative=sum(tab$MESS<0,na.rm=TRUE),
  median_suitability=if(all(is.na(suit))) NA_real_ else median(suit,na.rm=TRUE),
  median_MESS=if(all(is.na(mess))) NA_real_ else median(mess,na.rm=TRUE),
  median_MOP=if(all(is.na(mop))) NA_real_ else median(mop,na.rm=TRUE),
  baseline="LQ_rm2_cloglog_pilot",reference="fixed_rectangle_NOT_demonstrated_M",
  validation_status="descriptive_independent_site_extraction_NOT_external_validation")
write.csv(summary,file.path(out,"27_venezuela_transfer_summary.csv"),row.names=FALSE)
# Figure maps use unchanged original raster pixel values; overlays are point locations only.
map <- function(which, filename, ttl) {
  png(filename,width=2200,height=1750,res=250)
  tryCatch({terra::plot(r[[which]],main=ttl);points(xy,pch=21,bg="white",col="black",cex=.7)},
           finally=dev.off())
}
map("suitability",file.path(out,"28_suitability_venezuela_points_DIAGNOSTIC.png"),"Climatic suitability (pilot) and withheld Venezuelan sites")
map("mess",file.path(out,"29_MESS_venezuela_points_DIAGNOSTIC.png"),"MESS: rectangle-based reference, not M")
map("mop",file.path(out,"30_MOP_venezuela_points_DIAGNOSTIC.png"),"MOP distance: rectangle-based reference, not M")
writeLines(c(
  "R26-v3 independent Venezuelan-site descriptive transfer diagnostic",
  "Geometry: all rasters must have compatible geographic CRS; matching pixel grids NOT required.",
  "Each raster extracted independently at the original WGS84 site coordinates.",
  "NO resampling, raster projection, interpolation or raster stacking applied.",
  "terra::extract uses the matrix (x, y) method, without ID=FALSE",
  "Fixed operational rectangle: -12 to 60 longitude; 30 to 72 latitude; NOT validated M.",
  "R25 MESS/MOP are based on 5000 reference cells sampled from complete rectangle, seed 251018.",
  "R25 continuous MOP = mean distance of closest 1% (50) on reference-standardized climate values.",
  "Suitability comes from previously fitted LQ/RM2 pilot, not a final re-fitted SDM.",
  "No model re-fitting, tuning, threshold selection or site-based calibration occurs.",
  "MESS<0 means at least one predictor outside sampled reference ranges.",
  "MOP is continuous; no post hoc novelty threshold was selected.",
  "Site provenance and independence MUST be audited before any external-validation claims.",
  "Do not use this presence-only site dataset to report AUC or validated predictive accuracy.",
  paste("Independent input:",normalizePath(sitefile,winslash="/")),
  paste("R:",R.version.string),
  paste("terra:",as.character(packageVersion("terra")))
),file.path(out,"31_R26_provenance_README.txt"))
cat("\n[R26-v3] COMPLETE - descriptive site-level transfer diagnostic, NOT external validation\n")
print(summary,row.names=FALSE)
print(tab,row.names=FALSE)
cat("[R26] Outputs:",normalizePath(out,winslash="/"),"\n")
