# =============================================================================
# elicited_exposure.R  --  SeaSketch elicitation outputs -> elicited exposure inputs
#
# Takes the SeaSketch downloads (responses CSV + one GeoJSON per species) and produces,
# for each elicited species, the same kind of exposure input the app already uses
# (overlap_overall + per-season overlap), plus an uncertainty measure from the spread
# among respondents.
#
# Pipeline
#   PART 0  settings (paths, workshop time window, filters)         <- edit this
#   PART 1  responses CSV -> keep / drop (+ anonymised respondent codes)
#   PART 2  read the GeoJSONs, keep only kept respondents, fix the antimeridian
#   PART 3  EAAF polygon + wind footprints in one equal-area CRS
#   PART 4  season-overlap rules  (with a toy test)
#   PART 5  per respondent x species: resolve seasons, clip to EAAF, wind overlap
#   PART 6  aggregate across respondents (mean, SD, SE, median, IQR, range, bootstrap CI)
#   PART 7  write outputs + compare with the BirdLife-based values
#   PART 8  (optional) consensus map: agreement rasters -> consensus range -> exposure
#   PART 9  files for the app's "Expert range explorer" tab (per expert ranges + overlap + summary)
#
# Season rules (applied per respondent, per species, AFTER clipping to the EAAF):
#   1. resident  overlapping ANY other season          -> resident
#   2. breeding  overlapping non-breeding              -> resident
#   3. passage   overlapping breeding or non-breeding  -> that (breeding / non-breeding) season
#   (passage overlapping resident -> resident, rule 1; B x NB x passage -> resident, rule 2)
#
# Written to be run block by block (test as you go). Not run end-to-end by the author:
# if a block errors, paste it back and we'll fix it.
# =============================================================================


# ############################ PART 0: SETTINGS ################################

packages <- c("tidyverse", "sf", "terra", "here")
pacman::p_load(packages, character.only = TRUE); rm(packages)

# ---- inputs ----
survey_dir <- here::here("data/raw/seasketch")             # put the CSV + GeoJSONs here
resp_file  <- file.path(survey_dir, "responses.csv")       # <- the SeaSketch responses export
eaaf_path  <- here::here("data/raw/EAAF/EAAF_polygon.shp")
wind_path  <- here::here("data/processed/EAAF_offshore_wind_footprints.shp")   # written by exposure_scratch.R Part 6
birdlife_overlap_csv <- here::here("data/processed/species_wind_overlap.csv")  # for the side-by-side comparison

# ---- outputs ----
out_dir <- here::here("data/processed/elicitation")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- species: one row per SeaSketch question ----
#   file_pattern : regex that picks the GeoJSON out of survey_dir (must match exactly one file).
#                  The workshop files are named abbo.geojson.json / poja.geojson.json / ccte.geojson.json
#   csv_pattern  : regex that picks the "<question>_feature_ids" column out of the responses CSV
#                  (only used for a cross-check of polygon counts; if it matches no single column you get a
#                  warning and the cross-check is skipped, nothing else changes)
species_tbl <- tribble(
  ~sci_name,                ~common_name,           ~file_pattern,       ~csv_pattern,
  "Thalasseus bernsteini",  "Chinese Crested Tern", "^ccte\\.",          "(chinese|ccte).*_feature_ids$",
  "Stercorarius pomarinus", "Pomarine Jaeger",      "^poja\\.",          "(pomarine|poja).*_feature_ids$",
  "Papasula abbotti",       "Abbott's Booby",       "^abbo\\.",          "(abbott|abbo).*_feature_ids$"
  # was (pre-workshop names): "^chinese-crested", "^pomarine_jaeger", "^abbott" / "^aleutian_tern" (Aleutian Tern dropped)
)

# ---- which responses count as "legitimate workshop entries" ----
tz_local     <- "Asia/Singapore"
# Workshop window, in local time. Look at the timeline printed in PART 1 first, then set these.
# NA = no limit on that side.
window_start <- NA   # e.g. lubridate::ymd_hms("2026-11-18 09:00:00", tz = tz_local)
window_end   <- NA   # e.g. lubridate::ymd_hms("2026-11-18 17:30:00", tz = tz_local)

require_consent   <- TRUE    # drop anyone who did not tick consent
drop_practice     <- TRUE    # SeaSketch's own is_practice flag
drop_test_names   <- TRUE    # drop test entries: uniqID or account email matching test_name_regex (case-insensitive)
test_name_regex   <- "test|practice|dummy|asdf"   # add more words here if the timeline in PART 1 shows other test names
exclude_emails    <- c()     # drop by account_email, e.g. c("aaellis@ucsc.edu") for your own test runs (leave empty to keep)
# CAUTION: is_duplicate_ip flags everyone behind the same IP. At a workshop everyone shares the venue
# wifi, so leave this FALSE or you will throw out real entries.
drop_duplicate_ip <- FALSE
exclude_ids       <- c()     # SeaSketch response ids to drop by hand, e.g. c(20145, 20147)
require_all_species <- FALSE # TRUE = only keep respondents who drew something for ALL species

