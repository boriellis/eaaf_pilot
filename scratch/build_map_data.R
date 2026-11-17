# =============================================================================
# build_map_data.R  --  pre-process range / wind-overlap data for the app's
#                       "Exposure explorer" tab
#
# Self-contained: PART A rebuilds only what is needed from exposure_scratch.R
# (Parts 1-11 minus plots, sanity checks and the CSV writing) and CACHES the slow
# geometry steps to data/processed/cache/. First run is slow; reruns load the cache.
# If you change the wind data, legend rules or EAAF polygon, delete the cache folder.
#
# PART B then writes (into ./map_data/ inside the app folder):
#   map_data/wind_footprints.rds     sf polygons + fid, lon/lat (shifted, see below)
#   map_data/wind_points.rds         sf centroids of the footprints (visible when zoomed out)
#   map_data/species_index.csv       one row per species: has_map, overlap stats, note
#   map_data/ranges/<slug>.rds       per species: ranges (sf), overlap (sf), hit ids, stats
#
# Work through it block by block (it is written to be tested as you go).
# =============================================================================


# ############################ PART A: SETUP ###################################

packages <- c("tidyverse", "sf", "terra", "here", "janitor")
pacman::p_load(packages, character.only = TRUE); rm(packages)

cache_dir <- here::here("data/processed/cache")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

# ---- A1: EAAF polygon + offshore wind footprints (same logic as exposure_scratch Parts 2-6) ----
eaaf <- vect(here::here("data/raw/EAAF/EAAF_polygon.shp"))
wind <- read_csv(here::here("data/raw/gwpt_summary_feb26.csv"))

wind_clean <- wind %>%
  clean_names() %>%
  filter(installation_type %in% c("Offshore hard mount", "Offshore mount unknown", "Offshore floating")) %>%
  filter(!status %in% c("shelved", "shelved - inferred 2 y", "mothballed",
                        "cancelled", "cancelled - inferred 4 y", "retired"))

wind_pts <- vect(wind_clean, geom = c("longitude", "latitude"), crs = "EPSG:4326")
if (crs(eaaf) != crs(wind_pts)) wind_pts <- project(wind_pts, crs(eaaf))
wind_eaaf <- wind_pts[is.related(wind_pts, eaaf, relation = "intersects"), ]

# capacity -> circular footprint (MW/km2: fixed 6, floating 3, unknown 4.5)
density_lookup <- c("Offshore hard mount" = 6, "Offshore floating" = 3, "Offshore mount unknown" = 4.5)
wind_geo <- project(wind_eaaf, "EPSG:4326")
wind_geo$density_mw_km2 <- density_lookup[wind_geo$installation_type]
if (any(is.na(wind_geo$density_mw_km2))) warning("Unmatched installation_type values")
wind_geo$area_km2 <- wind_geo$capacity_mw / wind_geo$density_mw_km2
wind_geo$radius_m <- sqrt(wind_geo$area_km2 * 1e6 / pi)
wind_footprints <- project(buffer(wind_geo, width = wind_geo$radius_m), crs(eaaf))
nrow(wind_footprints)    # sanity: should match what you had before

# equal-area CRS for all area maths + one dissolved wind layer
crs_ea <- "EPSG:8857"
wind_dissolved <- aggregate(project(wind_footprints, crs_ea))

# ---- A2: lookups (Part 7 / 11 of the exposure script) ----
legend_lookup <- tribble(
  ~legend,                                     ~season,        ~status,            ~flag,           ~include,
  "Extant (resident)",                         "resident",     "extant",           NA,              TRUE,
  "Extant (breeding)",                         "breeding",     "extant",           NA,              TRUE,
  "Extant (non-breeding)",                     "non-breeding", "extant",           NA,              TRUE,
  "Extant (passage)",                          "passage",      "extant",           NA,              TRUE,
  "Extant & Reintroduced (resident)",          "resident",     "extant",           "reintroduced",  TRUE,
  "Extant & Reintroduced (passage)",           "passage",      "extant",           "reintroduced",  TRUE,
  "Possibly Extant (resident)",                "resident",     "possibly extant",  NA,              TRUE,
  "Possibly Extant (breeding)",                "breeding",     "possibly extant",  NA,              TRUE,
  "Possibly Extant (non-breeding)",            "non-breeding", "possibly extant",  NA,              TRUE,
  "Possibly Extant (passage)",                 "passage",      "possibly extant",  NA,              TRUE,
  # excluded for now - decide on these separately
  "Extant (seasonality uncertain)",            "uncertain",    "extant",           NA,              FALSE,
  "Possibly Extant (seasonality uncertain)",   "uncertain",    "possibly extant",  NA,              FALSE,
  "Extant & Vagrant (seasonality uncertain)",  "uncertain",    "extant",           "vagrant",       FALSE,
  "Extinct",                                   NA,             "extinct",          NA,              FALSE,
  "Possibly Extinct",                          NA,             "possibly extinct", NA,              FALSE
)
weight_lookup <- c("resident" = 1, "breeding" = 1/3, "non-breeding" = 1/3, "passage" = 1/3)
months_lookup <- c("resident" = 12, "breeding" = 4, "non-breeding" = 4, "passage" = 4)

