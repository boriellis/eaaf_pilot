# =============================================================================
# build_country_data.R  --  which countries does each species' range occur in?
#                           (land + EEZ, so offshore seabird ranges still match)
#
# Run AFTER build_map_data.R (it reuses the cached, EAAF-clipped ranges in
# data/processed/cache/). Run it from the repo root, same as build_map_data.R.
#
# Needs the Marine Regions land+EEZ union in:
#   data/raw/EEZ_land_union_v4_202410/EEZ_land_union_v4_202410.shp   (+ .dbf/.shx/.prj/.cpg alongside)
#
# Writes:
#   map_data/species_countries.csv             -> the APP reads this (copy map_data/ into the app folder again)
#   data/processed/species_country_long.csv    -> one row per species x country, with share of range
#   data/processed/species_country_wide.csv    -> TRUE/FALSE column per country, for your collaborator
#
# "Occurs in" = at least one counted season's range (resident / breeding / non-breeding / passage)
# overlaps that country's land or EEZ INSIDE THE FLYWAY, with share of that range above `min_share`.
# Work through it block by block.
# =============================================================================

library(terra); library(tidyverse); library(here)

# ---- Settings ----------------------------------------------------------------
eez_path      <- here::here("data/raw/EEZ_land_union_v4_202410/EEZ_land_union_v4_202410.shp")
country_level <- "sovereign"   # "sovereign": Hong Kong / Macau / territories roll up into their sovereign state
                               # "territory": territories listed separately (check names in Part 2 first)
min_share     <- 0             # a country counts if > this share of a season's range falls in it.
                               # 0 = any real overlap; try 0.01 to drop edge slivers (see Part 5)
high_seas_label <- "High seas (no EEZ)"
out_dir       <- here::here("map_data")
dir.create(out_dir, showWarnings = FALSE)

# ---- Part 1: ranges from the cache (made by build_map_data.R Part A) -------------
f_rd <- here::here("data/processed/cache/ranges_dissolved.gpkg")
if (!exists("ranges_dissolved")) ranges_dissolved <- vect(f_rd)    # reuse the object if it is already in the session
if (!exists("crs_ea")) crs_ea <- "EPSG:8857"                         # equal-area CRS used for all area maths (same as build_map_data.R)
if (!exists("eaaf")) eaaf <- vect(here::here("data/raw/EAAF/EAAF_polygon.shp"))
rd_df <- as.data.frame(ranges_dissolved)
nrow(rd_df); n_distinct(rd_df$sci_name)

# ---- Part 2: country layer, read only near the flyway ---------------------------------
hdr  <- vect(eez_path, proxy = TRUE)
names(hdr)                                                         # CHECK: should include TERRITORY1-3 and SOVEREIGN1-3
ctry <- vect(eez_path, extent = ext(project(eaaf, crs(hdr))))
nrow(ctry)

prefix     <- if (country_level == "sovereign") "SOVEREIGN" else "TERRITORY"
claim_cols <- intersect(paste0(prefix, 1:3), names(ctry))
if (length(claim_cols) == 0) stop("No ", prefix, "1-3 columns found. Names are: ", paste(names(ctry), collapse = ", "))

# some polygons are overlapping claims (e.g. Japan / Russia): the polygon belongs to every claimant
ctry_df <- as.data.frame(ctry)
claimants <- lapply(seq_len(nrow(ctry_df)), function(j) {
  v <- unlist(ctry_df[j, claim_cols]); v <- v[!is.na(v) & nzchar(v)]; unique(as.character(v))
})
sort(unique(unlist(claimants)))                                    # CHECK: the country list that will go in the app dropdown

ctry <- makeValid(project(ctry, crs_ea))
ctry$jid <- seq_len(nrow(ctry))

# ---- Part 3: quick pass - which range polygons touch which country polygons? -------------
rel <- relate(ranges_dissolved, ctry, "intersects")                # logical matrix: species-season x country polygon
dim(rel); sum(rel)

# ---- Part 4: area of each range inside each country (only for touching pairs) --------------
# also the share of the range that is outside every country polygon = "high seas"
one_range <- function(i) {
  ri  <- ranges_dissolved[i, ]
  a   <- rd_df$range_area_km2[i]
  js  <- which(rel[i, ])
  if (length(js) == 0) return(tibble(i = i, jid = 0L, area_km2 = a))          # nothing touches: all high seas
  cj  <- ctry[js, ]
  ov  <- terra::intersect(ri, cj)
  by_country <- if (nrow(ov) > 0) tibble(i = i, jid = ov$jid, area_km2 = expanse(ov, unit = "km")) else NULL
  cov <- terra::intersect(ri, aggregate(cj))                                  # dissolved, so overlapping claims are not double counted
  covered <- if (nrow(cov) > 0) sum(expanse(cov, unit = "km")) else 0
  bind_rows(by_country, tibble(i = i, jid = 0L, area_km2 = max(0, a - covered)))   # jid 0 = high seas
}
# TEST on one range first
one_range(which(rd_df$sci_name == "Thalasseus bernsteini")[1])

area_tbl <- map_dfr(seq_len(nrow(ranges_dissolved)), function(i) {
  if (i %% 50 == 0) message(i, " / ", nrow(ranges_dissolved))
  one_range(i)
})

# ---- Part 5: species x country table --------------------------------------------------------
long_season <- area_tbl %>%
  mutate(sci_name = rd_df$sci_name[i], season = rd_df$season[i], range_km2 = rd_df$range_area_km2[i],
         country  = map(jid, \(j) if (j == 0) high_seas_label else claimants[[j]])) %>%
  unnest_longer(country) %>%
  group_by(sci_name, season, country) %>%
  summarise(share = min(1, sum(area_km2) / first(range_km2)), .groups = "drop")

species_country_long <- long_season %>%
  filter(share > min_share) %>%
  group_by(sci_name, country) %>%
  summarise(max_share_of_range = max(share),
            seasons = paste(season, collapse = "; "), .groups = "drop") %>%
  arrange(sci_name, desc(max_share_of_range))

# sanity checks
species_country_long %>% filter(sci_name == "Thalasseus bernsteini")           # expect China, maybe Taiwan, etc.
species_country_long %>% count(country, sort = TRUE) %>% print(n = 60)         # species per country
setdiff(unique(rd_df$sci_name), species_country_long$sci_name)                 # species with no country (want none)
# how much does a 1% threshold change things?  (compare with min_share = 0)
long_season %>% filter(share > 0, share <= 0.01) %>% count(country, sort = TRUE) %>% head(10)

# ---- Part 6: write ----------------------------------------------------------------------------
write_csv(species_country_long, here::here("data/processed/species_country_long.csv"))

# wide TRUE/FALSE version for your collaborator: one column per country
slug <- function(x) paste0("occurs_", str_replace_all(str_to_lower(x), "[^a-z0-9]+", "_") %>% str_remove("_$"))
species_country_wide <- species_country_long %>%
  mutate(col = slug(country), present = TRUE) %>%
  select(sci_name, col, present) %>%
  pivot_wider(names_from = col, values_from = present, values_fill = FALSE)
write_csv(species_country_wide, here::here("data/processed/species_country_wide.csv"))

# the file the app reads: one text column, "; "-separated (country names contain no semicolons)
species_countries <- species_country_long %>%
  group_by(scientific_name = sci_name) %>%
  summarise(countries = paste(sort(country), collapse = "; "), n_countries = n(), .groups = "drop")
write_csv(species_countries, file.path("app/species_countries.csv"))
nrow(species_countries)