# ---- geometry / analysis settings ----
lon0_pac     <- 150          # central meridian of the analysis CRS (keeps the Pacific in one piece)
# Equal Earth centred on 150E. Same areas as EPSG:8857 (which the BirdLife pipeline used); only the
# centre differs, so shapes that cross the antimeridian (Pomarine jaeger, Abbott's booby) stay contiguous.
crs_pac      <- paste0("+proj=eqearth +lon_0=", lon0_pac, " +datum=WGS84 +units=m +no_defs")
min_season_area_km2 <- 1     # a resolved season smaller than this is treated as "not drawn" (kills slivers)

# months per season: same as exposure_scratch.R Part 11 (resident = year-round, others 4 each)
season_levels <- c("resident", "breeding", "non-breeding", "passage")
months_lookup <- c("resident" = 12, "breeding" = 4, "non-breeding" = 4, "passage" = 4)

n_boot <- 5000               # bootstrap resamples for the CI of the mean
set.seed(42)

make_consensus      <- TRUE  # PART 8 on/off
consensus_threshold <- 0.5   # a cell is in the consensus range if >= this share of respondents drew it
consensus_res_m     <- 10000 # raster cell size (m) for the agreement maps


# ############################ PART 1: RESPONSES ###############################

# everything read as text first (booleans arrive as "true"/"false"), so nothing is silently coerced
resp_raw <- read_csv(resp_file, col_types = cols(.default = col_character()))

resp <- resp_raw %>%
  mutate(
    created_utc   = lubridate::ymd_hms(created_at_utc, tz = "UTC"),
    created_local = lubridate::with_tz(created_utc, tz_local),
    name          = uniqID,                                    # whatever was typed / the logged-in email
    consent_ok    = !is.na(consent) & tolower(consent) == "true",
    drop_reason = case_when(
      id %in% as.character(exclude_ids)                                    ~ "manual exclude",
      drop_practice & tolower(is_practice) == "true"                       ~ "practice response",
      drop_test_names & (grepl(test_name_regex, name, ignore.case = TRUE) |
                         grepl(test_name_regex, account_email, ignore.case = TRUE)) ~ "test entry",
      !is.na(account_email) & tolower(account_email) %in% tolower(exclude_emails) ~ "excluded email",
      require_consent & !consent_ok                                        ~ "no consent",
      drop_duplicate_ip & tolower(is_duplicate_ip) == "true"               ~ "duplicate IP",
      !is.na(window_start) & created_local < window_start                  ~ "before workshop window",
      !is.na(window_end)   & created_local > window_end                    ~ "after workshop window",
      TRUE                                                                 ~ NA_character_
    )
  )

# ---- TEST: timeline of every entry, to help pick the workshop window ----
resp %>%
  arrange(created_utc) %>%
  select(id, name, created_local, consent_ok, is_practice, is_duplicate_ip, drop_reason) %>%
  print(n = Inf)

# polygons per respondent per species according to the CSV (cross-checked against the GeoJSONs in PART 2)
n_ids <- function(x) if_else(is.na(x) | x == "", 0L, lengths(str_split(x, ",")))
for (i in seq_len(nrow(species_tbl))) {
  col <- grep(species_tbl$csv_pattern[i], names(resp), value = TRUE, ignore.case = TRUE)
  if (length(col) != 1) {
    warning("CSV cross-check skipped for ", species_tbl$sci_name[i], ": expected one column matching '",
            species_tbl$csv_pattern[i], "', found ", length(col), ". Column names are:\n  ",
            paste(grep("feature_ids", names(resp), value = TRUE), collapse = "\n  "))
    resp[[paste0("n_poly_", species_tbl$sci_name[i])]] <- NA_integer_
    next
  }
  resp[[paste0("n_poly_", species_tbl$sci_name[i])]] <- n_ids(resp[[col]])
}

resp_kept <- resp %>% filter(is.na(drop_reason)) %>% arrange(created_utc) %>%
  mutate(resp_code = sprintf("R%02d", row_number()))          # anonymous code used in every output
resp_dropped <- resp %>% filter(!is.na(drop_reason))

cat("\nkept:", nrow(resp_kept), " dropped:", nrow(resp_dropped), "\n")
print(count(resp_dropped, drop_reason))


# ############################ PART 2: GEOMETRIES ##############################

# ---- helpers ----
# SeaSketch hands back "unwrapped" longitudes for shapes drawn across the antimeridian (e.g. 215 or
# -199). wrap_lon() maps every vertex into [lon0-180, lon0+180) so such shapes are contiguous.
wrap_lon <- function(x, lon0 = lon0_pac) {
  fix <- function(m) { m[, 1] <- ((m[, 1] - lon0 + 180) %% 360) - 180 + lon0; m }
  g <- lapply(sf::st_geometry(x), function(geom) {
    cls <- class(geom)
    out <- rapply(unclass(geom), fix, how = "replace")
    class(out) <- cls
    out
  })
  sf::st_geometry(x) <- sf::st_sfc(g, crs = sf::st_crs(x))
  x
}

