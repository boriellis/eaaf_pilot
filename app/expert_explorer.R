# =============================================================================
# expert_explorer.R  --  "Expert range explorer" tab for the EAAF vulnerability app
#
# For the species mapped at the workshop (SeaSketch elicitation): pick a species, pick one expert's
# drawn range (or all experts overlaid, or the consensus range), and see how the wind overlap changes.
# Up top: lowest, mean and highest overall overlap across experts, next to the BirdLife range-map value,
# so the numbers can be compared by hand with the other exposure inputs.
#
# Needs (all written by elicited_exposure.R PART 9, then copied into the app folder):
#   expert_data/expert_index.csv, expert_data/ranges/<species>.rds
# Needs packages: leaflet, sf, ggplot2   (already used by the app)
# Uses page_shell() from app.R, so it must be sourced with local = TRUE after page_shell is defined.
#
# Wiring into app.R is three small edits, listed at the bottom of this file.
# =============================================================================

# ---- Data loaded once at app start ----------------------------------------------------------------
xr_dir <- "expert_data"
xr_ok  <- file.exists(file.path(xr_dir, "expert_index.csv"))     # the tab shows a message instead of failing if missing
if (xr_ok) xr_index <- read.csv(file.path(xr_dir, "expert_index.csv"), stringsAsFactors = FALSE)

xr_season_cols <- c("resident" = "#3B6FB6", "breeding" = "#5BA36B",
                    "non-breeding" = "#E08A1E", "passage" = "#8E5EA2")
xr_overlap_col <- "#C1121F"

# tiny percentages stay readable: 0.000346 -> "0.035%", exact 0 -> "0%"; input is a FRACTION (0-1)
xr_fmt_pct <- function(p, sig = 2) {
  ifelse(is.na(p), "NA",
         ifelse(p == 0, "0%",
                ifelse(p < 1e-5, "<0.001%", paste0(formatC(100 * p, digits = sig, format = "fg"), "%"))))
}

xr_choices <- function() {
  d <- xr_index[order(xr_index$common_name), ]
  setNames(d$sci_name, paste0(d$common_name, " (", d$sci_name, ")"))
}

# one headline box
xr_box <- function(label, value, sub = NULL, col = "#1E4E5B") {
  div(style = "flex:1; min-width:150px; border:1px solid #d9d9d9; border-radius:8px; padding:10px 14px; background:#fff;",
      div(style = "font-size:12px; color:#5B6B70;", label),
      div(style = sprintf("font-size:26px; font-weight:700; color:%s;", col), value),
      if (!is.null(sub)) div(style = "font-size:12px; color:#5B6B70;", sub))
}

# hover label for wind farms: whatever descriptive columns the footprint file has
xr_wind_label <- function(d) {
  d <- sf::st_drop_geometry(d)
  d <- d[, setdiff(names(d), "hit_key"), drop = FALSE]
  if (ncol(d) == 0) return(NULL)
  do.call(paste, c(lapply(d, as.character), sep = " | "))
}

# wind-farm centre points (from the Exposure explorer's map_data) that do NOT touch the ranges being shown;
# `w_hit` = footprints that do touch them. Planar test on lon/lat (s2 off) because longitudes run 0-360.
xr_other_pts <- function(w_hit) {
  if (!exists("ee_pts", inherits = TRUE)) return(NULL)
  pts <- get("ee_pts", inherits = TRUE)
  if (is.null(w_hit) || nrow(w_hit) == 0) return(pts)
  old <- sf::sf_use_s2(FALSE); on.exit(sf::sf_use_s2(old), add = TRUE)
  hit <- lengths(sf::st_intersects(pts, w_hit)) > 0
  pts[!hit, ]
}

