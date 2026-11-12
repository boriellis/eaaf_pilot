
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



# Ranges ------------------------------------------------------------------

ranges_shp <- vect(here::here("data/raw/priority_sp_ranges_shp/pbsr.shp"))

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


# Part 7: Classify `legend` into season + weight ------------------------------

# One row per legend value present in the data (15). Explicit lookup instead of
# regex so every include/exclude decision is auditable.
#   include = FALSE -> excluded from the weighted overlap for now (flagged, not silent)
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

# annual-cycle weights: resident = full year, each non-resident category = 1/3
weight_lookup <- c(
  "resident"     = 1,
  "breeding"     = 1/3,
  "non-breeding" = 1/3,
  "passage"      = 1/3
)

# match onto the SpatVector (str_squish guards against stray whitespace)
idx <- match(str_squish(ranges_shp$legend), legend_lookup$legend)

# fail loudly if any legend value isn't in the lookup
if (any(is.na(idx))) {
  stop("Unmatched legend values: ",
       paste(unique(ranges_shp$legend[is.na(idx)]), collapse = "; "))
}

ranges_shp$season        <- legend_lookup$season[idx]
ranges_shp$range_status  <- legend_lookup$status[idx]
ranges_shp$range_flag    <- legend_lookup$flag[idx]
ranges_shp$include       <- legend_lookup$include[idx]

# weight is NA for anything excluded, so it can't leak into sums by accident
ranges_shp$season_weight <- ifelse(ranges_shp$include,
                                   weight_lookup[ranges_shp$season],
                                   NA_real_)

# review: how many polygons land in each bucket?
ranges_shp %>%
  as.data.frame() %>%
  count(legend, season, include, season_weight)


# Part 8: Trim ranges to the EAAF ---------------------------------------------

# Equal-area CRS for all area math. EPSG:3857 (Web Mercator) inflates area toward
# the poles, which would distort overlap proportions across the EAAF's latitude range.
crs_ea <- "EPSG:8857"   # Equal Earth

# 1. drop excluded rows first, so every later step runs on less data
ranges_inc <- ranges_shp[!is.na(ranges_shp$season_weight), ]
nrow(ranges_shp)
nrow(ranges_inc)

# 2. repair invalid geometries (common in range maps, and intersect can fail without this)
ranges_inc <- makeValid(ranges_inc)

# 3. EAAF boundary -> ranges' native CRS, dissolved to one attribute-free geometry
#    (so the clipped ranges keep only their own attributes, with no suffixed duplicates)
eaaf_native <- aggregate(project(eaaf, crs(ranges_inc)))

# 4. clip ranges to the flyway
ranges_eaaf <- intersect(ranges_inc, eaaf_native)

# 5. project to equal-area for the area calculations in Part 10
ranges_eaaf <- project(ranges_eaaf, crs_ea)
ranges_eaaf <- makeValid(ranges_eaaf) #repair again

# sanity checks
nrow(ranges_eaaf)
n_distinct(ranges_eaaf$sci_name)   # swap in your actual species column
ranges_eaaf %>% as.data.frame() %>% count(season)

plot(project(eaaf, crs_ea))
plot(ranges_eaaf[ranges_eaaf$sci_name == unique(ranges_eaaf$sci_name)[1], ],
     add = TRUE, col = "#ff000055")


# Part 9: dissolve wind footprints, in the same equal-area CRS as the ranges
wind_dissolved <- aggregate(project(wind_footprints, crs_ea))


# Part 10: Per species-season range area & wind overlap area -------------------

# 1. Dissolve to one feature per species x season. BirdLife files sometimes carry
#    overlapping or duplicate polygons within a species-season, and summing those
#    would double-count area. 
ranges_dissolved <- aggregate(ranges_eaaf, by = c("sci_name", "season", "season_weight"))

# 2. Range area inside the flyway (km2). Both layers are in the equal-area CRS
#    from Part 8, so these are true areas.
ranges_dissolved$range_area_km2 <- expanse(ranges_dissolved, unit = "km")

# 3. Portion of each species-season range that overlaps the dissolved wind footprints
overlap_geom <- intersect(ranges_dissolved, wind_dissolved)
overlap_geom$overlap_area_km2 <- expanse(overlap_geom, unit = "km")

# 4. Tabulate
range_df <- as.data.frame(ranges_dissolved) %>%
  select(sci_name, season, season_weight, range_area_km2)