read_species_geojson <- function(file_pattern, sci_name) {
  f <- list.files(survey_dir, pattern = file_pattern, full.names = TRUE)
  f <- f[grepl("\\.(geo)?json$", f, ignore.case = TRUE)]
  if (length(f) != 1) stop("Expected exactly one GeoJSON for '", file_pattern, "' in ", survey_dir,
                           ", found ", length(f))
  x <- sf::read_sf(f)
  if (is.na(sf::st_crs(x))) sf::st_crs(x) <- 4326
  range_col <- grep("_range$", names(x), value = TRUE)           # one per species, e.g. CCTE_range
  if (length(range_col) != 1) stop("Could not find a single *_range column in ", basename(f))
  x %>%
    mutate(sci_name    = sci_name,
           response_id = as.character(response_id),
           season      = recode(.data[[range_col]], "nonbreeding" = "non-breeding"),
           surveyed_area_km2 = area_sq_meters / 1e6) %>%
    select(sci_name, response_id, season, surveyed_area_km2)
}

geoms_all <- pmap(species_tbl, function(sci_name, file_pattern, ...) read_species_geojson(file_pattern, sci_name)) %>%
  bind_rows()

bad_season <- setdiff(unique(geoms_all$season), season_levels)
if (length(bad_season)) stop("Unexpected season labels in GeoJSON: ", paste(bad_season, collapse = ", "))

# ---- TEST: do GeoJSON and CSV agree on polygon counts per respondent? ----
chk <- geoms_all %>% st_drop_geometry() %>% count(sci_name, response_id, name = "n_geojson") %>%
  left_join(resp %>% select(id, starts_with("n_poly_")) %>%
              pivot_longer(-id, names_to = "sci_name", names_prefix = "n_poly_", values_to = "n_csv"),
            by = c("response_id" = "id", "sci_name"))
cat("\nGeoJSON vs CSV polygon counts (should be all TRUE):\n")
print(table(chk$n_geojson == chk$n_csv, useNA = "ifany"))
if (any(chk$n_geojson != chk$n_csv, na.rm = TRUE)) print(filter(chk, n_geojson != n_csv))

# ---- keep only kept respondents; attach anonymous code ----
geoms <- geoms_all %>%
  inner_join(resp_kept %>% select(response_id = id, resp_code), by = "response_id")

if (require_all_species) {
  complete <- geoms %>% st_drop_geometry() %>% distinct(resp_code, sci_name) %>%
    count(resp_code) %>% filter(n == nrow(species_tbl)) %>% pull(resp_code)
  geoms <- filter(geoms, resp_code %in% complete)
}

# ---- TEST: respondents x species with at least one polygon ----
geoms %>% st_drop_geometry() %>% distinct(resp_code, sci_name) %>% count(sci_name)
# kept respondents who drew nothing for a species simply have no rows for it (they are not counted as zeros)


# ############################ PART 3: EAAF + WIND #############################

# all three layers go: -> lon/lat -> wrap longitudes around lon0 -> equal-area CRS -> make valid
to_pac <- function(x) {
  x %>% sf::st_transform(4326) %>% wrap_lon() %>% sf::st_transform(crs_pac) %>% sf::st_make_valid()
}

eaaf_pac <- sf::st_as_sf(terra::vect(eaaf_path)) %>% to_pac()
eaaf_geom <- sf::st_union(eaaf_pac)                                 # one geometry (sfc, length 1)

wind_pac  <- sf::st_read(wind_path, quiet = TRUE) %>% to_pac()
wind_geom <- sf::st_union(wind_pac)

geoms_pac <- to_pac(geoms)

# ---- TEST 1: EAAF area here should match its area computed straight from lon/lat (ratio ~ 1) ----
a_here <- as.numeric(sf::st_area(eaaf_geom)) / 1e6
a_geod <- sum(terra::expanse(terra::vect(eaaf_path), unit = "km"))   # ellipsoidal area straight from lon/lat
cat("\nEAAF area ratio, equal-area CRS / ellipsoidal (should be ~1, within ~1%):", round(a_here / a_geod, 4), "\n")

# ---- TEST 2: our polygon areas vs the area SeaSketch reported (a few % off is normal for big
#      shapes: SeaSketch treats edges as geodesics, we treat them as straight lines on the map) ----
ratio <- as.numeric(sf::st_area(geoms_pac)) / 1e6 / geoms_pac$surveyed_area_km2
summary(ratio)

# ---- TEST 3: wind footprint count / area ----
nrow(wind_pac); as.numeric(sf::st_area(wind_geom)) / 1e6


# ############################ PART 4: SEASON RULES ############################

