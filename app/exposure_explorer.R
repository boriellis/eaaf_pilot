# =============================================================================
# exposure_explorer.R  --  "Exposure explorer" tab for the EAAF vulnerability app
#
# Pick a species -> zoomable map of its seasonal ranges (clipped to the flyway), the offshore
# wind footprints that touch it, and the range ∩ wind overlap, plus the numbers behind the
# Overlap column in the ranked table.
#
# Needs (all produced by build_map_data.R, copied into the app folder):
#   map_data/species_index.csv, map_data/wind_footprints.rds, map_data/wind_points.rds,
#   map_data/ranges/<species>.rds
# Needs packages: leaflet, sf   (install.packages(c("leaflet", "sf")))
#
# Wiring into app.R is four small edits, listed at the bottom of this file.
# =============================================================================

# ---- Data loaded once at app start -------------------------------------------------------------
ee_dir <- "map_data"
ee_ok  <- file.exists(file.path(ee_dir, "species_index.csv"))     # the tab shows a message instead of failing if missing

if (ee_ok) {
  ee_index <- read.csv(file.path(ee_dir, "species_index.csv"), stringsAsFactors = FALSE)
  ee_wind  <- readRDS(file.path(ee_dir, "wind_footprints.rds"))   # sf polygons, with fid
  ee_pts   <- readRDS(file.path(ee_dir, "wind_points.rds"))       # sf points (centroids), with fid
}

# season colours: same as the figures in exposure_scratch.R
ee_season_cols <- c("resident" = "#3B6FB6", "breeding" = "#5BA36B",
                    "non-breeding" = "#E08A1E", "passage" = "#8E5EA2")
ee_overlap_col <- "#C1121F"
ee_ring_max_zoom <- 7   # the centre rings on touching wind farms are shown at this zoom level and below only

# species dropdown: grouped by seabird / non-seabird, labelled "Common name (Scientific name)",
# species with no range map are still listed (so people can see they are missing) but flagged
ee_choices <- function() {
  sb <- read.csv("seabird_all_species_v2.csv",   stringsAsFactors = FALSE)[, c("common_name", "scientific_name")]
  ns <- read.csv("nonseabird_data_v2.csv",       stringsAsFactors = FALSE)[, c("common_name", "scientific_name")]
  mk <- function(d) {
    d <- d[order(d$common_name), ]
    has <- if (ee_ok) ee_index$has_map[match(d$scientific_name, ee_index$sci_name)] else FALSE
    has[is.na(has)] <- FALSE
    setNames(d$scientific_name, paste0(d$common_name, " (", d$scientific_name, ")", ifelse(has, "", " - no range map")))
  }
  list("Seabirds" = mk(sb), "Non-seabird migrants" = mk(ns))
}

# tiny percentages stay readable: 0.000346 -> "0.035%", exact 0 -> "0%"
ee_fmt_pct <- function(p, sig = 2) {
  ifelse(is.na(p), "NA",
         ifelse(p == 0, "0%",
                ifelse(p < 1e-5, "<0.001%", paste0(formatC(100 * p, digits = sig, format = "fg"), "%"))))
}

# hover label for wind farms: whichever of these columns exist
ee_wind_label <- function(d) {
  d <- sf::st_drop_geometry(d)
  parts <- list(d$project_name, d$country_area,
                if (!is.null(d$capacity_mw)) paste0(d$capacity_mw, " MW"),
                d$installation_type, d$status)
  parts <- Filter(Negate(is.null), parts)
  do.call(paste, c(parts, sep = " | "))
}