overlap_df <- as.data.frame(overlap_geom) %>%
  group_by(sci_name, season, season_weight) %>%
  summarise(overlap_area_km2 = sum(overlap_area_km2), .groups = "drop")

# species-seasons with no wind overlap are absent from overlap_df -> left join, fill 0
species_season <- range_df %>%
  left_join(overlap_df, by = c("sci_name", "season", "season_weight")) %>%
  mutate(overlap_area_km2 = replace_na(overlap_area_km2, 0),
         pct_overlap_season = overlap_area_km2 / range_area_km2)

# sanity checks
stopifnot(all(species_season$range_area_km2 > 0))
summary(species_season$pct_overlap_season)            # should all fall between 0 and 1
species_season %>% filter(overlap_area_km2 > 0) %>% count(season)
species_season %>% arrange(desc(pct_overlap_season)) %>% head(10)




# All seasons / legend categories for Thalasseus bernsteini (raw, not EAAF-clipped)

sp_name <- "Thalasseus bernsteini"   # swap sci_name for your actual species column

sp_all <- makeValid(ranges_shp[ranges_shp$sci_name == sp_name, ])

# what's in there?
sp_all %>% as.data.frame() %>% count(legend, season, include)

sp_all_ea <- project(sp_all, crs_ea)

# zoom to the full extent of all its ranges (+ 200 km margin)
e_all  <- ext(buffer(sp_all_ea, 200000))
e_all_ll <- ext(project(buffer(sp_all_ea, 200000), "EPSG:4326"))

land <- ne_countries(scale = 50, returnclass = "sf") %>%  
  vect() %>%
  crop(e_all_ll) %>%
  project(crs_ea)

# combined map, coloured by legend category (alpha so overlapping seasons stay visible)
ggplot() +
  geom_spatvector(data = land, fill = "grey92", color = "grey70", linewidth = 0.2) +
  geom_spatvector(data = eaaf_ea, fill = NA, color = "grey60", linewidth = 0.3) +
  geom_spatvector(data = sp_all_ea, aes(fill = legend), color = NA, alpha = 0.6) +
  # geom_spatvector(data = wind_hit, fill = "#d62828", alpha = 0.7) +   # optional: add wind footprints
  scico::scale_fill_scico_d(palette = "batlow", name = NULL) +
  coord_sf(xlim = c(xmin(e_all), xmax(e_all)), ylim = c(ymin(e_all), ymax(e_all)),
           expand = FALSE) +
  labs(title = paste(sp_name, "- all range categories")) +
  theme_minimal() +
  theme(legend.position = "bottom")

# or one panel per category - easier to read if the ranges overlap:
# last_plot() + facet_wrap(~legend)



#check:
# Plot: Thalasseus bernsteini breeding range + the wind footprints it intersects

sp_name <- "Thalasseus bernsteini"   # swap sci_name for your actual species column

# footprints in the same equal-area CRS as the ranges
wind_ea <- project(wind_footprints, crs_ea)
eaaf_ea <- project(eaaf, crs_ea)

# breeding-season range (trimmed to the EAAF)
tern <- ranges_eaaf[ranges_eaaf$sci_name == sp_name & ranges_eaaf$season == "breeding", ]
nrow(tern)   # if 0: check the name/season with count(ranges_eaaf$sci_name == sp_name, season)

# wind footprints that touch that range
wind_hit <- wind_ea[is.related(wind_ea, aggregate(tern), "intersects"), ]
nrow(wind_hit)

# what are they?
wind_hit %>%
  as.data.frame() %>%
  select(project_name, country_area, capacity_mw, installation_type, status) %>%
  arrange(desc(capacity_mw))

# zoom to the range + 150 km margin (the range is small relative to the flyway)
e <- ext(buffer(tern, 150000))

library(rnaturalearth)

# zoom window in lon/lat, so land can be cropped before projecting
e_ll <- ext(project(buffer(tern, 150000), "EPSG:4326"))

land <- ne_countries(scale = 50, returnclass = "sf") %>%   # or scale = 50
  vect() %>%
  crop(e_ll) %>%
  project(crs_ea)