# --- geometry helpers: always work with ONE (multi)polygon per season, empty = empty polygon ---
empty_geom <- function() sf::st_sfc(sf::st_polygon(), crs = crs_pac)
is_empty   <- function(g) length(g) == 0 || all(sf::st_is_empty(g))

tidy_geom <- function(r) {                                   # keep polygons only, merged into one geometry
  if (length(r) == 0) return(empty_geom())
  r <- suppressWarnings(sf::st_collection_extract(r, "POLYGON"))
  if (length(r) == 0 || all(sf::st_is_empty(r))) return(empty_geom())
  sf::st_make_valid(sf::st_union(r))
}
g_int   <- function(a, b) if (is_empty(a) || is_empty(b)) empty_geom() else tidy_geom(sf::st_intersection(a, b))
g_diff  <- function(a, b) if (is_empty(a)) empty_geom() else if (is_empty(b)) a else tidy_geom(sf::st_difference(a, b))
g_union <- function(...) {
  gs <- Filter(Negate(is_empty), list(...))
  if (length(gs) == 0) empty_geom() else sf::st_make_valid(sf::st_union(do.call(c, gs)))
}

#' Apply the season-overlap rules to one respondent's four season geometries.
#' S: named list (resident, breeding, non-breeding, passage); each element one (multi)polygon or empty.
#' Returns the same four names, now mutually exclusive.
resolve_seasons <- function(S) {
  R <- S[["resident"]]; B <- S[["breeding"]]; N <- S[["non-breeding"]]; P <- S[["passage"]]
  R_f <- g_union(R, g_int(B, N))              # rules 1 + 2: resident wins; breeding x non-breeding = resident
  B_f <- g_diff(B, R_f)
  N_f <- g_diff(N, R_f)
  P_f <- g_diff(P, g_union(R_f, B, N))        # rule 3: passage only keeps what nothing else claims
  list("resident" = R_f, "breeding" = B_f, "non-breeding" = N_f, "passage" = P_f)
}

# --- TEST with squares (units of 100 km, so 1 unit^2 = 10,000 km2) ---
sq <- function(x0, x1, y0, y1) sf::st_sfc(sf::st_polygon(list(rbind(
  c(x0, y0), c(x1, y0), c(x1, y1), c(x0, y1), c(x0, y0)) * 1e5)), crs = crs_pac)
toy <- resolve_seasons(list(
  "resident"     = sq(2.5, 4, 0, 1),
  "breeding"     = sq(0, 2, 0, 2),
  "non-breeding" = sq(1, 3, 0, 2),
  "passage"      = sq(0, 4, 1, 3)
))
toy_km2 <- vapply(toy, function(g) as.numeric(sum(sf::st_area(g))) / 1e6, numeric(1))
toy_km2     # expect resident 35000, breeding 20000, non-breeding 15000, passage 50000 (total 120000 = union of inputs)
stopifnot(all.equal(unname(toy_km2), c(35000, 20000, 15000, 50000), tolerance = 1e-6))


# ############################ PART 5: PER RESPONDENT EXPOSURE #################

#' Range area, wind overlap area and % overlap for one season geometry (NA if absent / sliver).
season_stats <- function(g, wind) {
  if (is_empty(g)) return(tibble(range_area_km2 = NA_real_, overlap_area_km2 = NA_real_, pct_overlap = NA_real_))
  a <- as.numeric(sum(sf::st_area(g))) / 1e6
  if (a < min_season_area_km2) return(tibble(range_area_km2 = NA_real_, overlap_area_km2 = NA_real_, pct_overlap = NA_real_))
  o  <- g_int(g, wind)
  oa <- if (is_empty(o)) 0 else as.numeric(sum(sf::st_area(o))) / 1e6
  tibble(range_area_km2 = a, overlap_area_km2 = oa, pct_overlap = oa / a)
}

#' One respondent x one species (df = their polygons): union per season -> clip -> resolve -> stats.
process_one <- function(df, clip, wind) {
  S <- lapply(setNames(season_levels, season_levels), function(s) {
    x <- df[df$season == s, ]
    if (nrow(x) == 0) return(empty_geom())
    g_int(sf::st_union(sf::st_make_valid(sf::st_geometry(x))), clip)     # all polygons of that season, clipped to EAAF
  })
  Rz <- resolve_seasons(S)
  stats <- bind_rows(lapply(season_levels, function(s) bind_cols(tibble(season = s), season_stats(Rz[[s]], wind))))
  stats$raw_area_km2 <- vapply(season_levels, function(s) if (is_empty(S[[s]])) NA_real_ else as.numeric(sum(sf::st_area(S[[s]]))) / 1e6, numeric(1))
  stats$sci_name  <- df$sci_name[1]
  stats$resp_code <- df$resp_code[1]
  list(stats = stats, geoms = Rz)
}

