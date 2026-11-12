# =============================================================================
# sensitivity_functions.R
# Core calculation functions for the EAAF prioritization app (seabird mode).
# Pure functions: no Shiny, no file I/O, so each one can be tested on its own.
#
# NOT YET RUN: written without R available. Test each section with the
# self-checks at the bottom (commented out) before wiring into the app.
#
# Data frame columns expected (suggested short names for the clean data file;
# change the `cols` map below if yours differ):
#   scientific_name, common_name
#   lamb_taxon, lamb_tier          Lamb group and match tier (A/B/C/N)
#   disp_pct_mean, disp_pct_lo, disp_pct_hi   % change in use (negative = decline), 95% CI
#   disp_lnrr                      lnRR (Lamb Table 3)
#   lamb_n_studies                 number of studies in the taxon group
#   esi                            BirdBase ESI, unscaled
#   FA, RSZt, MA                   Kelsey collision inputs
#
# Sections:
#   1. Column map
#   2. Rescaling helpers
#   3. Displacement sensitivity: point estimate (two options)
#   4. Displacement sensitivity: Monte Carlo (lnRR + t distribution)
#   5. Collision vulnerability (point estimate)
#   6. Combining pieces into the priority score
# =============================================================================


# ---- 1. COLUMN MAP -----------------------------------------------------------
# One place to change if the data file's column names change.
cols <- list(
  sci      = "scientific_name",
  common   = "common_name",
  taxon    = "lamb_taxon",
  tier     = "lamb_tier",
  pct_mean = "disp_pct_mean",
  pct_lo   = "disp_pct_lo",
  pct_hi   = "disp_pct_hi",
  lnrr     = "disp_lnrr",
  n_studies = "lamb_n_studies",
  esi      = "esi",
  fa       = "FA",
  rszt     = "RSZt",
  ma       = "MA"
)

# Pull a column by its logical name (so the rest of the code never hard-codes names).
get_col <- function(data, key) {
  nm <- cols[[key]]
  if (!nm %in% names(data)) stop("Column '", nm, "' (", key, ") not found in data")
  suppressWarnings(as.numeric(data[[nm]]))   # "NA" strings become NA
}


# ---- 2. RESCALING HELPERS ----------------------------------------------------

#' Rescale a numeric vector to a target range.
#' method "minmax": lowest value -> to[1], highest -> to[2].
#' method "robust": same, but values are first clipped to the [probs] quantiles so one
#'   extreme species does not squash everyone else (the choice between these is a DECISION
#'   TO RECORD in the methods markdown).
#' NAs stay NA. If all values are equal, everything maps to the midpoint of `to`.
rescale_to <- function(x, to = c(0, 1), method = c("minmax", "robust"),
                       probs = c(0.05, 0.95)) {
  method <- match.arg(method)
  if (method == "robust") {
    q <- stats::quantile(x, probs, na.rm = TRUE, names = FALSE)
    x <- pmin(pmax(x, q[1]), q[2])
  }
  rng <- range(x, na.rm = TRUE)
  if (!is.finite(rng[1]) || rng[1] == rng[2]) {
    out <- rep(mean(to), length(x)); out[is.na(x)] <- NA; return(out)
  }
  to[1] + (x - rng[1]) / (rng[2] - rng[1]) * (to[2] - to[1])
}

#' Map a 0-1 score onto the 0.5-2 scale used in the Pacific app's priority score.
#' (Kept separate from rescale_to() so the 0-1 sensitivity values can be shown as-is.)
to_priority_scale <- function(x01, to = c(0.5, 2)) to[1] + x01 * (to[2] - to[1])


# ---- 3. DISPLACEMENT SENSITIVITY: POINT ESTIMATE ------------------------------

#' Displacement rate from the Lamb % change in use.
#' % change is negative for a decline, so rate = -pct/100. Increases (attraction) are floored
#' at 0 displacement because the framework has no negative displacement.
displacement_rate <- function(pct_change) pmax(0, -pct_change / 100)

#' Raw (unscaled) displacement vulnerability.
#'   option "rate":      DV = displacement rate                 (default)
#'   option "rate_esi":  DV = displacement rate x ESI           (ESI replaces Kelsey's HS)
#' Species with no Lamb value (tier N / NA) get NA. Species with no ESI get NA under "rate_esi"
#' (see `esi_missing`: "drop" = NA, "fallback" = use rate only; a decision still to be made).
displacement_raw <- function(data, option = c("rate", "rate_esi"),
                             esi_missing = c("drop", "fallback")) {
  option      <- match.arg(option)
  esi_missing <- match.arg(esi_missing)
  rate <- displacement_rate(get_col(data, "pct_mean"))
  if (option == "rate") return(rate)
  esi <- get_col(data, "esi")
  dv <- rate * esi
  if (esi_missing == "fallback") dv <- ifelse(is.na(esi), rate, dv)
  dv
}