ggplot() +
  geom_spatvector(data = land, fill = "grey92", color = "grey70", linewidth = 0.2) +
  geom_spatvector(data = eaaf_ea, fill = NA, color = "grey60", linewidth = 0.3) +
  geom_spatvector(data = tern, fill = "#2a9d8f", color = "#1d6f66", alpha = 0.5) +
  geom_spatvector(data = wind_hit, fill = "#d62828", color = "#9d0208", alpha = 0.7) +
  coord_sf(xlim = c(xmin(e), xmax(e)), ylim = c(ymin(e), ymax(e)), expand = FALSE) +
  labs(title = paste(sp_name, "- breeding range"),
       subtitle = "Teal = range (trimmed to EAAF); red = intersecting wind footprints") +
  theme_minimal()





# Part 11: Months-weighted overall overlap per species -------------------------

# months spent in each zone type (resident = year-round; the others = 4 each).
# Same 3:1 ratio as the earlier season_weight, just in months.
months_lookup <- c("resident" = 12, "breeding" = 4, "non-breeding" = 4, "passage" = 4)

species_season <- species_season %>%
  mutate(months = months_lookup[season])

# overall = months-weighted mean of the per-season overlap proportions,
# normalised by the months of whichever seasons are actually mapped
species_overall <- species_season %>%
  group_by(sci_name) %>%
  summarise(
    seasons_present = paste(sort(unique(season)), collapse = ", "),
    months_covered  = sum(months),     # < 12 means part of the annual cycle isn't mapped
    overlap_overall = sum(months * pct_overlap_season) / sum(months),
    .groups = "drop"
  )

# per-season overlap + range area, one column each, for transparency
species_wide <- species_season %>%
  select(sci_name, season, pct_overlap_season, range_area_km2) %>%
  pivot_wider(names_from = season,
              values_from = c(pct_overlap_season, range_area_km2),
              names_glue = "{.value}_{season}")

# start from every species in the raw file so nothing silently drops out of your merge
species_out <- ranges_shp %>%
  as.data.frame() %>%
  distinct(sci_name) %>%
  left_join(species_overall, by = "sci_name") %>%
  left_join(species_wide, by = "sci_name") %>%
  mutate(
    overlap_overall_pct = 100 * overlap_overall,
    has_passage_mapped  = str_detect(replace_na(seasons_present, ""), "passage"),
    note = if_else(is.na(seasons_present),
                   "no included range in EAAF (excluded legend category or outside flyway)",
                   NA_character_)
  ) %>%
  arrange(desc(overlap_overall))

# sanity checks
summary(species_out$overlap_overall)               # should be between 0 and 1
species_out %>% count(seasons_present, sort = TRUE) # which season combinations exist?
species_out %>% filter(overlap_overall > 0) %>% nrow()
head(species_out, 15)

# write out for manual merging
write_csv(species_out, here::here("data/processed/species_wind_overlap.csv"))









# Part 12: Global seasons mapped per species (NOT clipped to the EAAF) ---------------

# Uses the legend classification from Part 7 (ranges_shp$season / $include), so "included"
# means exactly what it means for the EAAF columns: extant / possibly extant resident,
# breeding, non-breeding, passage. Only the attribute table is used, no geometry.

range_attr <- ranges_shp %>%
  as.data.frame() %>%
  mutate(legend = str_squish(legend))

# one row per species-season over ALL included polygons, anywhere in the world
seasons_global_long <- range_attr %>%
  filter(include) %>%
  distinct(sci_name, season)

seasons_global <- seasons_global_long %>%
  group_by(sci_name) %>%
  summarise(
    seasons_present_global   = paste(sort(unique(season)), collapse = ", "),
    n_seasons_mapped_global  = n_distinct(season),
    .groups = "drop"
  ) %>%
  mutate(
    has_resident_global     = str_detect(seasons_present_global, "(^|, )resident"),
    has_breeding_global     = str_detect(seasons_present_global, "(^|, )breeding"),
    has_nonbreeding_global  = str_detect(seasons_present_global, "non-breeding"),
    has_passage_global      = str_detect(seasons_present_global, "passage")
  )

# extra context for completeness: polygons with "seasonality uncertain" (excluded above)
# and extinct / possibly extinct polygons, flagged per species
flags_global <- range_attr %>%
  group_by(sci_name) %>%
  summarise(
    has_uncertain_season_polygon = any(season == "uncertain", na.rm = TRUE),
    has_extinct_polygon          = any(range_status %in% c("extinct", "possibly extinct")),
    n_polygons_all               = n(),
    n_polygons_included          = sum(include),
    .groups = "drop"
  )

