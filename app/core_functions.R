# =============================================================================
# core_functions.R  -  prototype calculation pipeline (seabirds, point estimates)
# Pure functions, no Shiny. NOT YET RUN (R was not available where this was written).
#
# DESIGN: every input is built as a species x D matrix of "draws". With point
# estimates D = 1. To add uncertainty later, replace the build_*() functions with
# samplers that return D > 1 columns; rescaling, combining, priority and summaries
# already work column-by-column and need no changes.
#
# Pipeline:  data -> build_inputs() -> scale_inputs() -> priority_draws() -> summarise_priority()
# =============================================================================

# ---- helpers -----------------------------------------------------------------
# Same as the Pacific app: geometric map of x onto 0.5-2 (exp of a linear map onto log(0.5)-log(2)).
# Differences: NA-safe, and a constant vector maps to 1 (midpoint on the log scale).
log_rescale <- function(x, to = c(0.5, 2)) {
  rng <- range(x, na.rm = TRUE)
  if (!is.finite(rng[1]) || rng[1] == rng[2]) return(ifelse(is.na(x), NA_real_, sqrt(prod(to))))
  exp(log(to[1]) + (log(to[2]) - log(to[1])) * (x - rng[1]) / (rng[2] - rng[1]))
}
rescale_01 <- function(x) {
  rng <- range(x, na.rm = TRUE)
  if (!is.finite(rng[1]) || rng[1] == rng[2]) return(ifelse(is.na(x), NA_real_, 0.5))
  (x - rng[1]) / (rng[2] - rng[1])
}
# Geometric mean (the central value wherever one is needed). Non-positive values -> NA.
geo_mean <- function(x, na.rm = TRUE) {
  x <- x[!is.na(x)]
  if (!length(x) || any(x <= 0)) return(NA_real_)
  exp(mean(log(x)))
}
# Apply a vector function down each column of a matrix (one draw = one column).
col_apply <- function(m, f, ...) {
  out <- apply(m, 2, f, ...)
  if (is.null(dim(out))) out <- matrix(out, nrow = nrow(m))   # n = 1 row edge case
  dimnames(out) <- dimnames(m); out
}

# Displacement rate from Lamb % change in use (negative = decline). Increases floored at 0.
displacement_rate <- function(pct) pmax(0, -pct / 100)

num <- function(data, nm) {
  if (!nm %in% names(data)) stop("Column '", nm, "' not found in data")
  suppressWarnings(as.numeric(data[[nm]]))
}
as_draws <- function(v, D = 1) matrix(rep(v, D), nrow = length(v), ncol = D)

# ---- 1. BUILD RAW INPUTS (swap these for samplers to add uncertainty) -----------

#' Exposure: one value (overlap_overall) now. If the data has a list column
#' `overlap_draws` (each element a numeric vector of draws for that species) it is used
#' instead, which is the hook for a future exposure distribution.
#' transform: "log10" (zeros set to half the smallest non-zero value, then log10) or "linear".
build_exposure <- function(data, transform = c("log10", "linear"), D = 1) {
  transform <- match.arg(transform)
  if ("overlap_draws" %in% names(data)) {
    D <- max(lengths(data$overlap_draws))
    m <- t(vapply(data$overlap_draws, function(v) if (length(v)) sample(v, D, replace = length(v) < D) else rep(NA_real_, D),
                  numeric(D)))
  } else {
    m <- as_draws(num(data, "overlap_overall"), D)
  }
  if (transform == "log10") {
    floor_val <- min(m[m > 0], na.rm = TRUE) / 2
    m <- log10(pmax(m, floor_val))
  }
  m
}

#' Collision raw = FA x RSZt x (1 - MA)   (Kelsey et al. 2025)
#' ma_source "kelsey": MA from the data (`ma`); "lamb": MA := Lamb displacement rate (floored at 0),
#' same formula. Species missing FA, RSZt or the chosen MA get NA.
build_collision <- function(data, ma_source = c("kelsey", "lamb"), D = 1) {
  ma_source <- match.arg(ma_source)
  ma <- if (ma_source == "kelsey") num(data, "ma") else displacement_rate(num(data, "disp_pct_mean"))
  as_draws(num(data, "fa") * num(data, "rszt") * (1 - ma), D)
}