keys   <- split(geoms_pac, list(geoms_pac$sci_name, geoms_pac$resp_code), drop = TRUE)
result <- lapply(keys, process_one, clip = eaaf_geom, wind = wind_geom)

season_long <- bind_rows(lapply(result, `[[`, "stats")) %>%
  select(sci_name, resp_code, season, raw_area_km2, range_area_km2, overlap_area_km2, pct_overlap)

# ---- TEST: resolved areas should add up to the (clipped) union of what each respondent drew ----
season_long %>% group_by(sci_name, resp_code) %>%
  summarise(raw_sum_km2 = sum(raw_area_km2, na.rm = TRUE), resolved_sum_km2 = sum(range_area_km2, na.rm = TRUE),
            .groups = "drop") %>% print(n = Inf)
# resolved_sum <= raw_sum is expected (overlaps between a respondent's own seasons are no longer counted twice)

# ---- per respondent overall: months-weighted over the seasons they drew (same formula as BirdLife) ----
resp_overall <- season_long %>%
  filter(!is.na(pct_overlap)) %>%
  mutate(months = unname(months_lookup[season])) %>%
  group_by(sci_name, resp_code) %>%
  summarise(seasons_present = paste(season[order(match(season, season_levels))], collapse = ", "),
            months_covered  = sum(months),
            overlap_overall = sum(months * pct_overlap) / sum(months),
            .groups = "drop")
resp_overall %>% print(n = Inf)

no_range <- anti_join(distinct(season_long, sci_name, resp_code), resp_overall, by = c("sci_name", "resp_code"))
if (nrow(no_range)) { warning("Respondents with no range inside the EAAF (dropped from stats):"); print(no_range) }


# ############################ PART 6: AGGREGATE ###############################

boot_ci <- function(x, B = n_boot, level = 0.95) {
  if (length(x) < 2) return(c(NA_real_, NA_real_))
  m <- replicate(B, mean(sample(x, length(x), replace = TRUE)))
  unname(quantile(m, c((1 - level) / 2, 1 - (1 - level) / 2)))
}

overall_summ <- resp_overall %>%
  group_by(sci_name) %>%
  summarise(n_respondents  = n(),
            overlap_mean   = mean(overlap_overall),
            overlap_sd     = sd(overlap_overall),
            overlap_se     = overlap_sd / sqrt(n_respondents),
            overlap_median = median(overlap_overall),
            overlap_q25    = unname(quantile(overlap_overall, 0.25)),
            overlap_q75    = unname(quantile(overlap_overall, 0.75)),
            overlap_min    = min(overlap_overall),
            overlap_max    = max(overlap_overall),
            months_covered = mean(months_covered),
            seasons_present = paste(season_levels[season_levels %in% unlist(str_split(seasons_present, ", "))], collapse = ", "),
            overlap_draws  = list(overlap_overall),            # one value per respondent -> the app's `overlap_draws` hook
            .groups = "drop") %>%
  mutate(ci = map(overlap_draws, boot_ci),
         overlap_ci_lo = map_dbl(ci, 1),                       # 95% bootstrap CI of the MEAN across respondents
         overlap_ci_hi = map_dbl(ci, 2)) %>%
  select(-ci)

season_summ <- season_long %>%
  filter(!is.na(pct_overlap)) %>%
  group_by(sci_name, season) %>%
  summarise(n_resp_mapped       = n(),
            pct_overlap_season  = mean(pct_overlap),
            pct_overlap_sd      = sd(pct_overlap),
            range_area_km2      = mean(range_area_km2),
            .groups = "drop") %>%
  pivot_wider(id_cols = sci_name, names_from = season,
              values_from = c(pct_overlap_season, pct_overlap_sd, range_area_km2, n_resp_mapped),
              names_glue = "{.value}_{season}")

# same column names as species_wind_overlap.csv (+ the uncertainty columns), so the app can swap rows
elicited <- overall_summ %>%
  left_join(season_summ, by = "sci_name") %>%
  mutate(overlap_overall     = overlap_mean,
         overlap_overall_pct = 100 * overlap_overall,
         has_passage_mapped  = str_detect(seasons_present, "passage"),
         source              = "elicited") %>%
  left_join(select(species_tbl, sci_name, common_name), by = "sci_name") %>%
  relocate(sci_name, common_name, source, n_respondents, seasons_present, months_covered,
           overlap_overall, overlap_overall_pct)
elicited %>% select(sci_name, n_respondents, overlap_overall_pct, overlap_sd, overlap_ci_lo, overlap_ci_hi, overlap_min, overlap_max)


# ############################ PART 7: WRITE + COMPARE #########################

# private: maps anonymous codes back to names / ids (do NOT share; keep out of git)
bind_rows(resp_kept %>% transmute(resp_code, id, name, created_local = as.character(created_local), status = "kept"),
          resp_dropped %>% transmute(resp_code = NA_character_, id, name, created_local = as.character(created_local),
                                     status = paste("dropped:", drop_reason))) %>%
  write_csv(file.path(out_dir, "PRIVATE_respondent_key.csv"))

