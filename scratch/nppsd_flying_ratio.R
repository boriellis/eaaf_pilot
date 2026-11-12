# =============================================================================
# nppsd_flying_ratio.R
# Flying ratio (a DFA proxy) from the North Pacific Pelagic Seabird Database
# (NPPSD v4.1), following the Kelsey et al. 2025 approach:
#   ratio = flying individuals / (flying + on-water individuals), per species,
#   only for species with > 100 sightings; skip species that spend lots of time
#   on land (cormorants, terns) because the ratio is biased for them.
#
# NOT YET RUN: written without access to the data. Step 1 prints the column names
# so you can confirm them; the CONFIG block is the only place you should need to edit.
# Work through it top to bottom, running each step and checking the printout.
# =============================================================================

library(tidyverse)
library(readxl)   # only needed for step 7 (comparison with our sheet)

# ---- CONFIG ------------------------------------------------------------------
cfg <- list(
  # Paths are relative to the project root (run from there, or open the .Rproj).
  in_dir     = file.path("data", "raw", "nppsd"),
  out_dir    = file.path("data", "processed", "nppsd"),
  obs_name   = "Observations_NPPSDv4.1.csv",        # required
  loc_name   = "Locations_NPPSDv4.1.csv",           # needed for fly_bird_method (step 2)
  tax_name   = "SpeciesTaxonomy_NPPSDv4.1.csv",     # maps species_code -> names (step 6)
  # Our species sheet, for the comparison in step 7. Put it wherever you keep it; if the
  # file is not found, step 7 is skipped with a message.
  sheet_file = file.path("data", "raw", "TBC_offline_backup_v1.3.xlsx"),
  
  min_birds  = 100,     # Kelsey: ">100 sightings" (we report both birds and records; filter uses birds)
  min_records = 0,      # optional extra filter on number of observation records
  only_on_transect = FALSE,   # TRUE = keep only on_off_tx == "ON"
  methods_keep = NULL   # e.g. c("Snapshot") to restrict by fly_bird_method; NULL = keep all (reported separately)
)

# Column names as given in the NPPSD metadata. Edit here if step 1 shows something different.
col <- list(
  species  = "species_code",
  behavior = "primary_behavior",   # Fly / Land / Water / Unknown
  count    = "number",
  loc_id   = "location_id",
  on_off   = "on_off_tx"
)

dir.create(cfg$out_dir, recursive = TRUE, showWarnings = FALSE)

# Full paths + existence check, so a wrong folder fails here with a clear message.
obs_path <- file.path(cfg$in_dir, cfg$obs_name)
loc_path <- file.path(cfg$in_dir, cfg$loc_name)
tax_path <- file.path(cfg$in_dir, cfg$tax_name)
for (f in c(obs_path, loc_path, tax_path))
  if (!file.exists(f)) stop("File not found: ", f, "  (working directory is ", getwd(), ")")
have_sheet <- file.exists(cfg$sheet_file)
if (!have_sheet) message("Sheet not found at ", cfg$sheet_file, " -> step 7 will be skipped")

# ---- STEP 1: read observations and check the columns -------------------------
# Only keep the columns we need; the file is ~120 MB.
obs_head <- read_csv(obs_path, n_max = 5, show_col_types = FALSE)
print(names(obs_head))                     # <-- check these against col above
stopifnot(all(unlist(col) %in% names(obs_head)))

obs <- read_csv(obs_path,
                # unname(): a named vector in col_select renames on read, which broke the rename() below
                col_select = all_of(unname(unlist(col))),
                show_col_types = FALSE) %>%
  rename(species = !!col$species, behavior = !!col$behavior, n = !!col$count,
         location_id = !!col$loc_id, on_off = !!col$on_off)

cat("\nObservation rows:", nrow(obs), "\n")
print(count(obs, behavior, wt = n, name = "birds"))      # how many birds per behavior class

# ---- STEP 2: join survey info from Locations ----------------------
# fly_bird_method says whether flying birds were counted Continuous (biased high from a
# moving boat) or Snapshot. We carry it through so the ratio can be split by method.
{
  loc_head <- read_csv(loc_path, n_max = 5, show_col_types = FALSE)
  print(names(loc_head))                  # <-- check: needs location_id and fly_bird_method
  loc <- read_csv(loc_path, show_col_types = FALSE) %>%
    select(location_id, any_of(c("fly_bird_method", "modified_survey_type",
                                 "modified_platform_type", "local_date_time")))
  obs <- left_join(obs, loc, by = "location_id")
  print(count(obs, fly_bird_method, wt = n, name = "birds"))
}