#' Displacement raw: Lamb displacement rate, optionally x ESI (ESI replaces Kelsey's habitat specialisation).
#' tiers_allowed: Lamb match tiers to keep (A species, B congener, C family/clade); others NA.
build_displacement <- function(data, use_esi = FALSE, tiers_allowed = c("A", "B", "C"), D = 1) {
  dv <- displacement_rate(num(data, "disp_pct_mean"))
  if (use_esi) dv <- dv * num(data, "esi")
  dv[!(data$lamb_tier %in% tiers_allowed)] <- NA
  as_draws(dv, D)
}

#' Status: IUCN ordinal LC=0, NT=1, VU=2, EN=3, CR=4. DD / NE / unknown -> NA (species dropped).
build_status <- function(data, D = 1) {
  map <- c(LC = 0, NT = 1, VU = 2, EN = 3, CR = 4)
  as_draws(unname(map[as.character(data$iucn_category)]), D)
}

# ---- 1b. NON-SEABIRD inputs ----------------------------------------------------------
# Exposure and threat are built exactly as for seabirds. Only collision and displacement differ.

#' Collision (non-seabirds), one of two options (rescaled 0-1 later, in scale_inputs):
#'   "thaxter": Thaxter et al. 2017 predicted collision vulnerability (`thaxter_pred`)
#'   "pcrh"   : proportion at collision risk height x (1 - avoidance rate)   (Woodward et al. 2023)
build_collision_ns <- function(data, option = c("thaxter", "pcrh"), D = 1) {
  option <- match.arg(option)
  cv <- if (option == "thaxter") num(data, "thaxter_pred") else num(data, "pcrh") * (1 - num(data, "avoidance_rate"))
  as_draws(cv, D)
}

#' Coastal disturbance (non-seabirds), used in place of Lamb displacement:
#'   FID_s = rescale_01(log(flight initiation distance))    (optionally size-corrected, see below)
#'   D     = FID_s x (b + (1 - b) x H),   H = 1 if the species uses coastal stopover habitat, else 0
#' b (floor_b) = 0 is a pure gate: species not known to use coastal habitat get 0. b > 0 softens that.
#' size_correct = TRUE replaces log(FID) by its residual from log(FID) ~ log(body mass), because FID
#' scales with body size (r about 0.7 in the sheet).
build_displacement_ns <- function(data, size_correct = FALSE, floor_b = 0, D = 1) {
  fid <- num(data, "fid_m"); h <- num(data, "coastal_habitat")
  x <- log(fid)
  if (size_correct) {
    lm_ <- log(num(data, "mass_g")); ok <- is.finite(x) & is.finite(lm_)
    r <- rep(NA_real_, length(x)); r[ok] <- stats::resid(stats::lm(x[ok] ~ lm_[ok]))
    x <- r
  }
  as_draws(rescale_01(x) * (floor_b + (1 - floor_b) * h), D)
}

#' Build everything in one go.
build_inputs <- function(data, opts) {
  if (identical(opts$group, "nonseabird"))
    return(list(
      exposure = build_exposure(data, opts$exp_transform),
      collision = build_collision_ns(data, opts$coll_option),
      displacement = build_displacement_ns(data, isTRUE(opts$fid_size_correct), opts$fid_floor),
      status = build_status(data)))
  list(
    exposure = build_exposure(data, opts$exp_transform),
    collision = build_collision(data, opts$ma_source),
    displacement = build_displacement(data, opts$use_esi, opts$tiers),
    status = build_status(data)
  )
}