write_csv(season_long,  file.path(out_dir, "elicited_respondent_season.csv"))    # respondent x species x season
write_csv(resp_overall, file.path(out_dir, "elicited_respondent_overall.csv"))   # respondent x species
write_rds(elicited,     file.path(out_dir, "species_wind_overlap_elicited.rds")) # keeps the overlap_draws list column
elicited %>%                                                                       # same, readable in Excel
  mutate(overlap_draws = map_chr(overlap_draws, ~ paste(signif(.x, 6), collapse = ";"))) %>%
  write_csv(file.path(out_dir, "species_wind_overlap_elicited.csv"))

# ---- side by side with the BirdLife-range exposure ----
if (file.exists(birdlife_overlap_csv)) {
  comparison <- read_csv(birdlife_overlap_csv, show_col_types = FALSE) %>%
    filter(sci_name %in% species_tbl$sci_name) %>%
    select(sci_name, birdlife_overlap = overlap_overall) %>%
    left_join(elicited %>% select(sci_name, n_respondents, elicited_mean = overlap_overall,
                                  elicited_ci_lo = overlap_ci_lo, elicited_ci_hi = overlap_ci_hi,
                                  elicited_min = overlap_min, elicited_max = overlap_max), by = "sci_name") %>%
    mutate(elicited_over_birdlife = elicited_mean / birdlife_overlap)
  write_csv(comparison, file.path(out_dir, "exposure_birdlife_vs_elicited.csv"))
  print(comparison)
}

# ---- quick plot: each dot = one respondent; diamond = BirdLife range-map value ----
p <- ggplot(resp_overall, aes(x = 100 * overlap_overall, y = 1)) +
  geom_jitter(height = 0.15, width = 0, alpha = 0.7, size = 2) +
  geom_pointrange(data = elicited, aes(x = 100 * overlap_overall, xmin = 100 * overlap_ci_lo, xmax = 100 * overlap_ci_hi, y = 0.6),
                  colour = "#1E4E5B") +
  { if (exists("comparison")) geom_point(data = comparison, aes(x = 100 * birdlife_overlap, y = 1.4), shape = 18, size = 4, colour = "#d62828") } +
  facet_wrap(~sci_name, scales = "free_x", ncol = 1) +
  scale_y_continuous(limits = c(0.4, 1.6), breaks = NULL) +
  labs(x = "Overall wind overlap (% of range)", y = NULL,
       subtitle = "dots = respondents; teal = mean and 95% bootstrap CI; red diamond = BirdLife range map") +
  theme_minimal()
ggsave(file.path(out_dir, "elicited_exposure_by_respondent.png"), p, width = 7, height = 6, dpi = 200, bg = "white")

# ---- how to use in the app later ----
# swap the elicited rows in for the three species (keeps every other species as is):
# birdlife <- read_csv(birdlife_overlap_csv)
# swapped  <- bind_rows(filter(birdlife, !sci_name %in% elicited$sci_name), elicited)
# the app's build_exposure() already uses a list column called `overlap_draws` when present.


# ############################ PART 8: CONSENSUS MAP (optional) ################

# For each species x season: share of respondents who drew each cell (0-1), using each respondent's
# RESOLVED seasons (so the rules in PART 4 are already applied). The consensus range = cells with
# agreement >= consensus_threshold; the rules are applied once more to the consensus layers
# (in case two seasons both clear the threshold in the same cell), then exposure is computed as usual.