# start from every species in the raw file so nothing silently drops out of the merge
seasons_global_out <- range_attr %>%
  distinct(sci_name) %>%
  left_join(seasons_global, by = "sci_name") %>%
  left_join(flags_global,   by = "sci_name") %>%
  # the existing EAAF-clipped seasons, for side-by-side comparison
  left_join(species_out %>% select(sci_name, seasons_present_eaaf = seasons_present),
            by = "sci_name") %>%
  mutate(
    n_seasons_mapped_global = replace_na(n_seasons_mapped_global, 0L),
    note = case_when(
      n_seasons_mapped_global == 0 & has_uncertain_season_polygon ~
        "no included season; only 'seasonality uncertain' polygons",
      n_seasons_mapped_global == 0 ~
        "no included range polygon anywhere (only extinct / excluded categories)",
      TRUE ~ NA_character_)
  ) %>%
  arrange(sci_name)

# sanity checks
# 1. every species with seasons inside the EAAF must have those same seasons globally
bad <- seasons_global_out %>%
  filter(!is.na(seasons_present_eaaf)) %>%
  rowwise() %>%
  filter(!all(str_split(seasons_present_eaaf, ", ")[[1]] %in%
                str_split(replace_na(seasons_present_global, ""), ", ")[[1]])) %>%
  ungroup()
nrow(bad)                                    # should be 0
bad

# 2. how many seasons per species, and how often does the EAAF clip drop seasons?
seasons_global_out %>% count(n_seasons_mapped_global)
seasons_global_out %>% count(seasons_present_global, sort = TRUE)
seasons_global_out %>%
  filter(!is.na(seasons_present_eaaf), seasons_present_eaaf != seasons_present_global) %>%
  select(sci_name, seasons_present_global, seasons_present_eaaf)

# 3. the two petrels we were just looking at
seasons_global_out %>% filter(sci_name %in% c("Pterodroma sandwichensis", "Pseudobulweria aterrima"))

write_csv(seasons_global_out, here::here("data/processed/species_seasons_global.csv"))














#Example figure

# Figure: how the seasonal overlap -> months-weighted overall overlap works ------

library(patchwork)

# consistent colours for season types (reuse these anywhere seasons are plotted)
season_cols <- c("resident"     = "#3b6fb6",
                 "breeding"     = "#3a9d5d",
                 "non-breeding" = "#e08a1e",
                 "passage"      = "#9b59b6")

# 1. example species: 3+ seasons mapped, some overlap, highest mean overlap.
#    Override by hand if you prefer, e.g. ex_sp <- "Thalasseus bernsteini"
ex_sp <- species_season %>%
  group_by(sci_name) %>%
  filter(n() >= 3, any(overlap_area_km2 > 0)) %>%
  summarise(m = mean(pct_overlap_season), .groups = "drop") %>%
  slice_max(m, n = 1) %>%
  pull(sci_name)
ex_sp

# 2. pieces for the example (all in the equal-area CRS)
wind_ea    <- project(wind_footprints, crs_ea)          # ALL footprints, no range filter
ex_ranges  <- ranges_dissolved[ranges_dissolved$sci_name == ex_sp, ]
ex_overlap <- intersect(ex_ranges, wind_dissolved)

ex_tbl <- species_season %>%
  filter(sci_name == ex_sp) %>%
  mutate(months = months_lookup[season])

# 3. plotting window in lon/lat: Asia-Pacific only (drops Alaska / North America).
#    Plotting copies only - ex_tbl above still reflects the full range.
plot_win <- ext(60, 180, -60, 80)

crop_for_plot <- function(x) {
  x %>% project("EPSG:4326") %>% crop(plot_win) %>% project(crs_ea)
}

ex_ranges_p  <- crop_for_plot(ex_ranges)
ex_overlap_p <- crop_for_plot(ex_overlap)
wind_p       <- crop_for_plot(wind_ea)                   # every footprint in the window

seasons_ex <- intersect(names(season_cols), ex_ranges_p$season)

# shared map window, based on the cropped ranges
e    <- ext(buffer(aggregate(ex_ranges_p), 100000))
# e <- ext(project(as.polygons(plot_win, crs = "EPSG:4326"), crs_ea))   # alternative: show the whole Asia-Pacific window
e_ll <- ext(project(as.polygons(e, crs = crs_ea), "EPSG:4326"))