# ---- STEP 3: filter to flying vs on-water ------------------------------------
# Kelsey: birds were recorded as either flying or on the water. Land and Unknown are dropped.
dat <- obs %>%
  filter(behavior %in% c("Fly", "Water"))
if (cfg$only_on_transect) dat <- filter(dat, on_off == "ON")
if (!is.null(cfg$methods_keep)) dat <- filter(dat, fly_bird_method %in% cfg$methods_keep)

# ---- STEP 4: ratio per species (all methods pooled) --------------------------
ratio_fun <- function(d, ...) {
  d %>%
    group_by(species, ...) %>%
    summarise(birds_fly   = sum(n[behavior == "Fly"],   na.rm = TRUE),
              birds_water = sum(n[behavior == "Water"], na.rm = TRUE),
              birds_total = birds_fly + birds_water,
              records     = n(),
              flying_ratio = birds_fly / birds_total,
              .groups = "drop")
}

pooled <- ratio_fun(dat)

# ---- STEP 5: ratio per species x method (to see the continuous-vs-snapshot bias) ----
by_method <- ratio_fun(dat, fly_bird_method)

# ---- STEP 6: attach names, apply the sighting filter, flag land-time groups ----
{
  tax <- read_csv(tax_path, show_col_types = FALSE)
  print(names(tax))   # <-- check which columns hold common / scientific names
  # The column names below are guesses; edit after looking at the printout.
  tax_keep <- tax %>% select(species_code, any_of(c("common_name", "scientific_name", "family")))
  pooled    <- left_join(pooled,    tax_keep, by = c("species" = "species_code"))
  by_method <- left_join(by_method, tax_keep, by = c("species" = "species_code"))
}

# Kelsey excluded species that spend a lot of time on land (cormorants, terns) because the
# flying:water ratio is biased by birds on land that were not counted. Flag them by name.
land_pattern <- "cormorant|shag|tern\\b|noddy"
pooled <- pooled %>%
  mutate(passes_min = birds_total > cfg$min_birds & records >= cfg$min_records,
         land_time_group = if ("common_name" %in% names(.))
           str_detect(str_to_lower(common_name), land_pattern) else NA)

write_csv(pooled,    file.path(cfg$out_dir, "nppsd_flying_ratio_pooled.csv"))
write_csv(by_method, file.path(cfg$out_dir, "nppsd_flying_ratio_by_method.csv"))
cat("\nSpecies with ratio:", nrow(pooled), " | passing filter:", sum(pooled$passes_min), "\n")

# ---- STEP 7 (optional): compare with the DFA / FA values already in our sheet ----
# Reads the Seabirds tab: header on row 3, data from row 4. Matches on scientific name.
if (have_sheet && "scientific_name" %in% names(pooled)) {
  ours <- read_excel(cfg$sheet_file, sheet = "Seabirds", skip = 2) %>%
    select(ScientificName, CommonName, DFA, FA, FA_Reference) %>%
    mutate(across(c(DFA, FA), ~ suppressWarnings(as.numeric(.x))))
  
  cmp <- pooled %>%
    filter(passes_min) %>%
    inner_join(ours, by = c("scientific_name" = "ScientificName")) %>%
    mutate(diff_vs_DFA = flying_ratio - DFA)
  write_csv(cmp, file.path(cfg$out_dir, "nppsd_vs_sheet.csv"))
  
  cat("\nSpecies compared with sheet DFA:", sum(!is.na(cmp$DFA)), "\n")
  cat("Correlation with DFA:", round(cor(cmp$flying_ratio, cmp$DFA, use = "complete.obs"), 2), "\n")
  
  # Candidate fills: species passing the filter that have NO FA in our sheet
  fills <- pooled %>%
    filter(passes_min) %>%
    inner_join(ours, by = c("scientific_name" = "ScientificName")) %>%
    filter(is.na(FA))
  write_csv(fills, file.path(cfg$out_dir, "nppsd_candidate_fills.csv"))
  cat("Candidate fills (no FA in sheet):", nrow(fills), "\n")
}

# ---- QUICK LOOK: ratio by method for the species we care about most -----------
by_method %>% filter(birds_total > cfg$min_birds) %>%
  arrange(species, fly_bird_method) %>% print(n = 40)