# ---- UI -----------------------------------------------------------------------------------------------
expert_explorer_ui <- function() {
  if (!xr_ok) {
    return(page_shell(body = div(class = "panel-box", style = "padding:20px;",
      h4("Expert range explorer is not available"),
      p("The expert_data/ folder was not found next to app.R. Run elicited_exposure.R (PART 9) and copy expert_data/ into the app folder."))))
  }
  page_shell(body = tagList(
    # hatch pattern for the BirdLife range: the map polygons reference it as fill = "url(#xr-hatch)".
    # An inline SVG with real size (not display:none) so every browser resolves the pattern.
    tags$svg(width = "0", height = "0", style = "position:absolute;",
             HTML('<defs><pattern id="xr-hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="8" stroke="#222222" stroke-width="1.6"/></pattern></defs>')),
    fluidRow(
      column(4, selectizeInput("xr_species", "Species", choices = xr_choices(), width = "100%")),
      column(4, selectInput("xr_expert", "Expert range to show", choices = c("All experts (overlay)" = "ALL"), width = "100%")),
      column(4, helpText("Each expert drew the species' range by season at the workshop. Pick one expert to see their map and ",
                         "overlap, or all of them overlaid. Experts are anonymous codes. The consensus range is the area ",
                         "that most experts drew."))),
    uiOutput("xr_summary"),
    br(),
    leaflet::leafletOutput("xr_map", height = "55vh"),
    br(),
    fluidRow(column(6, plotOutput("xr_dots", height = "280px")),
             column(6, uiOutput("xr_tbl_head"), tableOutput("xr_tbl"))),
    hr(),
    h5("What is counted"),
    helpText("Overlap is the share of an expert's range (clipped to the flyway) that falls inside an offshore wind footprint. ",
             "Where an expert drew several seasons, resident wins over everything, breeding overlapping non-breeding becomes resident, ",
             "and passage only keeps what no other season claims. The overall figure weights the seasons they drew by months ",
             "(resident 12; breeding, non-breeding, passage 4 each), the same way as the BirdLife range-map exposure. ",
             "Lowest and highest are the extremes among the individual experts; the mean is their average. ",
             "Footprints are circles sized from each project's capacity and an assumed density, so they show roughly where turbines ",
             "would be, not real layouts."),
    br()))
}