land <- ne_countries(scale = 50, returnclass = "sf") %>%   # or scale = 50
  vect() %>% crop(e_ll) %>% project(crs_ea)

# 4. one panel per season
make_panel <- function(sn) {
  r   <- ex_ranges_p[ex_ranges_p$season == sn, ]
  o   <- ex_overlap_p[ex_overlap_p$season == sn, ]
  row <- ex_tbl[ex_tbl$season == sn, ]
  
  # footprints that touch THIS season's range vs. those that don't
  touches   <- is.related(wind_p, aggregate(r), "intersects")
  wind_hit  <- wind_p[touches, ]
  wind_miss <- wind_p[!touches, ]
  
  ggplot() +
    geom_spatvector(data = land, fill = "grey94", color = "grey75", linewidth = 0.15) +
    geom_spatvector(data = r, fill = season_cols[sn], color = NA, alpha = 0.45) +
    geom_spatvector(data = wind_miss, fill = NA, color = "grey40",
                    linewidth = 0.3, linetype = "dashed") +              # not overlapped by this range
    geom_spatvector(data = wind_hit, fill = NA, color = "#c1121f", linewidth = 0.4) +  # overlapped
    geom_spatvector(data = o, fill = "#c1121f", color = "#c1121f") +     # range ∩ wind
    coord_sf(xlim = c(xmin(e), xmax(e)), ylim = c(ymin(e), ymax(e)), expand = FALSE) +
    labs(title = str_to_title(sn),
         subtitle = sprintf("overlap = %.1f%% \n weight = %d months",
                            100 * row$pct_overlap_season, row$months)) +
    theme_void() +
    theme(plot.title = element_text(face = "bold", color = season_cols[sn]),
          panel.border = element_rect(fill = NA, color = "grey70"))
}

panels <- map(seasons_ex, make_panel)

# 5. formula strip with the actual numbers (full range, not just the plotted window)
terms <- paste0(ex_tbl$months, " × ", sprintf("%.3f", ex_tbl$pct_overlap_season), collapse = " + ")
P     <- sum(ex_tbl$months * ex_tbl$pct_overlap_season) / sum(ex_tbl$months)
formula_label <- sprintf("Overall overlap  P  =  (%s) / %d  =  %.1f%%",
                         terms, sum(ex_tbl$months), 100 * P)

formula_panel <- ggplot() +
  annotate("text", x = 0, y = 0, label = formula_label, size = 5, hjust = 0.5) +
  theme_void()

fig <- wrap_plots(panels, nrow = 1) / formula_panel +
  plot_layout(heights = c(5, 1)) +
  plot_annotation(
    title = bquote(italic(.(ex_sp)) ~ "- seasonal range overlap with wind energy areas"),
    caption = paste("Coloured = seasonal range; red outline = wind footprint overlapped by that range;",
                    "grey dashed = not overlapped; red fill = range ∩ wind area.",
                    "Maps show the Asia-Pacific portion only; overlap values use each season's full range in the EAAF."))

fig
ggsave(here::here("figs/overlap_method_SWPA.png"), fig, width = 8, height = 5.5, dpi = 300)



#chinese crested tern

## ---- Inset plots for tiny ranges: Step 1 – cluster polygons ----
library(terra); library(tidyverse); library(tidyterra); library(patchwork)

sp_name     <- "Thalasseus bernsteini"
season_name <- "breeding"

# range polygons for this species/season (already clipped to EAAF, in crs_ea)
sp_rng <- ranges_eaaf[ranges_eaaf$sci_name == sp_name &
                        ranges_eaaf$season   == season_name, ]
sp_rng <- makeValid(sp_rng)

# split multipart geometry into individual islands/patches
parts <- disagg(aggregate(sp_rng))            # one row per polygon part

# group parts that are close together into one inset (single-linkage, 50 km)
cluster_dist_m <- 50000
cents <- centroids(parts)
hc    <- hclust(as.dist(distance(cents)), method = "single")
parts$cluster <- cutree(hc, h = cluster_dist_m)

# wind footprints in same CRS + dissolved copy for overlap math
wind_ea  <- project(wind_footprints, crs_ea)
wind_dis <- aggregate(wind_ea)