# ---- UI ------------------------------------------------------------------------------------------------
exposure_explorer_ui <- function() {
  if (!ee_ok) {
    return(page_shell(body = div(class = "panel-box", style = "padding:20px;",
      h4("Exposure explorer is not available"),
      p("The map data folder (map_data/) was not found next to app.R. Run build_map_data.R and copy map_data/ into the app folder."))))
  }
  # was: page_side(menu = ...) with the species box and notes in a left sidebar (exposure_explorer_v1.R).
  # Now a plain full-width page like the comparison pages: nothing from the Tool tab's sidebar can show through.
  page_shell(body = tagList(
    # rings are tagged with the class ee-ring; the map gets .ee-zoomed-in when zoomed in past ee_ring_max_zoom (see onRender below)
    tags$style(HTML(".ee-zoomed-in .ee-ring { display: none; }")),
    fluidRow(
      column(5, selectizeInput("ee_species", "Species", choices = ee_choices(), width = "100%",
                               selected = "Thalasseus bernsteini",   # falls back to the first species if not in the list
                               options = list(placeholder = "Type a name..."))),
      column(7, helpText("Ranges are clipped to the flyway and coloured by season. Use the layer box on the map to switch seasons on and off ",
                         "(the wind farms and overlap for a season switch with it); scroll or drag to zoom and pan. ",
                         "Red rings mark wind farms touching the range when zoomed out."))),
    leaflet::leafletOutput("ee_map", height = "60vh"),
    br(),
    uiOutput("ee_info"),
    tableOutput("ee_tbl"),
    hr(),
    h5("What is counted"),
    helpText("Resident, breeding, non-breeding and passage ranges (extant or possibly extant). ",
             "Ranges with uncertain seasonality, and extinct ranges, are not counted. ",
             "Overlap is the share of each seasonal range that falls inside an offshore wind footprint; the overall figure weights seasons ",
             "by months (resident 12; breeding, non-breeding, passage 4 each). ",
             "Footprints are circles sized from each project's capacity and an assumed density, so they show roughly where the turbines ",
             "would be, not real layouts."),
    br()))
}