# ---- A3: ranges clipped to the EAAF (slow: cached as a GeoPackage) ----
f_rng <- file.path(cache_dir, "ranges_eaaf.gpkg")
if (file.exists(f_rng)) {
  ranges_eaaf <- vect(f_rng)
} else {
  rng_path <- here::here("data/raw/priority_sp_ranges_shp/pbsr.shp")

  # EAAF boundary in the ranges' native CRS (read from the file header only), dissolved to one geometry
  eaaf_native <- aggregate(project(eaaf, crs(vect(rng_path, proxy = TRUE))))

  # read ONLY polygons whose bounding box touches the EAAF (much faster / lighter than the whole 1.2 GB)
  ranges_shp <- vect(rng_path, extent = ext(eaaf_native))

  idx <- match(str_squish(ranges_shp$legend), legend_lookup$legend)
  if (any(is.na(idx))) stop("Unmatched legend values: ", paste(unique(ranges_shp$legend[is.na(idx)]), collapse = "; "))
  ranges_shp$season        <- legend_lookup$season[idx]
  ranges_shp$range_status  <- legend_lookup$status[idx]
  ranges_shp$range_flag    <- legend_lookup$flag[idx]
  ranges_shp$include       <- legend_lookup$include[idx]
  ranges_shp$season_weight <- ifelse(ranges_shp$include, weight_lookup[ranges_shp$season], NA_real_)

  ranges_inc  <- makeValid(ranges_shp[!is.na(ranges_shp$season_weight), ])   # drop excluded rows first
  ranges_eaaf <- terra::intersect(ranges_inc, eaaf_native)                          # clip to the flyway
  ranges_eaaf <- makeValid(project(ranges_eaaf, crs_ea))
  writeVector(ranges_eaaf, f_rng, overwrite = TRUE)
  rm(ranges_shp, ranges_inc)
}
nrow(ranges_eaaf); n_distinct(ranges_eaaf$sci_name)

# ---- A4: dissolve to species x season, overlap with wind (cached) ----
f_rd <- file.path(cache_dir, "ranges_dissolved.gpkg")
f_ov <- file.path(cache_dir, "overlap_geom.gpkg")
if (file.exists(f_rd) && file.exists(f_ov)) {
  ranges_dissolved <- vect(f_rd)
  overlap_geom     <- vect(f_ov)
} else {
  ranges_dissolved <- aggregate(ranges_eaaf, by = c("sci_name", "season", "season_weight"))
  ranges_dissolved$range_area_km2 <- expanse(ranges_dissolved, unit = "km")
  overlap_geom <- terra::intersect(ranges_dissolved, wind_dissolved)
  overlap_geom$overlap_area_km2 <- expanse(overlap_geom, unit = "km")
  writeVector(ranges_dissolved, f_rd, overwrite = TRUE)
  writeVector(overlap_geom,     f_ov, overwrite = TRUE)
}

# ---- A5: tables (same as exposure_scratch Part 10 / 11) ----
range_df <- as.data.frame(ranges_dissolved) %>% select(sci_name, season, season_weight, range_area_km2)
overlap_df <- as.data.frame(overlap_geom) %>%
  group_by(sci_name, season, season_weight) %>%
  summarise(overlap_area_km2 = sum(overlap_area_km2), .groups = "drop")

species_season <- range_df %>%
  left_join(overlap_df, by = c("sci_name", "season", "season_weight")) %>%
  mutate(overlap_area_km2 = replace_na(overlap_area_km2, 0),
         pct_overlap_season = overlap_area_km2 / range_area_km2,
         months = months_lookup[season])