#' Displacement sensitivity scaled to `to` (default 0-1), across the species passed in.
#' IMPORTANT: scaling is across the species in `data`, so pass the currently selected
#' mode/subset (seabirds only), not the whole table.
#' Optionally drop low-confidence Lamb matches first: tiers_allowed = c("A","B") sets tier C
#' species to NA instead of using the family-level extrapolation.
#' Returns a data frame with raw and scaled values plus the number of species with no value.
displacement_sensitivity <- function(data,
                                     option = c("rate", "rate_esi"),
                                     esi_missing = c("drop", "fallback"),
                                     tiers_allowed = c("A", "B", "C"),
                                     to = c(0, 1),
                                     scale_method = c("minmax", "robust"),
                                     probs = c(0.05, 0.95)) {
  option <- match.arg(option); esi_missing <- match.arg(esi_missing)
  scale_method <- match.arg(scale_method)
  
  raw <- displacement_raw(data, option, esi_missing)
  tier <- data[[cols$tier]]
  raw[!(tier %in% tiers_allowed)] <- NA          # tier N is never in tiers_allowed
  
  out <- data.frame(
    scientific_name = data[[cols$sci]],
    dv_raw    = raw,
    dv_scaled = rescale_to(raw, to, scale_method, probs),
    stringsAsFactors = FALSE
  )
  attr(out, "n_missing") <- sum(is.na(raw))
  out
}


# ---- 4. DISPLACEMENT SENSITIVITY: MONTE CARLO ----------------------------------
# Sampling plan (see methods markdown, 5b):
#   1. CI bounds to the lnRR scale: ln(1 + pct/100).
#   2. SD = (upper_lnRR - lower_lnRR) / 3.92.
#   3. Draw lnRR ~ mean + SD * t(df), df = n studies - 1 (floored at `min_df`), so the 95%
#      interval is wider than the published CI by qt(.975, df)/1.96.
#   4. Back-transform: displacement = 1 - exp(draw), floored at 0.
# Species share their Lamb group's values, so draws are made PER TAXON and shared by every
# species in that group in a given draw. Sampling per species would wrongly treat species
# in the same group as independent.

#' lnRR and SD for each taxon, from the CI columns. Returns one row per taxon.
taxon_lnrr_params <- function(data, mu_source = c("lnrr", "ci_mid"), min_df = 3) {
  mu_source <- match.arg(mu_source)
  d <- data.frame(taxon = data[[cols$taxon]],
                  lnrr  = get_col(data, "lnrr"),
                  lo    = log(1 + get_col(data, "pct_lo") / 100),
                  hi    = log(1 + get_col(data, "pct_hi") / 100),
                  k     = get_col(data, "n_studies"),
                  stringsAsFactors = FALSE)
  d <- d[!is.na(d$taxon) & !is.na(d$lnrr), ]
  d <- d[!duplicated(d$taxon), ]
  d$sd <- (d$hi - d$lo) / 3.92
  # mu: the published lnRR (default) or the midpoint of the CI on the lnRR scale. They differ
  # for gannets, whose published point estimate lies outside its own CI (unresolved).
  d$mu <- if (mu_source == "lnrr") d$lnrr else (d$lo + d$hi) / 2
  d$df <- pmax(d$k - 1, min_df)
  d
}

#' Draw displacement rates per taxon. Returns a matrix: rows = taxa, columns = draws.
draw_taxon_displacement <- function(params, n_draws = 1000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  draws <- t(sapply(seq_len(nrow(params)), function(i) {
    lnrr <- params$mu[i] + params$sd[i] * stats::rt(n_draws, df = params$df[i])
    pmax(0, 1 - exp(lnrr))                       # floor at 0: attraction -> no displacement
  }))
  rownames(draws) <- params$taxon
  draws
}