# ---- 2. RESCALE + COMBINE -------------------------------------------------------
#' Rescale raw inputs to the 0.5-2 scale.
#' CHANGED for the all-species version: each component is rescaled across EVERY species that has that
#' component (not just species that have everything). This means a data-limited species still gets rescaled
#' values for whatever it does have (shown on the "Data limited" tab), on the same scale as ranked species.
#' `keep` = species that have every input the chosen combination needs; only those get a priority and rank.
#'   collision only    -> needs exposure, status, collision
#'   displacement only -> needs exposure, status, displacement
#'   highest / sum     -> needs exposure, status, collision AND displacement
#' (the old version set non-complete species to NA before rescaling; kept below, commented out)
scale_inputs <- function(inp, combine = c("collision", "displacement", "highest", "sum")) {
  combine <- match.arg(combine)
  need_cv <- combine != "displacement"; need_dv <- combine != "collision"
  ok <- stats::complete.cases(inp$exposure, inp$status) &
        (!need_cv | stats::complete.cases(inp$collision)) &
        (!need_dv | stats::complete.cases(inp$displacement))
  # mask <- function(m) { m[!ok, ] <- NA; m }
  # cv01 <- col_apply(mask(inp$collision), rescale_01)
  # dv01 <- col_apply(mask(inp$displacement), rescale_01)
  cv01 <- col_apply(inp$collision, rescale_01)       # 0-1, NA stays NA
  dv01 <- col_apply(inp$displacement, rescale_01)
  # NA if either piece is missing for highest / sum (pmax and + do not drop NAs), so a species with only
  # one of the two is data limited under those settings but fine under "collision only" / "displacement only"
  sens_raw <- switch(combine, collision = cv01, displacement = dv01,
                     sum = cv01 + dv01, highest = pmax(cv01, dv01))
  list(
    exposure    = col_apply(inp$exposure, log_rescale),
    sensitivity = col_apply(sens_raw, log_rescale),
    status      = col_apply(inp$status, log_rescale),
    cv01 = cv01, dv01 = dv01, keep = ok
  )
}

#' For each species, which raw inputs are missing FOR THE CURRENT SETTINGS (character vector, "" = none).
#' Mirrors what build_*() and scale_inputs() require, so it explains why a species is data limited.
missing_inputs <- function(data, opts) {
  need_cv <- opts$combine != "displacement"; need_dv <- opts$combine != "collision"
  flag <- function(cond, label) ifelse(cond, label, NA_character_)
  na_ <- function(nm) is.na(num(data, nm))
  if (identical(opts$group, "nonseabird")) {
    parts <- list(flag(na_("overlap_overall"), "overlap_overall"), flag(is.na(build_status(data)[, 1]), "iucn_category"))
    if (need_cv) parts <- c(parts, if (opts$coll_option == "thaxter") list(flag(na_("thaxter_pred"), "thaxter_pred"))
                                   else list(flag(na_("pcrh"), "proportion at collision risk height"),
                                             flag(na_("avoidance_rate"), "avoidance_rate")))
    if (need_dv) parts <- c(parts, list(flag(na_("fid_m"), "flight initiation distance"),
                                        flag(na_("coastal_habitat"), "coastal_habitat")),
                            if (isTRUE(opts$fid_size_correct)) list(flag(na_("mass_g"), "mass_g")))
    m <- do.call(cbind, parts)
    return(apply(m, 1, function(r) paste(r[!is.na(r)], collapse = "; ")))
  }
  parts <- list(
    flag(na_("overlap_overall"), "overlap_overall"),
    flag(is.na(build_status(data)[, 1]), "iucn_category"))
  if (need_cv) {
    parts <- c(parts, list(flag(na_("fa"), "fa"), flag(na_("rszt"), "rszt")))
    if (opts$ma_source == "kelsey") parts <- c(parts, list(flag(na_("ma"), "ma")))
    else parts <- c(parts, list(flag(na_("disp_pct_mean"), "disp_pct_mean (Lamb, used as MA)")))
  }
  if (need_dv) {
    parts <- c(parts, list(flag(na_("disp_pct_mean"), "disp_pct_mean (Lamb)")))
    if (opts$use_esi) parts <- c(parts, list(flag(na_("esi"), "esi")))
    parts <- c(parts, list(flag(!na_("disp_pct_mean") & !(data$lamb_tier %in% opts$tiers), "Lamb tier not selected")))
  }
  m <- do.call(cbind, parts)
  apply(m, 1, function(r) paste(r[!is.na(r)], collapse = "; "))
}

#' Priority = E^w1 x S^w2 x T^w3 (each 0.5-2), per draw. Also returns weighted components.
priority_draws <- function(sc, w = c(3, 2, 1)) {
  pw <- function(x, p) ifelse(is.na(x), NA_real_, x^p)    # NA^0 is 1 in R; keep NA as NA
  out <- list(e_w = pw(sc$exposure, w[1]), s_w = pw(sc$sensitivity, w[2]), t_w = pw(sc$status, w[3]))
  out$priority <- out$e_w * out$s_w * out$t_w
  out$priority[!sc$keep, ] <- NA                           # only species with every needed input get a priority
  out
}