# summary per cluster: area, overlap area, overlap %
cluster_tbl <- map_dfr(sort(unique(parts$cluster)), function(k) {
  pk  <- aggregate(parts[parts$cluster == k, ])
  a   <- expanse(pk, unit = "km")
  ov  <- suppressWarnings(intersect(pk, wind_dis))
  ova <- if (nrow(ov) == 0) 0 else sum(expanse(ov, unit = "km"))
  tibble(cluster = k, n_parts = sum(parts$cluster == k),
         area_km2 = a, overlap_km2 = ova, pct = 100 * ova / a)
})
print(cluster_tbl)   # sanity check: should sum to ~57.9 km2 total
sum(cluster_tbl$area_km2)



## ---- Step 2 – one zoomed panel per cluster ----
land <- rnaturalearth::ne_countries(scale = 50, returnclass = "sv") |> project(crs_ea)

## ---- Shared window calc (used by insets AND overview boxes) ----
get_win <- function(k, min_half_m = 20000, pad_frac = 0.6) {
  e  <- ext(aggregate(parts[parts$cluster == k, ]))
  cx <- mean(c(e$xmin, e$xmax)); cy <- mean(c(e$ymin, e$ymax))
  half <- max(min_half_m, pad_frac * max(e$xmax - e$xmin, e$ymax - e$ymin))
  ext(cx - half, cx + half, cy - half, cy + half)
}

# inside make_inset(), swap the cx/cy/half/win lines for:
#   win  <- get_win(k, min_half_m, pad_frac)
#   half <- (win$xmax - win$xmin) / 2     # still needed for the caption
make_inset <- function(k, min_half_m = 20000, pad_frac = 0.6) {
  pk <- aggregate(parts[parts$cluster == k, ])
  e  <- ext(pk)
  
  # panel extent: square-ish window centred on the cluster, never tighter than min_half_m
  cx <- mean(c(e$xmin, e$xmax)); cy <- mean(c(e$ymin, e$ymax))
  half <- max(min_half_m, pad_frac * max(e$xmax - e$xmin, e$ymax - e$ymin))
  win  <- ext(cx - half, cx + half, cy - half, cy + half)
  
  # what's inside the window
  land_k <- crop(land, win)
  wind_k <- crop(wind_ea, win)
  ov_k   <- suppressWarnings(intersect(pk, wind_dis))   # overlap region only
  row    <- cluster_tbl[cluster_tbl$cluster == k, ]
  
  ggplot() +
    geom_spatvector(data = land_k, fill = "grey92", colour = "grey70", linewidth = 0.2) +
    # all wind footprints in the window (solid outline, light fill)
    { if (nrow(wind_k) > 0)
      geom_spatvector(data = wind_k, fill = "firebrick", alpha = 0.15,
                      colour = "firebrick", linewidth = 0.3) } +
    # the range patch(es)
    geom_spatvector(data = pk, fill = season_cols[[season_name]], alpha = 0.8,
                    colour = "black", linewidth = 0.4) +
    # overlap area on top
    { if (nrow(ov_k) > 0)
      geom_spatvector(data = ov_k, fill = "firebrick", colour = "black", linewidth = 0.3) } +
    coord_sf(xlim = c(win$xmin, win$xmax), ylim = c(win$ymin, win$ymax),
             expand = FALSE, datum = NA) +
    labs(title    = paste0("Cluster ", k, " (", row$n_parts, " patch",
                           ifelse(row$n_parts > 1, "es", ""), ")"),
         subtitle = sprintf("%.1f km² | overlap %.1f%%", row$area_km2, row$pct),
         caption  = sprintf("window %.0f km wide", 2 * half / 1000)) +
    theme_void(base_size = 10) +
    theme(panel.border = element_rect(colour = "grey50", fill = NA),
          plot.title = element_text(face = "bold"),
          plot.caption = element_text(size = 7, colour = "grey40"))
}

insets <- map(cluster_tbl$cluster, make_inset)
insetmaps <- wrap_plots(insets, ncol = 3) +
  plot_annotation(title = paste(sp_name, "–", season_name, "range"),
                  subtitle = "Red = wind footprints; solid red = range overlapping wind")
ggsave(here::here("figs/overlap_insets_CCTE.png"), insetmaps, width = 8, height = 5.5, dpi = 300)

## ---- Overview map: where the insets sit ----
boxes <- do.call(rbind, map(cluster_tbl$cluster, function(k) as.polygons(get_win(k), crs = crs_ea)))
boxes$cluster <- cluster_tbl$cluster