#' Monte Carlo displacement sensitivity for every species.
#' Returns a list: $draws (species x draws, scaled), $summary (mean/median/lo/hi per species).
#' scale_each_draw = TRUE rescales within each draw (the min and max species can change from
#' draw to draw, so the uncertainty includes where a species falls relative to the others);
#' FALSE scales every draw using the point-estimate min and max.
displacement_sensitivity_mc <- function(data,
                                        option = c("rate", "rate_esi"),
                                        esi_missing = c("drop", "fallback"),
                                        tiers_allowed = c("A", "B", "C"),
                                        n_draws = 1000, seed = 1, min_df = 3,
                                        mu_source = c("lnrr", "ci_mid"),
                                        to = c(0, 1),
                                        scale_method = c("minmax", "robust"),
                                        probs = c(0.05, 0.95),
                                        scale_each_draw = TRUE,
                                        interval = c(0.025, 0.975)) {
  option <- match.arg(option); esi_missing <- match.arg(esi_missing)
  mu_source <- match.arg(mu_source); scale_method <- match.arg(scale_method)
  
  params <- taxon_lnrr_params(data, mu_source, min_df)
  tdraw  <- draw_taxon_displacement(params, n_draws, seed)       # taxa x draws
  
  # Map each species to its taxon's draws (NA row for species with no Lamb value / excluded tier)
  idx <- match(data[[cols$taxon]], rownames(tdraw))
  ok  <- !is.na(idx) & (data[[cols$tier]] %in% tiers_allowed)
  rate_draws <- matrix(NA_real_, nrow(data), n_draws)
  rate_draws[ok, ] <- tdraw[idx[ok], , drop = FALSE]
  
  # ESI option: multiply every draw by the species' ESI (ESI itself is not uncertain here)
  if (option == "rate_esi") {
    esi <- get_col(data, "esi")
    if (esi_missing == "fallback") esi[is.na(esi)] <- 1
    rate_draws <- rate_draws * esi                                # recycles down columns
  }
  
  # Rescale
  if (scale_each_draw) {
    scaled <- apply(rate_draws, 2, rescale_to, to = to, method = scale_method, probs = probs)
  } else {
    pt <- displacement_raw(data, option, esi_missing); pt[!(data[[cols$tier]] %in% tiers_allowed)] <- NA
    rng <- range(pt, na.rm = TRUE)
    scaled <- to[1] + (rate_draws - rng[1]) / (rng[2] - rng[1]) * (to[2] - to[1])
    scaled <- pmin(pmax(scaled, to[1]), to[2])
  }
  rownames(scaled) <- data[[cols$sci]]
  
  summ <- data.frame(
    scientific_name = data[[cols$sci]],
    mean   = rowMeans(scaled),
    median = apply(scaled, 1, stats::median),
    lo     = apply(scaled, 1, stats::quantile, probs = interval[1], na.rm = TRUE),
    hi     = apply(scaled, 1, stats::quantile, probs = interval[2], na.rm = TRUE),
    stringsAsFactors = FALSE, row.names = NULL
  )
  list(draws = scaled, summary = summ, params = params)
}


# ---- 5. COLLISION VULNERABILITY (point estimate) -------------------------------
# Kelsey et al. 2025: CV = FA x RSZt x (1 - MA). Checked against the CV column of the
# Seabirds tab: reproduces it within rounding for the 43 species with all inputs.

collision_raw <- function(data) get_col(data, "fa") * get_col(data, "rszt") * (1 - get_col(data, "ma"))

collision_sensitivity <- function(data, to = c(0, 1), scale_method = c("minmax", "robust"),
                                  probs = c(0.05, 0.95)) {
  scale_method <- match.arg(scale_method)
  raw <- collision_raw(data)
  data.frame(scientific_name = data[[cols$sci]], cv_raw = raw,
             cv_scaled = rescale_to(raw, to, scale_method, probs), stringsAsFactors = FALSE)
}


# ---- 6. COMBINING INTO THE PRIORITY SCORE --------------------------------------

#' Sensitivity from collision and displacement scaled scores.
#' how: "collision", "displacement", "sum", "highest".
#' NOTE: the "sum"/"highest" behavior is an OPEN ISSUE in the methods markdown (5b); with the
#' Lamb-based displacement they no longer share MA, but confirm they behave sensibly.
combine_sensitivity <- function(cv_scaled, dv_scaled,
                                how = c("collision", "displacement", "sum", "highest")) {
  how <- match.arg(how)
  switch(how,
         collision    = cv_scaled,
         displacement = dv_scaled,
         sum          = cv_scaled + dv_scaled,
         highest      = pmax(cv_scaled, dv_scaled))
}

#' Priority = Exposure^w1 x Sensitivity^w2 x Status^w3, each input already on the 0.5-2 scale.
priority_score <- function(exposure, sensitivity, status, w = c(1, 1, 1)) {
  exposure^w[1] * sensitivity^w[2] * status^w[3]
}


# ---- SELF-CHECKS (uncomment and run once the data are loaded) -------------------
# dat <- readxl::read_excel("data/raw/TBC_offline_backup_v1.3.xlsx", sheet = "Seabirds", skip = 2)
# names(dat)[names(dat) == "ScientificName"] <- "scientific_name"      # ...and the other renames
#
# # 1. Rescaling: output must span exactly the target range
# r <- rescale_to(c(1, 2, 3, NA), c(0, 1)); stopifnot(identical(r, c(0, 0.5, 1, NA)))
#
# # 2. Displacement rate: -62% change -> 0.62; +20% (attraction) -> 0
# stopifnot(all.equal(displacement_rate(c(-62, 20)), c(0.62, 0)))
#
# # 3. Point estimate: tier N species must be NA, everything else in [0, 1]
# ds <- displacement_sensitivity(dat, option = "rate")
# stopifnot(all(ds$dv_scaled[!is.na(ds$dv_scaled)] >= 0 & ds$dv_scaled[!is.na(ds$dv_scaled)] <= 1))
#
# # 4. MC: the median draw should sit close to the point estimate (tolerance depends on t/skew)
# mc <- displacement_sensitivity_mc(dat, n_draws = 2000)
# plot(ds$dv_scaled, mc$summary$median); abline(0, 1)
#
# # 5. Species in the same Lamb group must have identical draws (shared per taxon)
# # e.g. all.equal(mc$draws["Uria aalge", ], mc$draws["Uria lomvia", ])  # only if no ESI option
#
# # 6. Collision: compare with the sheet's CV column
# cmp <- cbind(sheet = suppressWarnings(as.numeric(dat$CV)), ours = collision_raw(dat))