# ---- Server ----------------------------------------------------------------------------------------------
expert_explorer_server <- function(input, output, session) {
  if (!xr_ok) return(invisible(NULL))

  xr_obj <- reactive({
    req(input$xr_species)
    i <- match(input$xr_species, xr_index$sci_name)
    f <- if (is.na(i)) NA else file.path(xr_dir, xr_index$file[i])
    if (is.na(f) || !file.exists(f)) return(NULL)
    readRDS(f)
  })

  # BirdLife range polygons for the species: same files the Exposure explorer uses (map_data/ranges/<species>.rds)
  xr_bl <- reactive({
    req(input$xr_species)
    if (!exists("ee_index", inherits = TRUE)) return(NULL)
    idx <- get("ee_index", inherits = TRUE)
    i <- match(input$xr_species, idx$sci_name)
    if (is.na(i) || is.na(idx$file[i])) return(NULL)
    f <- file.path(if (exists("ee_dir", inherits = TRUE)) get("ee_dir", inherits = TRUE) else "map_data", idx$file[i])
    if (!file.exists(f)) return(NULL)
    readRDS(f)$ranges
  })

  # when the species changes: refill the expert list (labelled with each expert's overall overlap)
  observeEvent(xr_obj(), {
    obj <- xr_obj(); req(obj)
    ov  <- obj$overall
    ex  <- ov[ov$resp_code != "Consensus", ]
    ex  <- ex[order(ex$resp_code), ]
    ch  <- c("All experts (overlay)" = "ALL")
    if (any(ov$resp_code == "Consensus")) ch <- c(ch, "Consensus range" = "Consensus")
    ch  <- c(ch, setNames(ex$resp_code, sprintf("%s (overlap %s)", ex$resp_code, xr_fmt_pct(ex$overlap_overall))))
    updateSelectInput(session, "xr_expert", choices = ch, selected = "ALL")
  })

  # headline boxes
  output$xr_summary <- renderUI({
    i <- match(input$xr_species, xr_index$sci_name); req(!is.na(i))
    r <- xr_index[i, ]
    obj <- xr_obj()
    sel <- NULL
    if (!is.null(obj) && !is.null(input$xr_expert) && !input$xr_expert %in% c("ALL")) {
      o <- obj$overall[obj$overall$resp_code == input$xr_expert, ]
      if (nrow(o) == 1) sel <- xr_box(paste0("Selected: ", input$xr_expert), xr_fmt_pct(o$overlap_overall),
                                      paste0(o$seasons_present, " (", o$months_covered, " months)"), col = "#E08A1E")
    }
    tagList(
      p(strong(paste0(r$common_name, " ")), tags$em(paste0("(", r$sci_name, ")")),
        sprintf(" - %d experts mapped this species. Overall overlap, raw (%% of range overlapping wind):", r$n_respondents)),
      # plain-text headline with the actual numbers (3 significant figures), straight above the boxes and the map
      div(style = "font-size:18px; line-height:1.7; margin:6px 0 12px 0; padding:10px 14px; background:#f4f8f6; border-left:4px solid #1E4E5B;",
          HTML(sprintf(
            "<b>Experts (n = %d):</b> mean overlap <b>%s</b> of range &nbsp;(95%% CI %s; lowest %s, highest %s)<br><b>BirdLife range map:</b> <b>%s</b> of range",
            r$n_respondents, xr_fmt_pct(r$overlap_mean, 3),
            if (is.na(r$overlap_ci_lo)) "not available with fewer than 2 experts" else paste0(xr_fmt_pct(r$overlap_ci_lo, 3), " to ", xr_fmt_pct(r$overlap_ci_hi, 3)),
            xr_fmt_pct(r$overlap_lo, 3), xr_fmt_pct(r$overlap_hi, 3),
            xr_fmt_pct(r$birdlife_overlap, 3))),
          if (!is.na(r$consensus_overlap)) HTML(sprintf("<br><b>Consensus range</b> (area most experts drew): <b>%s</b> of range", xr_fmt_pct(r$consensus_overlap, 3)))),
      div(style = "display:flex; gap:12px; flex-wrap:wrap;",
          xr_box("Lowest expert", xr_fmt_pct(r$overlap_lo)),
          xr_box("Mean across experts", xr_fmt_pct(r$overlap_mean),
                 if (!is.na(r$overlap_ci_lo)) paste0("95% CI ", xr_fmt_pct(r$overlap_ci_lo), " to ", xr_fmt_pct(r$overlap_ci_hi))),
          xr_box("Highest expert", xr_fmt_pct(r$overlap_hi)),
          xr_box("BirdLife range map", xr_fmt_pct(r$birdlife_overlap), "for comparison", col = "#C1121F"),
          if (!is.na(r$consensus_overlap)) xr_box("Consensus range", xr_fmt_pct(r$consensus_overlap), "area most experts drew"),
          sel),
      if (r$n_respondents < 3)
        p(class = "text-warning", "Fewer than three experts: the lowest / highest values are not a meaningful spread yet."))
  })

  # map
  output$xr_map <- leaflet::renderLeaflet({
    obj <- xr_obj()
    m <- leaflet::leaflet(options = leaflet::leafletOptions(minZoom = 2)) |>
      leaflet::addProviderTiles(leaflet::providers$Esri.WorldGrayCanvas) |>
      leaflet::setView(lng = 130, lat = 20, zoom = 3)
    if (is.null(obj) || is.null(input$xr_expert)) return(m)

    sel <- input$xr_expert
    rng <- obj$ranges
    all_mode <- identical(sel, "ALL")
    rng <- if (all_mode) rng[rng$resp_code != "Consensus", ] else rng[rng$resp_code == sel, ]
    if (nrow(rng) == 0) return(m)
    rng <- rng[order(-rng$range_area_km2), ]
    seasons <- names(xr_season_cols)[names(xr_season_cols) %in% rng$season]
    groups  <- paste0("Range: ", seasons)

    for (k in seq_along(seasons)) {
      s <- seasons[k]
      r <- rng[rng$season == s, ]
      lab <- if (all_mode) paste0(r$resp_code, " (", s, ")") else {
        st <- obj$stats[obj$stats$resp_code == sel & obj$stats$season == s, ]
        sprintf("%s: %s of range overlaps wind (%s of %s km²)", s, xr_fmt_pct(st$pct_overlap),
                format(round(st$overlap_area_km2, 1), big.mark = ","), format(round(st$range_area_km2), big.mark = ","))
      }
      m <- leaflet::addPolygons(m, data = r, group = groups[k], label = lab, color = xr_season_cols[[s]], weight = 1,
                                fillColor = xr_season_cols[[s]], fillOpacity = if (all_mode) 0.12 else 0.45)
      # wind footprints touching this season's range, and the overlap itself
      if (!is.null(obj$wind)) {
        keys <- if (all_mode) paste0(unique(r$resp_code), ":", s) else paste0(sel, ":", s)
        hit  <- Reduce(`|`, lapply(keys, function(k) grepl(paste0("(^|;)", k, "(;|$)"), obj$wind$hit_key)))
        w_s  <- obj$wind[hit, ]
        if (nrow(w_s) > 0) m <- leaflet::addPolygons(m, data = w_s, group = groups[k], color = xr_overlap_col, weight = 1.5,
                                                     fill = FALSE, label = xr_wind_label(w_s))
      }
      if (!is.null(obj$overlap)) {
        o <- obj$overlap[obj$overlap$season == s & (if (all_mode) obj$overlap$resp_code != "Consensus" else obj$overlap$resp_code == sel), ]
        if (nrow(o) > 0) m <- leaflet::addPolygons(m, data = o, group = groups[k], color = xr_overlap_col, weight = 1,
                                                   fillColor = xr_overlap_col, fillOpacity = if (all_mode) 0.35 else 0.9,
                                                   label = paste0(s, ": overlap with wind"))
      }
    }

    # BirdLife range, hatched (no solid fill), as its own switchable layer so it can be compared with the expert ranges
    bl <- xr_bl()
    if (!is.null(bl) && nrow(bl) > 0) {
      m <- leaflet::addPolygons(m, data = bl, group = "BirdLife range (hatched)", color = "#222222", weight = 1,
                                fillColor = "url(#xr-hatch)", fillOpacity = 1,
                                label = paste0("BirdLife range: ", bl$season),
                                options = leaflet::pathOptions(interactive = FALSE))
      groups <- c(groups, "BirdLife range (hatched)")
    }

    # grey points for the wind farms that do NOT touch the ranges shown (same idea as the Exposure explorer)
    if (exists("ee_pts", inherits = TRUE)) {
      shown <- if (is.null(obj$wind)) NULL else
        obj$wind[grepl(if (all_mode) "(^|;)R[0-9]+:" else paste0("(^|;)", sel, ":"), obj$wind$hit_key), ]
      p_other <- xr_other_pts(shown)
      if (!is.null(p_other) && nrow(p_other) > 0) {
        lab_fun <- if (exists("ee_wind_label", inherits = TRUE)) get("ee_wind_label", inherits = TRUE) else xr_wind_label
        m <- leaflet::addCircleMarkers(m, data = p_other, group = "Other wind farms (points)", radius = 3, color = "grey35",
                                       weight = 1, fillOpacity = 0.7, label = lab_fun(p_other))
        groups <- c(groups, "Other wind farms (points)")
      }
    }

    bb <- sf::st_bbox(rng)
    if (!is.null(bl) && nrow(bl) > 0) {              # frame the experts AND the BirdLife range
      b2 <- sf::st_bbox(bl)
      bb <- c(xmin = min(bb[["xmin"]], b2[["xmin"]]), xmax = max(bb[["xmax"]], b2[["xmax"]]),
              ymin = min(bb[["ymin"]], b2[["ymin"]]), ymax = max(bb[["ymax"]], b2[["ymax"]]))
    }
    cx <- mean(c(bb[["xmin"]], bb[["xmax"]])); cy <- mean(c(bb[["ymin"]], bb[["ymax"]]))
    hx <- max(bb[["xmax"]] - bb[["xmin"]], 2) * 0.6; hy <- max(bb[["ymax"]] - bb[["ymin"]], 2) * 0.6
    m <- leaflet::fitBounds(m, cx - hx, cy - hy, cx + hx, cy + hy, options = list(maxZoom = 8))
    m |>
      leaflet::addLayersControl(overlayGroups = groups, options = leaflet::layersControlOptions(collapsed = FALSE)) |>
      leaflet::addLegend("bottomright", title = if (all_mode) "All experts, by season" else paste0("Expert ", sel),
                         colors = c(xr_season_cols[seasons], xr_overlap_col),
                         labels = c(seasons, "range overlapping wind"), opacity = 0.8)
  })

  # one dot per expert: where does this expert sit among the others?
  output$xr_dots <- renderPlot({
    obj <- xr_obj(); req(obj)
    i  <- match(input$xr_species, xr_index$sci_name); r <- xr_index[i, ]
    ex <- obj$overall[obj$overall$resp_code != "Consensus", ]
    ex$sel <- ex$resp_code == input$xr_expert
    p <- ggplot2::ggplot(ex, ggplot2::aes(x = 100 * overlap_overall, y = reorder(resp_code, overlap_overall))) +
      ggplot2::geom_vline(xintercept = 100 * r$overlap_mean, colour = "#1E4E5B") +
      ggplot2::geom_vline(xintercept = 100 * c(r$overlap_lo, r$overlap_hi), colour = "#1E4E5B", linetype = "dashed") +
      ggplot2::geom_point(ggplot2::aes(colour = sel, size = sel)) +
      ggplot2::scale_colour_manual(values = c("FALSE" = "grey40", "TRUE" = "#E08A1E"), guide = "none") +
      ggplot2::scale_size_manual(values = c("FALSE" = 2.5, "TRUE" = 5), guide = "none") +
      { if (!is.na(r$birdlife_overlap)) ggplot2::geom_vline(xintercept = 100 * r$birdlife_overlap, colour = "#C1121F", linewidth = 1) } +
      ggplot2::labs(x = "Overall wind overlap (% of range)", y = NULL,
                    subtitle = "dots = experts; solid = mean; dashed = lowest / highest; red = BirdLife") +
      ggplot2::theme_minimal(base_size = 12)
    p
  })

  output$xr_tbl_head <- renderUI({
    if (identical(input$xr_expert, "ALL")) h5("Overall overlap by expert") else h5(paste("Overlap by season:", input$xr_expert))
  })

  output$xr_tbl <- renderTable({
    obj <- xr_obj(); req(obj, input$xr_expert)
    if (identical(input$xr_expert, "ALL")) {
      o <- obj$overall[obj$overall$resp_code != "Consensus", ]
      o <- o[order(o$overlap_overall), ]
      data.frame(Expert = o$resp_code, `Seasons drawn` = o$seasons_present, Months = as.integer(o$months_covered),
                 `Overall overlap (%)` = xr_fmt_pct(o$overlap_overall), check.names = FALSE)
    } else {
      s <- obj$stats[obj$stats$resp_code == input$xr_expert, ]
      s <- s[order(match(s$season, names(xr_season_cols))), ]
      data.frame(Season = s$season, Months = as.integer(s$months),
                 `Range in flyway (km2)` = round(s$range_area_km2),
                 `Overlap with wind (km2)` = round(s$overlap_area_km2, 2),
                 `Overlap (%)` = xr_fmt_pct(s$pct_overlap), check.names = FALSE)
    }
  }, striped = TRUE, width = "100%")
}

# =============================================================================
# Wiring into app.R (3 edits):
#
# 1. next to the other source() calls (after page_shell is defined; local = TRUE so it can see page_shell):
#      source("expert_explorer.R", local = TRUE)
#
# 2. in ui <- navbarPage(...), right after the "Exposure explorer" tabPanel:
#      tabPanel("Expert range explorer", expert_explorer_ui()),
#
# 3. in the server, next to exposure_explorer_server(input, output, session):
#      expert_explorer_server(input, output, session)
# =============================================================================