if (make_consensus) {
  cons_dir <- file.path(out_dir, "consensus"); dir.create(cons_dir, showWarnings = FALSE)
  bb <- sf::st_bbox(eaaf_geom)
  tmpl <- terra::rast(xmin = bb[["xmin"]], xmax = bb[["xmax"]], ymin = bb[["ymin"]], ymax = bb[["ymax"]],
                      resolution = consensus_res_m, crs = crs_pac, vals = 0)

  cons_stats <- list(); cons_geoms <- list()
  for (sp in species_tbl$sci_name) {
    ks <- names(result)[vapply(result, function(r) r$stats$sci_name[1] == sp, logical(1))]
    n_sp <- length(ks)
    if (n_sp == 0) next
    slug <- gsub("[^a-z]+", "_", tolower(sp))

    cons_layers <- lapply(setNames(season_levels, season_levels), function(s) {
      agree <- tmpl
      for (k in ks) {
        g <- result[[k]]$geoms[[s]]
        if (!is_empty(g)) {
          v <- terra::vect(sf::st_sf(geometry = g))
          terra::crs(v) <- terra::crs(tmpl)          # same CRS, just spelled the same way as the template
          agree <- agree + terra::rasterize(v, tmpl, field = 1, background = 0)
        }
      }
      agree <- agree / n_sp
      names(agree) <- paste0("agreement_", gsub("-", "", s))
      terra::writeRaster(agree, file.path(cons_dir, paste0(slug, "_", gsub("-", "", s), "_agreement.tif")), overwrite = TRUE)

      hit <- terra::ifel(agree >= consensus_threshold, 1, NA)
      if (all(is.na(terra::values(hit)))) return(empty_geom())
      cp <- sf::st_union(sf::st_as_sf(terra::as.polygons(hit, dissolve = TRUE)))
      suppressWarnings(sf::st_crs(cp) <- sf::st_crs(crs_pac))   # identical CRS; avoids a WKT-vs-proj-string mismatch
      g_int(cp, eaaf_geom)
    })

    Rz <- resolve_seasons(cons_layers)
    cons_geoms[[sp]] <- Rz
    cons_stats[[sp]] <- bind_rows(lapply(season_levels, function(s) bind_cols(tibble(sci_name = sp, season = s), season_stats(Rz[[s]], wind_geom))))
  }

  consensus_season <- bind_rows(cons_stats)
  consensus_overall <- consensus_season %>%
    filter(!is.na(pct_overlap)) %>%
    mutate(months = unname(months_lookup[season])) %>%
    group_by(sci_name) %>%
    summarise(consensus_overlap = sum(months * pct_overlap) / sum(months),
              consensus_seasons = paste(season, collapse = ", "), .groups = "drop")

  write_csv(consensus_season,  file.path(cons_dir, "consensus_season_stats.csv"))
  write_csv(consensus_overall, file.path(cons_dir, "consensus_overall.csv"))
  write_rds(cons_geoms,        file.path(cons_dir, "consensus_ranges_pac.rds"))   # sfc per species x season, in crs_pac
  print(consensus_overall)
  # compare: consensus-range exposure vs mean of per-respondent exposure (they will differ - ratio of means
  # vs mean of ratios - and the gap itself says something about how much the experts disagree)
}


# ############################ PART 9: FILES FOR THE APP'S EXPERT RANGE EXPLORER #

# Writes everything the "Expert range explorer" tab needs into ONE folder, expert_data/:
#   expert_data/expert_index.csv        one row per species: n experts, mean / lowest / highest per-expert overall
#                                        overlap, 95% CI of the mean, BirdLife range-map value, consensus value
#   expert_data/ranges/<species>.rds    per species list(ranges, overlap, wind, stats, overall):
#       ranges   sf (lon/lat, longitudes 0-360 like the rest of the app): one row per expert x season (+ "Consensus")
#       overlap  sf: the part of each of those ranges inside a wind footprint
#       wind     sf: wind footprints touching any of them; hit_key says who ("R01:breeding;R03:resident")
#       stats    per expert x season: months, range area, overlap area, pct_overlap
#       overall  per expert: seasons_present, months_covered, overlap_overall
# Then copy (or set app_copy_dir) the expert_data/ folder next to app.R.
# Expert codes (R01, R02, ...) are the anonymous ones from PART 1; names never go into these files.

app_copy_dir <- NA     # e.g. "~/path/to/app" -> expert_data/ is also copied there at the end (NA = don't copy)

expert_dir <- file.path(out_dir, "expert_data")
dir.create(file.path(expert_dir, "ranges"), recursive = TRUE, showWarnings = FALSE)

slugify <- function(x) stringr::str_replace_all(stringr::str_to_lower(x), "[^a-z]+", "_") %>% stringr::str_remove("_$")

# analysis CRS -> lon/lat with longitudes in 0-360 (Pacific stays in one piece; leaflet accepts lng > 180)
to_web <- function(x) x %>% sf::st_transform(4326) %>% wrap_lon(lon0 = 180)

# simplify for display only (areas and overlaps above were computed on the unsimplified shapes);
# tolerance scales with the shape's own area, same idea as build_map_data.R
simp_geom <- function(g) {
  a   <- as.numeric(sum(sf::st_area(g)))
  tol <- min(3000, 0.002 * sqrt(a))
  if (tol < 5) return(g)
  s <- tryCatch(sf::st_make_valid(sf::st_simplify(g, preserveTopology = TRUE, dTolerance = tol)), error = function(e) g)
  if (is_empty(s)) g else s
}

wind_keep <- base::intersect(c("project_na", "project_name", "country_ar", "country_area", "capacity_m",
                               "capacity_mw", "installati", "installation_type", "status"), names(wind_pac))

