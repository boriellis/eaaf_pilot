
# Part 1: Load packages & set parameters --------------------------------------


packages <- c("tidyverse", "sf", "terra", "tidyterra", "here", "janitor")
pacman::p_load(packages, character.only = TRUE); rm(packages)


# Part 2: Load data -------------------------------------------------------

eaaf <- vect(here::here("data/raw/EAAF/EAAF_polygon.shp"))
plot(eaaf)

wind <- read_csv(here::here("data/raw/gwpt_summary_feb26.csv"))
ranges <- vect(here::here("data/raw/priority_sp_ranges_shp/pbsr.shp"))


# Part 3: Clean names & filter ---------------------------------------------

wind_clean <- wind %>%
  clean_names() %>%
  filter(installation_type %in% c("Offshore hard mount",
                                  "Offshore mount unknown",
                                  "Offshore floating")) %>%
  filter(!status %in% c("shelved", "shelved - inferred 2 y",
                        "mothballed",
                        "cancelled", "cancelled - inferred 4 y",
                        "retired"))
wind_clean %>% count(status)
wind_clean %>% count(installation_type)

nrow(wind_clean)


# Part 4: Filter to points within the EAAF polygon --------------------------

crs(eaaf)
wind_pts <- vect(wind_clean,
                 geom = c("longitude", "latitude"),
                 crs = "EPSG:4326")
if (crs(eaaf) != crs(wind_pts)) {
  wind_pts <- project(wind_pts, crs(eaaf))
}
in_eaaf <- is.related(wind_pts, eaaf, relation = "intersects")

wind_eaaf <- wind_pts[in_eaaf, ]

# sanity checks
nrow(wind_eaaf)
plot(eaaf)
points(wind_eaaf, col = "red", pch = 20)


# Part 5: Capacity -> footprint polygons -------------------------------------

# capacity-density assumptions (MW/km2), per our discussion:
#   fixed-bottom ("Offshore hard mount")    : 6   MW/km2  (European as-built avg; Baltic LINes 2018)
#   floating     ("Offshore floating")      : 3   MW/km2  (BOEM/NREL CA lease planning assumption)
#   unknown      ("Offshore mount unknown") : 4.5 MW/km2  (average of the two)

density_lookup <- c(
  "Offshore hard mount"     = 6,
  "Offshore floating"       = 3,
  "Offshore mount unknown"  = 4.5
)

# reproject back to geographic coords (EPSG:4326) before buffering 
wind_geo <- project(wind_eaaf, "EPSG:4326")

wind_geo$density_mw_km2 <- density_lookup[wind_geo$installation_type]

# flag anything that didn't match the lookup before silently propagating NAs
if (any(is.na(wind_geo$density_mw_km2))) {
  warning("Unmatched installation_type values: ",
          paste(unique(wind_geo$installation_type[is.na(wind_geo$density_mw_km2)]), collapse = ", "))
}

# area (km2) implied by capacity + density -> radius (m) of an equivalent circle
wind_geo$area_km2 <- wind_geo$capacity_mw / wind_geo$density_mw_km2
wind_geo$radius_m <- sqrt(wind_geo$area_km2 * 1e6 / pi)

# buffer each point by its own radius -> circular footprint polygons
wind_footprints <- buffer(wind_geo, width = wind_geo$radius_m)

# back to eaaf's CRS for the final output
wind_footprints <- project(wind_footprints, crs(eaaf))

# sanity checks
plot(eaaf)
plot(wind_footprints, add = TRUE, col = "red", border = NA)

head(as.data.frame(wind_footprints)[, c("project_name", "capacity_mw",
                                        "installation_type", "density_mw_km2",
                                        "area_km2", "radius_m")])
summary(wind_footprints$radius_m)


# Part 6: Write out -----------------------------------------------------------

writeVector(wind_footprints,
            here::here("data/processed/EAAF_offshore_wind_footprints.shp"),
            overwrite = TRUE)

test <- vect(here::here("data/processed/EAAF_offshore_wind_footprints.shp"))
plot(test)


# check field names first
names(ranges_shp)

# pull the attribute table only (skip geometry - much faster on a 1.2GB file)
ranges_attr <- as.data.frame(ranges_shp)

# how many rows / unique species?
nrow(ranges_attr)
n_distinct(ranges_attr$sci_name)   

# peek at the full attribute structure
glimpse(ranges_attr)
unique(ranges_attr$legend)




# Check: does a species' resident polygon spatially overlap its own
# breeding/non-breeding/passage polygon(s)? This determines whether the
# additive weighting scheme risks double-counting area for any species.

ranges_shp$season <- case_when(
  str_detect(ranges_shp$SEASONAL, "non-breeding") ~ "non-breeding",
  str_detect(ranges_shp$SEASONAL, "\\bbreeding")   ~ "breeding",
  str_detect(ranges_shp$SEASONAL, "resident")      ~ "resident",
  str_detect(ranges_shp$SEASONAL, "passage")       ~ "passage",
  TRUE ~ NA_character_
)