box_lab <- as_tibble(crds(centroids(boxes))) |>
  mutate(cluster = boxes$cluster,
         lab = paste0(cluster, ifelse(cluster_tbl$pct > 0, "*", "")))   # * = overlaps wind

pad_m  <- 600000                       # km of context around the boxes; tweak
e_all  <- ext(boxes)
ov_win <- ext(e_all$xmin - pad_m, e_all$xmax + pad_m, e_all$ymin - pad_m, e_all$ymax + pad_m)

land_ov <- crop(land, ov_win)
wind_ov <- crop(centroids(wind_ea), ov_win)      # points: footprints are too small to see here

p_overview <- ggplot() +
  geom_spatvector(data = land_ov, fill = "grey92", colour = "grey70", linewidth = 0.2) +
  geom_spatvector(data = wind_ov, colour = "firebrick", size = 0.6, alpha = 0.6) +
  geom_spatvector(data = boxes, fill = NA, colour = "black", linewidth = 0.7) +
  ggrepel::geom_text_repel(data = box_lab, aes(x, y, label = lab),
                           fontface = "bold", size = 3.5, min.segment.length = 0,
                           box.padding = 0.6, segment.colour = "black") +
  coord_sf(xlim = c(ov_win$xmin, ov_win$xmax), ylim = c(ov_win$ymin, ov_win$ymax),
           expand = FALSE, datum = NA) +
  labs(title = "Where the insets sit",
       subtitle = "Boxes = inset windows (40 km); red dots = wind farm locations; * = overlaps wind",
       caption = sprintf("window ~%.0f km wide", (ov_win$xmax - ov_win$xmin) / 1000)) +
  theme_void(base_size = 10) +
  theme(panel.border = element_rect(colour = "grey50", fill = NA),
        plot.title = element_text(face = "bold"))


(p_overview | wrap_plots(insets, ncol = 2)) +
  plot_layout(widths = c(1, 1.3)) +
  plot_annotation(title = paste(sp_name, "-", season_name, "range"))
p_overview

ggsave(here::here("figs/rangescale_CCTE.png"), p_overview, width = 10, height = 7, dpi = 300)



## =====================================================================
## Seasonal range overlap figure – one species, start to finish
## Needs: ranges_eaaf (SpatVector, crs_ea; fields sci_name, season),
##        wind_footprints (SpatVector), crs_ea
## Packages: terra, tidyverse, tidyterra, patchwork, ggtext, rnaturalearth
## =====================================================================
library(terra); library(tidyverse); library(tidyterra); library(patchwork); library(ggtext)

## ---- 0. Settings ------------------------------------------------------
sp_name  <- "Lathamus discolor"
plot_win <- ext(60, 180, -60, 80)          # lon/lat window for DISPLAY only (keeps Alaska out)

season_order <- c("resident", "breeding", "non-breeding", "passage")
season_w     <- c(resident = 12, breeding = 4, `non-breeding` = 4, passage = 4)   # months
season_cols  <- c(resident = "#3B6FB6", breeding = "#5BA36B",
                  `non-breeding` = "#E08A1E", passage = "#8E5EA2")

## ---- 1. Helpers --------------------------------------------------------
# keeps tiny percentages readable: 0.000346 -> "0.035%", exact 0 -> "0%"
fmt_pct <- function(p, sig = 2) {
  ifelse(is.na(p), "NA",
         ifelse(p == 0, "0%",
                ifelse(p < 1e-5, "<0.001%",
                       paste0(formatC(100 * p, digits = sig, format = "fg"), "%"))))
}

# crop a copy to the display window (lon/lat), then back to Equal Earth for plotting
crop_for_plot <- function(x) project(crop(project(x, "EPSG:4326"), plot_win), crs_ea)

## ---- 2. Data for this species -------------------------------------------
wind_ea  <- project(wind_footprints, crs_ea)
wind_dis <- aggregate(wind_ea)                                    # one dissolved wind layer

sp_all   <- makeValid(ranges_eaaf[ranges_eaaf$sci_name == sp_name, ])
seasons  <- season_order[season_order %in% unique(sp_all$season)] # only seasons that exist

land <- rnaturalearth::ne_countries(scale = 50, returnclass = "sv")
land_plot <- project(crop(land, plot_win), crs_ea)