# ---- 3. SUMMARISE (geometric mean; quantiles only meaningful when D > 1) ----------
summarise_row <- function(m, prefix, ci = c(0.025, 0.975)) {
  D <- ncol(m)
  out <- data.frame(central = apply(m, 1, geo_mean))
  out$lwr <- if (D > 1) apply(m, 1, stats::quantile, ci[1], na.rm = TRUE) else out$central
  out$upr <- if (D > 1) apply(m, 1, stats::quantile, ci[2], na.rm = TRUE) else out$central
  names(out) <- paste0(prefix, c("", "_lwr", "_upr"))
  out
}

#' Master function: data + options -> per-species results (one row per species), ranked.
run_priority <- function(data, opts) {
  inp <- build_inputs(data, opts)
  sc  <- scale_inputs(inp, opts$combine)
  pd  <- priority_draws(sc, opts$w)
  res <- data.frame(common_name = data$common_name, scientific_name = data$scientific_name,
                    rl_category = as.character(data$iucn_category), stringsAsFactors = FALSE)
  res <- cbind(res,
    summarise_row(sc$exposure, "exposure"), summarise_row(sc$sensitivity, "sensitivity"),
    summarise_row(sc$status, "status"),
    summarise_row(pd$e_w, "e_w"), summarise_row(pd$s_w, "s_w"), summarise_row(pd$t_w, "t_w"),
    summarise_row(pd$priority, "priority"))
  # 0-1 sensitivity components contain exact zeros, so the geometric mean is undefined; show the arithmetic mean
  res$cv_scaled01 <- rowMeans(sc$cv01); res$dv_scaled01 <- rowMeans(sc$dv01)
  # raw (unscaled) values for hover text / table; arithmetic mean across draws (identical when D = 1)
  res$overlap_overall <- num(data, "overlap_overall")
  # columns that only exist for one group are NA for the other (colnum returns NA if the column is absent)
  colnum <- function(nm) if (nm %in% names(data)) num(data, nm) else rep(NA_real_, nrow(data))
  res$fa <- colnum("fa"); res$rszt <- colnum("rszt"); res$ma <- colnum("ma")
  res$thaxter <- colnum("thaxter_pred"); res$pcrh <- colnum("pcrh"); res$avoid <- colnum("avoidance_rate")
  res$fid_m <- colnum("fid_m"); res$coastal <- colnum("coastal_habitat")
  # one-line descriptions of the raw collision / displacement inputs, used in hover text
  sg <- function(x, n = 3) signif(x, n)
  if (identical(opts$group, "nonseabird")) {
    res$disp_name <- "coastal disturbance"
    res$coll_detail <- if (opts$coll_option == "thaxter")
      paste0("Thaxter predicted ", sg(res$thaxter), " (", sg(colnum("thaxter_lower")), " to ", sg(colnum("thaxter_upper")), ")")
      else paste0("proportion at risk height ", sg(res$pcrh), ", avoidance rate ", sg(res$avoid, 4))
    res$disp_detail <- paste0("flight initiation distance ", sg(res$fid_m), " m, coastal habitat used: ",
                              ifelse(is.na(res$coastal), "NA", ifelse(res$coastal == 1, "yes", "no")))
  } else {
    res$disp_name <- "displacement"
    res$coll_detail <- paste0("FA ", sg(res$fa), ", RSZt ", sg(res$rszt), ", MA ", sg(res$ma))
    res$disp_detail <- paste0("Lamb % change ", sg(colnum("disp_pct_mean")), ", tier ", as.character(data$lamb_tier))
  }
  res$cv_raw <- rowMeans(inp$collision); res$dv_raw <- rowMeans(inp$displacement)
  res$family <- as.character(data$family); res$tax_index <- num(data, "tax_index")
  # descriptive columns shown in tables and hover text: migratory status (1-3) and the seasons with a range polygon anywhere
  res$migration <- num(data, "migration")
  res$seasons_mapped_global <- as.character(data$seasons_mapped_global)
  res$included <- sc$keep
  res$missing_inputs <- missing_inputs(data, opts)   # why a species is data limited under these settings
  res$rank <- ifelse(res$included, rank(-res$priority, ties.method = "min", na.last = "keep"), NA)
  # priority draws (species x D, rows match `res` before sorting) kept for the boxplot
  rownames(pd$priority) <- data$scientific_name
  res <- res[order(res$rank, na.last = TRUE), ]
  attr(res, "priority_draws") <- pd$priority
  attr(res, "group") <- if (identical(opts$group, "nonseabird")) "nonseabird" else "seabird"
  res
}