resident_polys    <- ranges_shp[ranges_shp$season == "resident" & !is.na(ranges_shp$season), ]
nonresident_polys <- ranges_shp[ranges_shp$season %in% c("breeding", "non-breeding", "passage"), ]

# how many species even have BOTH a resident polygon and another season polygon mapped?
species_both <- intersect(unique(resident_polys$SCINAME), unique(nonresident_polys$SCINAME))
length(species_both)

# for those species, check whether the geometries actually overlap in space
# (having both categories mapped doesn't guarantee they're in the same place)
overlap_check <- map_dfr(species_both, function(sp) {
  r  <- resident_polys[resident_polys$SCINAME == sp, ]
  nr <- nonresident_polys[nonresident_polys$SCINAME == sp, ]
  
  ov <- tryCatch(terra::intersect(r, nr), error = function(e) NULL)
  
  overlap_area_m2  <- if (!is.null(ov) && nrow(ov) > 0) sum(expanse(ov, unit = "m")) else 0
  resident_area_m2 <- sum(expanse(r, unit = "m"))
  
  tibble(
    SCINAME = sp,
    resident_area_m2 = resident_area_m2,
    overlap_with_nonresident_m2 = overlap_area_m2,
    pct_resident_overlapping = overlap_area_m2 / resident_area_m2
  )
})

overlap_check %>%
  filter(pct_resident_overlapping > 0) %>%
  arrange(desc(pct_resident_overlapping))

nrow(overlap_check %>% filter(pct_resident_overlapping > 0))





# Part 7: Classify SEASONAL into season + weight ------------------------------

weight_lookup <- c(
  "resident"     = 1,
  "breeding"     = 1/3,
  "non-breeding" = 1/3,
  "passage"      = 1/3
)

ranges_shp$season <- case_when(
  str_detect(ranges_shp$SEASONAL, "non-breeding")        ~ "non-breeding",
  str_detect(ranges_shp$SEASONAL, "\\bbreeding")           ~ "breeding",   # after non-breeding so it doesn't double-match
  str_detect(ranges_shp$SEASONAL, "resident")             ~ "resident",
  str_detect(ranges_shp$SEASONAL, "passage")              ~ "passage",
  TRUE ~ NA_character_   # Extinct, Possibly Extinct, seasonality uncertain - deliberately unweighted for now
)

# review before proceeding - confirm nothing unexpected fell into NA
ranges_shp %>% as.data.frame() %>% count(SEASONAL, season)

ranges_shp$season_weight <- weight_lookup[ranges_shp$season]


# Part 8: Trim ranges to the EAAF, drop unweighted rows -----------------------

ranges_eaaf <- intersect(ranges_shp, eaaf) %>%
  filter(!is.na(season))   # drops Extinct/Possibly Extinct/seasonality uncertain for now - flagged, not silent


# Part 9: Dissolve wind footprints into one geometry --------------------------
# (so overlapping circles from nearby projects aren't double-counted as overlap area)

wind_dissolved <- aggregate(wind_footprints)


# Part 10: Per-species-per-season range area & overlap area -------------------

ranges_eaaf$range_area_m2 <- expanse(ranges_eaaf, unit = "m")

overlap_geom <- intersect(ranges_eaaf, wind_dissolved)
overlap_geom$overlap_area_m2 <- expanse(overlap_geom, unit = "m")

overlap_df <- as.data.frame(overlap_geom) %>%
  select(SCINAME, season, season_weight, overlap_area_m2) %>%
  group_by(SCINAME, season, season_weight) %>%
  summarise(overlap_area_m2 = sum(overlap_area_m2), .groups = "drop")

range_df <- as.data.frame(ranges_eaaf) %>%
  select(SCINAME, season, season_weight, range_area_m2) %>%
  group_by(SCINAME, season, season_weight) %>%
  summarise(range_area_m2 = sum(range_area_m2), .groups = "drop")

# species/seasons with zero overlap won't appear in overlap_df - left join + 0 fill
species_season <- range_df %>%
  left_join(overlap_df, by = c("SCINAME", "season", "season_weight")) %>%
  mutate(overlap_area_m2 = replace_na(overlap_area_m2, 0))


# Part 11: Weighted overlap proportion per species -----------------------------

species_overlap <- species_season %>%
  group_by(SCINAME) %>%
  summarise(
    seasons_present   = paste(sort(unique(season)), collapse = ", "),
    weighted_overlap   = sum(season_weight * overlap_area_m2),
    weighted_range     = sum(season_weight * range_area_m2),
    pct_overlap        = weighted_overlap / weighted_range,
    .groups = "drop"
  ) %>%
  arrange(desc(pct_overlap))

species_overlap