## ---- 3. Per-season overlap (full EAAF range, NOT the cropped display) ----
season_stats <- map_dfr(seasons, function(s) {
  rng <- aggregate(sp_all[sp_all$season == s, ])
  a   <- expanse(rng, unit = "km")
  ov  <- suppressWarnings(intersect(rng, wind_dis))
  ova <- if (nrow(ov) == 0) 0 else sum(expanse(ov, unit = "km"))
  tibble(season = s, weight = season_w[[s]], range_km2 = a, overlap_km2 = ova, p = ova / a)
})
P_overall <- sum(season_stats$weight * season_stats$p) / sum(season_stats$weight)
print(season_stats); P_overall        # sanity check against your CSV (overlap_overall)

## ---- 4. One panel per season --------------------------------------------
make_panel <- function(s) {
  st  <- season_stats[season_stats$season == s, ]
  rng <- aggregate(sp_all[sp_all$season == s, ])
  
  # which footprints touch this season's range? (tested on the full range)
  hit_idx <- is.related(wind_ea, rng, "intersects")
  wind_hit  <- wind_ea[hit_idx, ]
  wind_miss <- wind_ea[!hit_idx, ]
  
  # display copies, cropped to the Asia-Pacific window
  rng_p  <- crop_for_plot(rng)
  miss_p <- crop_for_plot(centroids(wind_miss))
  hit_p  <- crop_for_plot(wind_hit)
  ov_p   <- suppressWarnings(intersect(rng, wind_dis)) |> (\(x) if (nrow(x) > 0) crop_for_plot(x) else x)()
  
  p <- ggplot() +
    geom_spatvector(data = land_plot, fill = "grey94", colour = "grey75", linewidth = 0.15) +
    geom_spatvector(data = rng_p, fill = season_cols[[s]], alpha = 0.55, colour = NA)
  # non-overlapped farms: small solid dots (no dashes/outlines that fragment at this scale)
  if (nrow(miss_p) > 0) p <- p + geom_spatvector(data = miss_p, colour = "grey35", size = 0.5)
  # farms touching the range: true footprint + enlarged ring so it stays visible
  if (nrow(hit_p) > 0) p <- p +
    geom_spatvector(data = hit_p, fill = "red3", colour = "red3", linewidth = 0.4) +
    geom_spatvector(data = centroids(hit_p), shape = 1, colour = "red3", size = 3, stroke = 0.7)
  # overlap area itself
  if (nrow(ov_p) > 0) p <- p + geom_spatvector(data = ov_p, fill = "red3", colour = "red3")
  
  p +
    coord_sf(expand = FALSE, datum = NA) +
    labs(title    = str_to_title(s),
         subtitle = paste0("overlap = ", fmt_pct(st$p), "\nweight = ", st$weight, " months")) +
    theme_void(base_size = 11) +
    theme(plot.title    = element_text(face = "bold", colour = season_cols[[s]], size = 15),
          plot.subtitle = element_text(size = 11),
          panel.border  = element_rect(colour = "grey60", fill = NA))
}
panels <- map(seasons, make_panel)

## ---- 5. Formula strip -----------------------------------------------------
formula_txt <- paste0(
  "Overall overlap  P  =  (",
  paste0(season_stats$weight, " × ", fmt_pct(season_stats$p), collapse = " + "),
  ")  /  ", sum(season_stats$weight), "  =  ", fmt_pct(P_overall))

p_formula <- ggplot() +
  annotate("text", x = 0, y = 0, label = formula_txt, size = 5.5) +
  theme_void()

## ---- 6. Assemble + save ------------------------------------------------------
cap <- str_wrap(paste("Grey dots = wind areas not overlapped; red = range ∩ wind area (rings enlarged for visibility).",
                      "Maps show the Asia-Pacific portion only; overlap values use each season's full range in the EAAF."), 110)

fig <- (wrap_plots(panels, nrow = 1) / p_formula) +
  plot_layout(heights = c(1, 0.08)) +
  plot_annotation(
    title   = paste0("*", sp_name, "* – seasonal range overlap with wind energy areas"),
    caption = cap,
    theme   = theme(plot.title = element_markdown(size = 16),
                    plot.caption = element_text(hjust = 0, size = 8),
                    plot.caption.position = "plot"))
fig

ggsave(here::here("figs/overlap_method_SWPA.png"), fig, width = 8, height = 5.5, dpi = 300)