stopifnot(all(species_season$range_area_km2 > 0))

# species_out = the CSV you already wrote (every species in the raw file, incl. those with no EAAF range)
species_out <- read_csv(here::here("data/processed/species_wind_overlap.csv"))

# quick consistency check: recomputed overall overlap should match the CSV
chk <- species_season %>% group_by(sci_name) %>%
  summarise(ov = sum(months * pct_overlap_season) / sum(months), .groups = "drop") %>%
  left_join(species_out %>% select(sci_name, overlap_overall), by = "sci_name")
max(abs(chk$ov - chk$overlap_overall), na.rm = TRUE)      # want ~0 (< 1e-6)


# ############################ PART B: BUILD MAP DATA ##########################

# ---- Settings ---------------------------------------------------------------
out_dir   <- here::here("app/")   # change to wherever the app folder is, e.g. "app/map_data"
shift_lon <- TRUE    # TRUE: longitudes < 0 become +360, so the Pacific is continuous
                     # (Leaflet handles lng > 180). Set FALSE to keep -180..180.
simp_frac <- 0.002   # simplification tolerance = simp_frac * sqrt(range area), in metres...
simp_max  <- 3000    # ...but never more than this (m). Tiny ranges end up barely simplified.
simp_min  <- 5       # below this tolerance (m) skip simplification entirely
include_uncertain <- FALSE  # optional grey "seasonality uncertain" polygons (see Part 6; slow)

dir.create(file.path(out_dir, "ranges"), recursive = TRUE, showWarnings = FALSE)

# ---- Part 0: sanity (Part A built everything we need) ----
nrow(ranges_dissolved); n_distinct(ranges_dissolved$sci_name)   # species-seasons / species

# ---- Helpers -------------------------------------------------------------------
slugify <- function(x) str_replace_all(str_to_lower(x), "[^a-z]+", "_") %>% str_remove("_$")

# SpatVector (any CRS) -> sf in lon/lat (optionally shifted to 0-360)
to_web <- function(v) {
  s <- sf::st_as_sf(project(v, "EPSG:4326"))
  if (shift_lon) s <- sf::st_shift_longitude(s)
  s
}

# simplify each feature with a tolerance scaled to its own area (keeps tiny ranges intact)
simplify_adaptive <- function(v) {
  out <- lapply(seq_len(nrow(v)), function(i) {
    vi  <- v[i, ]
    tol <- min(simp_max, simp_frac * sqrt(vi$range_area_km2 * 1e6))
    if (tol < simp_min) return(vi)
    s <- tryCatch(makeValid(simplifyGeom(vi, tolerance = tol)), error = function(e) vi)
    if (nrow(s) == 0 || all(is.na(expanse(s)))) vi else s    # fall back if simplification empties it
  })
  do.call(rbind, out)
}

# ---- Part 1: wind footprints (one file for the whole flyway) -----------------------
wind_ea <- project(wind_footprints, crs_ea)
wind_ea$fid <- seq_len(nrow(wind_ea))        # id used to say "this footprint touches this range"

keep_cols <- base::intersect(c("fid", "project_name", "country_area", "capacity_mw",
                         "installation_type", "status"), names(wind_ea))
wind_sf  <- to_web(wind_ea[, keep_cols])
wind_pts <- to_web(centroids(wind_ea)[, keep_cols])

saveRDS(wind_sf,  file.path(out_dir, "wind_footprints.rds"))
saveRDS(wind_pts, file.path(out_dir, "wind_points.rds"))
nrow(wind_sf)                                              # sanity: matches nrow(wind_footprints)

# ---- Part 2: build the per-species object -------------------------------------------
build_species <- function(sp) {
  rd <- ranges_dissolved[ranges_dissolved$sci_name == sp, ]
  if (nrow(rd) == 0) return(NULL)

  # which footprints touch each season's range? (tested on the UNsimplified range)
  hit <- lapply(seq_len(nrow(rd)), function(i) wind_ea$fid[is.related(wind_ea, rd[i, ], "intersects")])
  names(hit) <- rd$season

  # per-season numbers straight from the exposure calc, so the app matches the table exactly
  stats <- species_season %>%
    filter(sci_name == sp) %>%
    mutate(months = c(resident = 12, breeding = 4, `non-breeding` = 4, passage = 4)[season],
           n_wind_touching = lengths(hit)[season]) %>%
    select(sci_name, season, months, range_area_km2, overlap_area_km2,
           pct_overlap_season, n_wind_touching)

  # ranges for display (simplified), overlap polygons (as calculated, not simplified)
  rng_sf <- to_web(simplify_adaptive(rd)[, c("sci_name", "season", "season_weight", "range_area_km2")])
  ov     <- overlap_geom[overlap_geom$sci_name == sp, ]
  ov_sf  <- if (nrow(ov) > 0) to_web(ov[, c("sci_name", "season")]) else NULL

  list(species = sp, ranges = rng_sf, overlap = ov_sf, hit = hit, stats = stats)
}