#' Everything the tab needs for one species. `sources` = one entry per expert (+ the consensus, if made):
#' list(code, geoms = four season geometries in crs_pac, in the same order as season_levels).
build_expert_obj <- function(sp) {
  ks <- names(result)[vapply(result, function(r) r$stats$sci_name[1] == sp, logical(1))]
  if (length(ks) == 0) return(NULL)
  sources <- lapply(ks, function(k) list(code = result[[k]]$stats$resp_code[1], geoms = result[[k]]$geoms))
  if (exists("cons_geoms") && !is.null(cons_geoms[[sp]])) {
    sources <- c(sources, list(list(code = "Consensus", geoms = cons_geoms[[sp]])))
  }

  rng <- list(); ovl <- list(); sts <- list(); hit <- list()
  for (src in sources) {
    for (s in season_levels) {
      g <- src$geoms[[s]]
      if (is_empty(g)) next
      a <- as.numeric(sum(sf::st_area(g))) / 1e6
      if (a < min_season_area_km2) next
      ss <- season_stats(g, wind_geom)
      sts[[length(sts) + 1]] <- bind_cols(tibble(resp_code = src$code, season = s, months = unname(months_lookup[s])), ss)
      rng[[length(rng) + 1]] <- sf::st_sf(tibble(resp_code = src$code, season = s, range_area_km2 = a), geometry = simp_geom(g))
      o <- g_int(g, wind_geom)
      if (!is_empty(o)) ovl[[length(ovl) + 1]] <- sf::st_sf(tibble(resp_code = src$code, season = s), geometry = simp_geom(o))
      idx <- which(lengths(sf::st_intersects(wind_pac, g)) > 0)
      if (length(idx)) hit[[length(hit) + 1]] <- tibble(wind_row = idx, key = paste0(src$code, ":", s))
    }
  }
  if (length(rng) == 0) return(NULL)

  hit_df <- bind_rows(hit)
  wind_sf <- NULL
  if (nrow(hit_df) > 0) {
    hk <- hit_df %>% group_by(wind_row) %>% summarise(hit_key = paste(key, collapse = ";"), .groups = "drop")
    wind_sf <- wind_pac[hk$wind_row, wind_keep, drop = FALSE]
    wind_sf$hit_key <- hk$hit_key
    wind_sf <- to_web(wind_sf)
  }

  stats <- bind_rows(sts)
  ov_all <- stats %>%
    filter(!is.na(pct_overlap)) %>%
    group_by(resp_code) %>%
    summarise(seasons_present = paste(season[order(match(season, season_levels))], collapse = ", "),
              months_covered  = sum(months),
              overlap_overall = sum(months * pct_overlap) / sum(months), .groups = "drop")

  list(species = sp,
       ranges  = to_web(dplyr::bind_rows(rng)),
       overlap = if (length(ovl)) to_web(dplyr::bind_rows(ovl)) else NULL,
       wind    = wind_sf,
       stats   = stats,
       overall = ov_all)
}

# ---- TEST on one species first: sizes and a quick look ----
test_obj <- build_expert_obj(species_tbl$sci_name[1])
test_obj$overall                                   # one row per expert (+ Consensus); overlap_overall is a fraction (0-1)
print(object.size(test_obj), units = "Kb")         # want well under ~1 Mb per species
plot(sf::st_geometry(test_obj$ranges), col = "#2a9d8f33", axes = TRUE)

# ---- all species ----
index_rows <- list()
for (sp in species_tbl$sci_name) {
  obj <- tryCatch(build_expert_obj(sp), error = function(e) { message("FAILED: ", sp, " - ", conditionMessage(e)); NULL })
  if (is.null(obj)) next
  saveRDS(obj, file.path(expert_dir, "ranges", paste0(slugify(sp), ".rds")))
  index_rows[[sp]] <- tibble(sci_name = sp, file = paste0("ranges/", slugify(sp), ".rds"))
}

# ---- index: one row per species, the headline numbers (per-expert overall overlap, as fractions 0-1) ----
bl <- if (file.exists(birdlife_overlap_csv)) {
  read_csv(birdlife_overlap_csv, show_col_types = FALSE) %>% select(sci_name, birdlife_overlap = overlap_overall)
} else tibble(sci_name = character(), birdlife_overlap = numeric())
cons_ov <- if (exists("consensus_overall")) {
  select(consensus_overall, sci_name, consensus_overlap)
} else tibble(sci_name = character(), consensus_overlap = numeric())

expert_index <- bind_rows(index_rows) %>%
  left_join(select(species_tbl, sci_name, common_name), by = "sci_name") %>%
  left_join(select(elicited, sci_name, n_respondents, overlap_mean = overlap_overall, overlap_sd,
                   overlap_ci_lo, overlap_ci_hi, overlap_lo = overlap_min, overlap_hi = overlap_max,
                   seasons_present, months_covered), by = "sci_name") %>%
  left_join(bl, by = "sci_name") %>%
  left_join(cons_ov, by = "sci_name") %>%
  relocate(sci_name, common_name, n_respondents, overlap_lo, overlap_mean, overlap_hi)
write_csv(expert_index, file.path(expert_dir, "expert_index.csv"))
expert_index
sum(file.size(list.files(expert_dir, recursive = TRUE, full.names = TRUE))) / 1e6      # MB the app will ship

if (!is.na(app_copy_dir)) {
  file.copy(expert_dir, app_copy_dir, recursive = TRUE, overwrite = TRUE)   # -> <app_copy_dir>/expert_data/
}