# ---- Server ---------------------------------------------------------------------------------------------
exposure_explorer_server <- function(input, output, session) {
  if (!ee_ok) return(invisible(NULL))

  # the saved object for the selected species (NULL if it has no map)
  ee_obj <- reactive({
    req(input$ee_species)
    i <- match(input$ee_species, ee_index$sci_name)
    if (is.na(i) || is.na(ee_index$file[i])) return(NULL)
    f <- file.path(ee_dir, ee_index$file[i])
    if (!file.exists(f)) return(NULL)
    readRDS(f)
  })

  base_map <- function() {
    leaflet::leaflet(options = leaflet::leafletOptions(minZoom = 2)) |>
      leaflet::addProviderTiles(leaflet::providers$Esri.WorldGrayCanvas) |>
      leaflet::setView(lng = 120, lat = 15, zoom = 3)
  }

  output$ee_map <- leaflet::renderLeaflet({
    obj <- ee_obj()
    m <- base_map()
    if (is.null(obj)) return(m)

    rng <- obj$ranges
    rng <- rng[order(-rng$range_area_km2), ]            # big ranges underneath, small ones on top
    seasons <- names(ee_season_cols)[names(ee_season_cols) %in% rng$season]
    st <- obj$stats

    # One layer group per season, holding that season's range, the wind farms touching it, their centre rings
    # and the overlap polygons, so switching a season off removes all of it. Drawn in two passes so every
    # season's farms and overlap sit on top of every range.
    range_groups <- paste0("Range: ", seasons)
    for (k in seq_along(seasons)) {
      s  <- seasons[k]
      r  <- rng[rng$season == s, ]
      sr <- st[st$season == s, ]
      lab <- sprintf("%s: %s of range overlaps wind (%s km\u00b2 of %s km\u00b2)", s,
                     ee_fmt_pct(sr$pct_overlap_season), format(round(sr$overlap_area_km2, 1), big.mark = ","),
                     format(round(sr$range_area_km2), big.mark = ","))
      m <- leaflet::addPolygons(m, data = r, group = range_groups[k], label = lab,
                                color = ee_season_cols[[s]], weight = 1, fillColor = ee_season_cols[[s]], fillOpacity = 0.45)
    }

    # farms touching ANY season (these are removed from the grey "other" dots)
    hits    <- unique(unlist(obj$hit))
    p_other <- ee_pts[!ee_pts$fid %in% hits, ]
    if (nrow(p_other) > 0) {
      m <- leaflet::addCircleMarkers(m, data = p_other, group = "Other wind farms (points)", radius = 3, color = "grey35",
                                     weight = 1, fillOpacity = 0.7, label = ee_wind_label(p_other))
    }

    for (k in seq_along(seasons)) {
      s   <- seasons[k]
      ids <- obj$hit[[s]]
      w_s <- ee_wind[ee_wind$fid %in% ids, ]
      p_s <- ee_pts[ee_pts$fid %in% ids, ]
      if (nrow(w_s) > 0) {
        m <- m |>
          leaflet::addPolygons(data = w_s, group = range_groups[k], color = ee_overlap_col, weight = 1.5, fill = FALSE) |>
          # ring on each footprint centre so it stays findable when zoomed out (hidden by CSS when zoomed in)
          leaflet::addCircleMarkers(data = p_s, group = range_groups[k], radius = 7, color = ee_overlap_col, weight = 2,
                                    fill = FALSE, label = ee_wind_label(p_s),
                                    options = leaflet::pathOptions(className = "ee-ring"))
      }
      ov_s <- if (!is.null(obj$overlap)) obj$overlap[obj$overlap$season == s, ] else NULL
      if (!is.null(ov_s) && nrow(ov_s) > 0) {
        m <- leaflet::addPolygons(m, data = ov_s, group = range_groups[k], color = ee_overlap_col, weight = 1,
                                  fillColor = ee_overlap_col, fillOpacity = 0.9, label = paste0(s, ": overlap with wind"))
      }
    }

    # zoom to the range; pad tiny ranges so the basemap is not zoomed to the max
    bb  <- sf::st_bbox(rng)
    cx  <- mean(c(bb[["xmin"]], bb[["xmax"]])); cy <- mean(c(bb[["ymin"]], bb[["ymax"]]))
    hx  <- max(bb[["xmax"]] - bb[["xmin"]], 2) * 0.6; hy <- max(bb[["ymax"]] - bb[["ymin"]], 2) * 0.6
    m <- leaflet::fitBounds(m, cx - hx, cy - hy, cx + hx, cy + hy, options = list(maxZoom = 8))

    groups <- c(range_groups, if (nrow(p_other) > 0) "Other wind farms (points)")
    m <- m |>
      leaflet::addLayersControl(overlayGroups = groups, options = leaflet::layersControlOptions(collapsed = FALSE)) |>
      leaflet::addLegend("bottomright", title = "Seasonal range",
                         colors = c(ee_season_cols[seasons], ee_overlap_col),
                         labels = c(seasons, "range overlapping wind"), opacity = 0.8)

    # toggle a class on the map when zoomed in past ee_ring_max_zoom; CSS then hides the centre rings
    htmlwidgets::onRender(m, sprintf(
      "function(el, x) { var map = this; function f() { el.classList.toggle('ee-zoomed-in', map.getZoom() > %d); } map.on('zoomend', f); f(); }",
      ee_ring_max_zoom))
  })

  # headline numbers + notes under the map
  output$ee_info <- renderUI({
    i <- match(input$ee_species, ee_index$sci_name)
    if (is.na(i)) return(NULL)
    r <- ee_index[i, ]
    ttl <- h4(tags$em(r$sci_name))
    if (!isTRUE(r$has_map)) {
      return(tagList(ttl, div(class = "alert alert-warning",
        "No range map for this species inside the flyway. ",
        if (!is.na(r$note) && nzchar(r$note)) r$note else "It may be missing from the range file under this name.")))
    }
    tagList(ttl,
      p(strong("Overall overlap: "), ee_fmt_pct(r$overlap_overall_pct / 100),
        " (months-weighted across the seasons below). Seasons mapped inside the flyway: ", r$seasons_present, "."),
      if (!is.na(r$months_covered) && r$months_covered < 12)
        p(class = "text-warning", sprintf("Only %d of 12 months of the annual cycle are mapped for this species; the overall figure is normalised over those months.", r$months_covered)))
  })

  output$ee_tbl <- renderTable({
    obj <- ee_obj(); req(obj)
    s <- obj$stats
    data.frame(Season = s$season, Months = s$months,
               `Range in flyway (km2)` = round(s$range_area_km2),
               `Overlap with wind (km2)` = round(s$overlap_area_km2, 2),
               `Overlap (%)` = ee_fmt_pct(s$pct_overlap_season),
               `Wind farms touching` = s$n_wind_touching,
               check.names = FALSE)
  }, striped = TRUE, width = "100%")
}

# =============================================================================
# Wiring into app.R (4 edits):
#
# 1. near the other library() calls:
#      library(leaflet); library(sf)
#
# 2. after source("core_functions.R"); source("plot_functions.R") AND after page_shell / page_side are
#    defined (they are used inside the UI function, so just before `ui <- navbarPage(` is safest):
#      source("exposure_explorer.R", local = TRUE)   # local = TRUE so it can see page_shell / page_side
#
# 3. in ui <- navbarPage(...), e.g. right after the "Tool" tabPanel:
#      tabPanel("Exposure explorer", exposure_explorer_ui()),
#
# 4. first line inside server <- function(input, output, session) {
#      exposure_explorer_server(input, output, session)
# =============================================================================