# ---- Part 3: TEST ON ONE SPECIES FIRST ------------------------------------------------
# A tiny range, then a big one. Check the size, then look at it.
test_sp <- "Thalasseus bernsteini"
obj <- build_species(test_sp)
obj$stats                         # compare with species_season / your earlier plots
obj$hit                           # footprint ids per season
print(object.size(obj), units = "Kb")
plot(sf::st_geometry(obj$ranges), col = "#2a9d8f55", axes = TRUE)   # quick look
if (!is.null(obj$overlap)) plot(sf::st_geometry(obj$overlap), col = "red", add = TRUE)

big_sp <- species_season %>% slice_max(range_area_km2, n = 1) %>% pull(sci_name)
print(object.size(build_species(big_sp)), units = "Mb")             # want well under ~1 Mb

# ---- Part 4: loop over every species -----------------------------------------------------
sp_all <- sort(unique(ranges_dissolved$sci_name))
fails  <- character()
for (sp in sp_all) {
  obj <- tryCatch(build_species(sp), error = function(e) { message("FAILED: ", sp, " - ", conditionMessage(e)); NULL })
  if (is.null(obj)) { fails <- c(fails, sp); next }
  saveRDS(obj, file.path(out_dir, "ranges", paste0(slugify(sp), ".rds")))
}
fails                                                      # want character(0)

# total size of what the app will have to ship
f <- list.files(out_dir, recursive = TRUE, full.names = TRUE)
sum(file.size(f)) / 1e6                                    # MB; shinyapps.io is fine up to a few hundred

# ---- Part 5: species index (what the dropdown reads) -----------------------------------------
# one row for EVERY species in the raw file, so species without a map still get a message
species_index <- species_out %>%
  mutate(has_map = sci_name %in% sp_all,
         file    = if_else(has_map, paste0("ranges/", slugify(sci_name), ".rds"), NA_character_)) %>%
  select(sci_name, has_map, file, overlap_overall_pct, seasons_present, months_covered, note,
         starts_with("pct_overlap_season_"), starts_with("range_area_km2_"))

write_csv(species_index, file.path(out_dir, "species_index.csv"))
count(species_index, has_map)

# ---- Part 5b: coverage vs the app's species lists (the name check we did earlier) -------------
# adjust paths to the app folder
app_sp <- bind_rows(read_csv("app/seabird_all_species_v2.csv")    %>% mutate(group = "seabird"),
                    read_csv("app/nonseabird_data_v2.csv")        %>% mutate(group = "nonseabird")) %>%
  mutate(scientific_name = str_squish(scientific_name))
app_sp %>% count(group, has_map = scientific_name %in% sp_all)             # coverage per group
app_sp %>% filter(!scientific_name %in% sp_all) %>%
  select(group, common_name, scientific_name)                              # these will show "no map"

# ---- Part 6 (optional, slow): grey "seasonality uncertain" polygons ------------------------------
# Shows what the exposure calc EXCLUDES. Needs ranges_shp + eaaf from the exposure script and a
# second EAAF clip, so it is OFF by default. Left here for later; not needed for tomorrow.
if (include_uncertain) {
  unc <- ranges_shp[ranges_shp$season %in% "uncertain", ]
  unc <- makeValid(unc)
  unc <- terra::intersect(unc, aggregate(project(eaaf, crs(unc))))
  unc <- aggregate(project(makeValid(unc), crs_ea), by = "sci_name")
  unc$range_area_km2 <- expanse(unc, unit = "km")
  unc <- simplify_adaptive(unc)
  saveRDS(to_web(unc[, c("sci_name", "range_area_km2")]), file.path(out_dir, "uncertain_ranges.rds"))
}

