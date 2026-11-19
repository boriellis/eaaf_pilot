# =============================================================================
# EAAF bird vulnerability prototype (point estimates): seabirds OR non-seabird migrants
# Run from the folder containing: app.R, core_functions.R, plot_functions.R,
#   seabird_all_species_v2.csv, nonseabird_data_v2.csv
# Optional (for the Definitions page): seabird_all_species_v2_dictionary.csv, nonseabird_data_v2_dictionary.csv
# NOT YET RUN: written without R available; expect to fix small typos on first launch.
# Packages: shiny, shinythemes, DT, dplyr, tidyr, ggplot2, scico, scales, plotly, ggrepel
#
# Layout: navbar across the top (Tool / Instructions / Definitions / two scenario-comparison pages).
# Tool page: menu in a fixed left sidebar, results in a scrolling panel beside it.
# Comparison pages: controls across the top of the scrolling page; hide them or pin them with the buttons above them.
# =============================================================================
library(shiny); library(DT); library(dplyr); library(leaflet); library(sf)
library(shinythemes)   # for the sandstone theme (install.packages("shinythemes"))
source("core_functions.R"); source("plot_functions.R"); source("exposure_explorer.R", local = TRUE); source("expert_explorer.R", local = TRUE); source("country_filter.R", local = TRUE)

# (methods_url and the link to the GitHub notes were removed: the Instructions and Definitions pages cover it now)

# dat <- read.csv("seabird_test_data_v1.csv", stringsAsFactors = FALSE)   # old 34-species complete-case test set
# All seabird-tab species; missing values are "NA" and read in as NA. Which species can be scored depends
# on the sensitivity setting; the rest go to the "Data limited" tab.
dat_sb <- read.csv("seabird_all_species_v2.csv", stringsAsFactors = FALSE)
# Non-seabird migrants (55 species). Seabirds and non-seabirds are never ranked together.
# dat_ns <- read.csv("nonseabird_data_v1.csv", stringsAsFactors = FALSE)   # v1: coastal habitat from the hand lit review only
dat_ns <- read.csv("nonseabird_data_v2.csv", stringsAsFactors = FALSE)   # v2: coastal habitat and rank from BirdBase
# Data dictionaries for the Definitions page (skipped quietly if the files are not deployed with the app)
read_dict <- function(f) if (file.exists(f)) read.csv(f, stringsAsFactors = FALSE)[, c("column", "group", "description")] else NULL
dict_sb <- read_dict("seabird_all_species_v2_dictionary.csv")
dict_ns <- read_dict("nonseabird_data_v2_dictionary.csv")

# ---- Option widgets, written once and reused by the Tool page and the scenario pages ------------------
# `p` is an id prefix: "" on the Tool page, "sa_" / "sb_" / "na_" / "nb_" on the scenario pages, so the same
# option can exist several times with different ids (input$w_e, input$sa_w_e, ...).
# A one-to-two sentence explanation under an option. Shown on the Tool page (help = TRUE), left out of the scenario pages.
hlp <- function(show, text) if (isTRUE(show)) helpText(text)

# stacked = TRUE: one slider under another (left sidebar); FALSE: three across (scenario menus)
weight_sliders <- function(p, stacked = FALSE, help = FALSE) if (stacked) tagList(
  hlp(help, "Each component is rescaled to 0.5-2 and raised to its exponent before the three are multiplied. 0 switches a component off."),
  sliderInput(paste0(p, "w_e"), "Exposure", min = 0, max = 3, value = 3, step = 1, width = "100%"),
  hlp(help, "How strongly overlap between the species' range and the flyway drives the ranking. "),
  sliderInput(paste0(p, "w_s"), "Sensitivity", min = 0, max = 3, value = 2, step = 1, width = "100%"),
  hlp(help, "How strongly the species' collision and displacement (or coastal disturbance) sensitivity drives the ranking."),
  sliderInput(paste0(p, "w_t"), "Threat (IUCN)", min = 0, max = 3, value = 1, step = 1, width = "100%"),
  hlp(help, "How strongly IUCN Red List status drives the ranking. ")) else fluidRow(
  column(4, sliderInput(paste0(p, "w_e"), "Exposure exponent", min = 0, max = 3, value = 3, step = 1, width = "100%")),
  column(4, sliderInput(paste0(p, "w_s"), "Sensitivity exponent", min = 0, max = 3, value = 2, step = 1, width = "100%")),
  column(4, sliderInput(paste0(p, "w_t"), "Threat exponent", min = 0, max = 3, value = 1, step = 1, width = "100%")))

combine_radio <- function(p, nonseabird = FALSE, help = FALSE) tagList(
  radioButtons(paste0(p, "combine"), "Combine collision and displacement",
    choices = setNames(c("collision", "displacement", "highest", "sum"),
                       c("Collision only",
                         # nonseabird: TRUE = non-seabird page, FALSE = seabird page, NA = Tool page (one shared radio, neutral wording)
                         if (isTRUE(nonseabird)) "Coastal disturbance only" else if (is.na(nonseabird)) "Displacement / disturbance only" else "Displacement only",
                         "Higher of the two", "Sum of the two")),
    selected = "highest"),
  hlp(help, "Each component is first rescaled 0-1. 'Higher of the two' keeps whichever is larger for each species and 'sum' adds them; the result is then rescaled 0.5-2. Choosing one component only lets in species that have just that input."))

exp_radio <- function(p, help = FALSE) tagList(
  radioButtons(paste0(p, "exp_transform"), "Exposure transform before rescaling",
    choices = c("log10 (zeros set to half the smallest non-zero value)" = "log10", "Linear" = "linear")),
  hlp(help, "Overlap values span orders of magnitude. Log10 stops a few high-overlap species dominating the scale; linear keeps the raw proportions, so the highest-overlap species stand far above the rest."))

seabird_options <- function(p, help = FALSE) tagList(
  radioButtons(paste0(p, "ma_source"), "Collision: avoidance rate (MA) from",
    choices = c("Kelsey et al. 2025 (as published)" = "kelsey", "Lamb et al. 2024 displacement rate" = "lamb")),
  hlp(help, "Collision risk is flight activity x time in the rotor-swept zone x (1 - avoidance). The avoidance term is either the published Kelsey macro-avoidance rate or the Lamb displacement rate, which changes which species can be scored and their collision values."),
  checkboxInput(paste0(p, "use_esi"), "Displacement: multiply Lamb rate by ESI", value = FALSE),
  hlp(help, "Multiplies each species' Lamb displacement rate by its Ecological Specialization Index (BirdBase), so dietary and habitat specialists score higher displacement sensitivity."),
  checkboxGroupInput(paste0(p, "tiers"), "Lamb match tiers to use",
    choices = c("A: species" = "A", "B: congener" = "B", "C: family / clade" = "C"), selected = c("A", "B", "C")),
  hlp(help, "Lamb rates are matched to species at three levels: A is the species itself, B a congener, C a family or clade relative. Unticking tiers keeps only closer matches, and species left with no match become data limited."))

nonseabird_options <- function(p, help = FALSE) tagList(
  radioButtons(paste0(p, "coll_option"), "Collision measure (rescaled 0-1)",
    choices = c("Thaxter et al. 2017 predicted collision vulnerability" = "thaxter",
                "Proportion at collision risk height x (1 - avoidance rate)" = "pcrh")),
  hlp(help, "Thaxter is a predicted collision rate built from onshore carcass counts, with wide uncertainty. The second option multiplies the share of flight at rotor height (Woodward et al. 2023) by one minus a group-level avoidance rate, and 9 species have no value."),
  radioButtons(paste0(p, "coastal_weight"), "Coastal habitat weighting",
    choices = c("Rank-weighted (BirdBase preference rank)" = "rank", "Binary (uses coastal habitat or not)" = "binary")),
  hlp(help, "Rank-weighted scales coastal disturbance by how highly a species ranks coastal habitat among the habitats it uses, as (n - rank + 1) / n, so a first choice scores 1. Binary only asks whether coastal habitat is used at all."),
  checkboxInput(paste0(p, "fid_size_correct"), "Coastal disturbance: correct flight initiation distance for body mass", value = FALSE),
  hlp(help, "Flight initiation distance rises with body size. Ticking this uses how wary a species is for its size (the residual from a regression on body mass) instead of the raw distance."),
  sliderInput(paste0(p, "fid_floor"), "Coastal disturbance: floor for species not known to use coastal habitat (0 = pure gate)",
              min = 0, max = 0.5, value = 0, step = 0.05, width = "100%"),
  hlp(help, "Gives species that do not use coastal habitat a minimum share of their disturbance score instead of zero. At 0 coastal habitat acts as a strict gate; higher values soften it."))

# One scenario's menu on a comparison page (compact: sliders in a row, options in two columns beneath)
scenario_menu <- function(p, group, title, extra = NULL) {
  ns <- identical(group, "nonseabird")
  div(h4(title, extra, style = "margin-top:0;"),
      weight_sliders(p),
      fluidRow(column(6, combine_radio(p, ns), exp_radio(p)),
               column(6, if (ns) nonseabird_options(p) else seabird_options(p))))
}

# Build the run_priority() options list from whichever set of inputs we are reading.
# `get` is a function: get("w_e") returns that scenario's input value.
build_opts <- function(group, get) {
  opts <- list(group = group, w = c(get("w_e"), get("w_s"), get("w_t")), combine = get("combine"),
               exp_transform = get("exp_transform"))
  if (identical(group, "nonseabird")) {
    opts$coll_option <- get("coll_option"); opts$fid_size_correct <- get("fid_size_correct")
    opts$fid_floor <- get("fid_floor"); opts$coastal_weight <- get("coastal_weight")
  } else {
    req(length(get("tiers")) > 0)   # at least one Lamb tier must be ticked
    opts$ma_source <- get("ma_source"); opts$use_esi <- get("use_esi"); opts$tiers <- get("tiers")
  }
  opts
}

# Page skeleton: a fixed region under the navbar with an optional menu bar on top and a scrolling body below.
page_shell <- function(menu = NULL, body) div(class = "fixed-page",
  if (!is.null(menu)) div(class = "menu-bar", menu), div(class = "body-panel", body))

# Page with the menu in a fixed left sidebar (its own scroll) and the results in a scrolling panel to its right
page_side <- function(menu, body) div(class = "fixed-page side",
  div(class = "menu-side", menu), div(class = "body-panel", body))

# One output panel on a comparison page: a heading, then Scenario A | Scenario B side by side, each in a scrollable box.
compare_row <- function(title, id_a, id_b, height, ui_fun) tagList(
  h3(title),
  fluidRow(column(6, div(class = "panel-box", style = paste0("height:", height, "px;"), h5("Scenario A"), ui_fun(id_a))),
           column(6, div(class = "panel-box", style = paste0("height:", height, "px;"), h5("Scenario B"), ui_fun(id_b)))))

# The controls sit at the top of the scrolling page, so they scroll away with it by default. "Show / hide controls" collapses
# them; "Pin controls to top" keeps them stuck to the top while you scroll (capped at 45% of the screen height).
compare_page <- function(group, a, b, label) page_shell(
  body = tagList(
    div(class = "ctl-wrap",
      div(class = "ctl-head",
        tags$button(type = "button", class = "btn btn-default btn-sm", `data-toggle` = "collapse",
                    `data-target` = paste0("#ctl_", a), "Show / hide controls"),
        tags$label(class = "pin-label",
          tags$input(type = "checkbox", onchange = "this.closest('.ctl-wrap').classList.toggle('pinned', this.checked)"),
          " Pin controls to top")),
      div(id = paste0("ctl_", a), class = "collapse in ctl-body",
        fluidRow(column(6, scenario_menu(paste0(a, "_"), group, "Scenario A")),
                 column(6, scenario_menu(paste0(b, "_"), group, "Scenario B",
                   extra = actionButton(paste0("copy_", a, "_", b), "Copy A to B", class = "btn-default btn-sm",
                                        style = "margin-left:14px;")))))),
    p(class = "text-muted", sprintf("Change the inputs for either scenario above (hide or pin them with the buttons) and compare the %s results below. Top 10, scatterplot and family plot each sit in their own scrollable panel.", label)),
    compare_row("Top 10 priority species", paste0("top_", a), paste0("top_", b), 450,
                function(id) DTOutput(id)),
    compare_row("Vulnerability scatterplot", paste0("scatter_", a), paste0("scatter_", b), 660,
                function(id) plotly::plotlyOutput(id, height = "600px")),
    compare_row("Priority by family", paste0("fam_", a), paste0("fam_", b), 600,
                # was: plotOutput(id, height = "520px") (static); now interactive so hovering a point shows the species and its metrics
                function(id) plotly::plotlyOutput(id, height = "520px"))))

# ---- Text for the Instructions and Definitions pages ----------------------------------------------------
output_defs <- data.frame(
  Column = c("Rank", "Priority", "Species / Scientific name", "IUCN",
             "Migratory status (1-3)", "Seasons mapped (global)",
             "Overlap (raw, %)", "Exposure", "Sensitivity", "Threat",
             "Weighted exposure / sensitivity / threat",
             "Missing for these settings (Data limited tab)",
             "Collision (raw) / Displacement (raw)", "Collision (0-1) / Displacement (0-1)",
             "Coastal habitat used / Coastal rank / Habitats used / Coastal weight (non-seabirds)"),
  Meaning = c(
    "1 = highest priority within the chosen group, among species that have every input the current settings need.",
    "Weighted exposure x weighted sensitivity x weighted threat. Only comparable within a group (seabirds or non-seabird migrants).",
    "Names from the data sheet.",
    "IUCN Red List category (CR, EN, VU, NT, LC, DD). Data Deficient species have no threat score and appear on the Data limited tab.",
    "Migratory status score, 1-3, from the data sheet.",
    "Seasons for which a range polygon exists for the species anywhere in the world (not clipped to the flyway). A rough guide to how complete the range map is, not a measure of uncertainty.",
    "Raw overlap of the species' range with the wind areas, as a percentage of its range (the data column overlap_overall x 100), before any transform or rescaling.",
    "Overlap, transformed (log10 or linear, per the menu) and rescaled to 0.5-2 across all species in the group that have an overlap value.",
    "Collision and displacement (or coastal disturbance), each rescaled 0-1, combined as the menu says, then rescaled to 0.5-2 across the group.",
    "IUCN category scored LC = 0, NT = 1, VU = 2, EN = 3, CR = 4, then rescaled to 0.5-2 across the group.",
    "Each scaled value raised to its exponent (the sliders). Priority is the product of the three.",
    "Which inputs are missing for the species under the current settings. The list changes as the settings change.",
    "Collision: seabirds use flight activity x time in the rotor-swept zone x (1 - macro-avoidance); non-seabirds use the Thaxter prediction or risk-height proportion x (1 - avoidance rate). Displacement: Lamb displacement rate (seabirds) or the coastal disturbance score (non-seabirds). Raw = before rescaling.",
    "The same two components after rescaling to 0-1 across the group, before they are combined into sensitivity.",
    "From BirdBase: whether the species uses sea-coast habitat, where coastal habitat falls in its ranked list of habitats (1 = most preferred), how many habitats it uses, and the weight (n - rank + 1) / n used for coastal disturbance (0 if coastal habitat is not used)."),
  stringsAsFactors = FALSE)

instructions_ui <- div(style = "max-width:900px;",
  h2("How to use this tool"),
  p("This prototype ranks species for offshore wind vulnerability across the East Asian-Australasian Flyway. Priority = Exposure^w1 x Sensitivity^w2 x Threat^w3, where each component is first rescaled to 0.5-2 and the exponents (w1, w2, w3) are set by the sliders. It is a flexible prototype for discussion; every setting is meant to be changed."),
  h3("Tool page"),
  tags$ol(
    tags$li("Choose a species group. Seabirds and non-seabird migrants are scored and ranked separately, never together."),
    tags$li("Set the exponents. Defaults are exposure 3, sensitivity 2, threat 1. A value of 0 switches a component off."),
    tags$li("Choose how collision and displacement are combined: collision only, displacement only (coastal disturbance only for non-seabirds), the higher of the two, or their sum."),
    tags$li("Choose the group-specific options: for seabirds, where the avoidance rate comes from, whether to multiply the displacement rate by ESI, and which Lamb match tiers to allow; for non-seabirds, the collision measure, how coastal habitat is weighted (by BirdBase preference rank or simply used / not used), the body-size correction and the coastal habitat floor. Each option has a short explanation under it."),
    tags$li("Choose the exposure transform (log10 or linear) before rescaling."),
    tags$li("Read the results in the tabs to the right of the menu: ranked table, Data limited, vulnerability scatter, and priority by family. The menu stays on the left while the results scroll.")),
  h3("Data limited tab"),
  p("A species needs every input that the current settings use. Species missing one are listed on the Data limited tab with their raw and rescaled values and NA for what is missing. The list changes with the settings: collision only needs fewer inputs than displacement or a sum, for example."),
  h3("Comparing scenarios"),
  p("The two comparison pages (seabirds and non-seabirds) put two sets of inputs side by side. Change either scenario's menu and the top 10 species, the vulnerability scatterplot and the family-level plot update for that scenario, so you can see what a choice changes. \"Copy A to B\" copies every Scenario A setting into B. The controls scroll away with the page; use \"Show / hide controls\" to collapse them or \"Pin controls to top\" to keep them in view."),
  h3("Things to keep in mind"),
  tags$ul(
    tags$li("These are point estimates; uncertainty is not yet included."),
    tags$li("Some range maps are incomplete, so some exposure values are NA or low for reasons that are not ecological."),
    tags$li("Rescaling is done across all species in a group that have the component, so scores depend on which species are in the data.")))

definitions_ui <- div(style = "max-width:1100px;",
  h2("Definitions"),
  h3("Output columns"),
  DTOutput("defs_output"),
  h3("Seabird data columns"),
  p(class = "text-muted", "Columns of the seabird input file, as in its data dictionary."),
  DTOutput("defs_sb"),
  h3("Non-seabird data columns"),
  p(class = "text-muted", "Columns of the non-seabird input file, as in its data dictionary."),
  DTOutput("defs_ns"))

# ---- UI ---------------------------------------------------------------------------------------------------
css <- "
:root { --nav-h: 52px; }   /* height of the navbar: change if the page content slides under or away from it */
.navbar { margin-bottom: 0; }
.fixed-page { position: fixed; top: var(--nav-h); left: 0; right: 0; bottom: 0; display: flex; flex-direction: column; background: #f4f4f1; }
.menu-bar { flex: 0 0 auto; max-height: 48vh; overflow-y: auto; background: #fff; border-bottom: 2px solid #c9c9c3;
            padding: 8px 20px 4px; box-shadow: 0 2px 6px rgba(0,0,0,0.12); z-index: 5; }
.menu-bar .form-group { margin-bottom: 6px; }
.menu-bar .radio, .menu-bar .checkbox { margin-top: 2px; margin-bottom: 2px; }
.menu-bar h4 { font-weight: 600; }
.fixed-page.side { flex-direction: row; }
.menu-side { flex: 0 0 340px; overflow-y: auto; background: #fff; border-right: 2px solid #c9c9c3; padding: 12px 16px 30px; }
.menu-side h4 { font-weight: 600; }
.ctl-wrap { background: #fff; border: 1px solid #d5d5cf; border-radius: 6px; padding: 8px 14px; margin-bottom: 16px; }
.ctl-wrap.pinned { position: sticky; top: 0; z-index: 10; box-shadow: 0 3px 8px rgba(0,0,0,0.2); }
.ctl-wrap.pinned .ctl-body { max-height: 45vh; overflow-y: auto; }
.ctl-head { margin-bottom: 6px; }
.pin-label { font-weight: normal; margin-left: 16px; cursor: pointer; }
.ctl-wrap .form-group { margin-bottom: 6px; }
.ctl-wrap .radio, .ctl-wrap .checkbox { margin-top: 2px; margin-bottom: 2px; }
.body-panel { flex: 1 1 auto; overflow-y: auto; padding: 14px 20px 40px; }
.panel-box { background: #fff; border: 1px solid #d5d5cf; border-radius: 6px; padding: 10px 12px; overflow: auto; margin-bottom: 14px; }
.panel-box h5 { margin-top: 0; font-weight: 600; color: #555; }
"

ui <- navbarPage(
  title = "EAAF bird vulnerability",   # was: title plus a small "methods" link to the GitHub notes
  id = "nav", windowTitle = "EAAF bird vulnerability",
  theme = shinythemes::shinytheme("sandstone"),   # was: no theme (default Bootstrap 3)
  header = tags$head(tags$style(HTML(css)),
    # the sandstone navbar is taller than the default, so read the real height into --nav-h (and re-read on resize)
    tags$script(HTML("function setNavH(){var n=document.querySelector('.navbar'); if(n){document.documentElement.style.setProperty('--nav-h', n.offsetHeight+'px');}}
                      $(setNavH); $(window).on('resize', setNavH); $(document).on('shiny:connected', setNavH);"))),

  # ---- Tool ----
  # was: menu in a bar across the top (page_shell(menu = fluidRow(...))); back to a left sidebar. Previous version: app_pre_sidebar.R
  tabPanel("Tool", page_side(
    menu = tagList(
      radioButtons("group", "Species group", choices = c("Seabirds" = "seabird", "Non-seabird migrants" = "nonseabird")),
      helpText("Seabirds and non-seabird migrants are scored on different inputs and are never ranked together. Switching group changes the species list and the options below."),
      hr(), h4("Exponents (weights)"), weight_sliders("", stacked = TRUE, help = TRUE),
      hr(), h4("Sensitivity"),
      combine_radio("", NA, help = TRUE),   # one shared radio (ids must be unique), neutral wording for the second choice
      conditionalPanel("input.group == 'seabird'", seabird_options("", help = TRUE)),
      conditionalPanel("input.group == 'nonseabird'", nonseabird_options("", help = TRUE)),
      hr(), h4("Exposure"), exp_radio("", help = TRUE)),
    body = tabsetPanel(
      tabPanel("Ranked table", br(), cf_ui(), uiOutput("country_note"), uiOutput("excluded_note"),
               DTOutput("tbl"),
               br(), downloadButton("dl", "Download table (csv)")),
      tabPanel("Data limited", br(), uiOutput("country_note_lim"), uiOutput("limited_note"), 
               DTOutput("tbl_limited"),
               br(), downloadButton("dl_limited", "Download table (csv)")),
      tabPanel("Vulnerability scatter", br(), plotly::plotlyOutput("scatter", height = "650px")),
      tabPanel("Priority by family", br(), plotly::plotlyOutput("boxplot", height = "750px"))))),
  tabPanel("Exposure explorer", exposure_explorer_ui()),
  tabPanel("Expert range explorer", expert_explorer_ui()),
  # ---- Instructions / Definitions ----
  tabPanel("Instructions", page_shell(body = instructions_ui)),
  tabPanel("Definitions", page_shell(body = definitions_ui)),

  # ---- Scenario comparison pages ----
  tabPanel("Compare seabird scenarios", compare_page("seabird", "sa", "sb", "seabird")),
  tabPanel("Compare non-seabird scenarios", compare_page("nonseabird", "na", "nb", "non-seabird migrant"))
)

# ---- Server -------------------------------------------------------------------------------------------------
server <- function(input, output, session) {
  exposure_explorer_server(input, output, session)
  expert_explorer_server(input, output, session)
  output$country_note     <- renderUI(cf_note(input$country_filter, nrow(table_df()),   sum(res()$included)))
  output$country_note_lim <- renderUI(cf_note(input$country_filter, nrow(limited_df()), sum(!res()$included)))
  # ================= Tool page =================
  is_ns <- reactive(identical(input$group, "nonseabird"))
  dat <- reactive(if (is_ns()) dat_ns else dat_sb)                  # dataset follows the group switch
  grp_label <- reactive(if (is_ns()) "nonseabird" else "seabird")   # used in download file names

  res <- reactive(run_priority(dat(), build_opts(input$group, function(n) input[[n]])))

  output$excluded_note <- renderUI({
    r <- res(); n_out <- sum(!r$included)
    # was: a list of excluded species names; now they are on the "Data limited" tab
    if (n_out > 0) div(class = "alert alert-warning",
      sprintf("%d of %d species lack an input needed for these settings and are on the \"Data limited\" tab.",
              n_out, nrow(r)))
  })

  table_df <- reactive({
    res() %>% filter(included) %>%
      transmute(Rank = rank, Species = common_name, `Scientific name` = scientific_name,
                IUCN = rl_category, `Migratory status (1-3)` = migration,
                `Seasons mapped (global)` = seasons_mapped_global,
                `Overlap (raw, %)` = overlap_overall * 100,        # raw overlap proportion x 100, before transform/rescaling
                Exposure = exposure, Sensitivity = sensitivity,
                Threat = status, `Weighted exposure` = e_w, `Weighted sensitivity` = s_w,
                `Weighted threat` = t_w, Priority = priority) %>%
      cf_apply(input$country_filter)
  })
  output$tbl <- renderDT({
    datatable(table_df(), rownames = FALSE, options = list(pageLength = 50, scrollX = TRUE)) %>%
      formatSignif("Overlap (raw, %)", 3) %>%    # overlaps are small (often < 0.1%), so significant figures, not decimals
      formatRound(c("Exposure", "Sensitivity", "Threat", "Weighted exposure",
                    "Weighted sensitivity", "Weighted threat", "Priority"), 3)
  })
  output$dl <- downloadHandler(function() paste0("eaaf_", grp_label(), "_priority.csv"),
                               function(file) write.csv(table_df(), file, row.names = FALSE))

  # ---- Data limited tab: species missing something the chosen sensitivity setting needs ----------
  # Raw values and rescaled values for everything the species does have; NA for everything it does not.
  # Rescaled columns: exposure / sensitivity / threat are on the 0.5-2 scale, collision and displacement
  # components are on 0-1 (before they are combined into sensitivity).
  limited_df <- reactive({
    r <- res() %>% filter(!included)
    base <- r %>% transmute(Species = common_name, `Scientific name` = scientific_name, IUCN = rl_category,
                `Migratory status (1-3)` = migration, `Seasons mapped (global)` = seasons_mapped_global,
                `Missing for these settings` = missing_inputs, `Overlap (raw, %)` = overlap_overall * 100)
    # raw inputs differ by group
    raw <- if (is_ns()) r %>% transmute(`Thaxter predicted` = thaxter, `Prop. at risk height` = pcrh,
                                        `Avoidance rate` = avoid, `Flight initiation distance (m)` = fid_m,
                                        `Coastal habitat used` = coastal, `Coastal rank` = coastal_rank,
                                        `Habitats used (BirdBase)` = habitats_n, `Coastal weight (0-1)` = coastal_pref)
           else r %>% transmute(FA = fa, RSZt = rszt, MA = ma)
    rest <- r %>% transmute(`Collision (raw)` = cv_raw, `Displacement (raw)` = dv_raw,
                `Exposure (0.5-2)` = exposure, `Collision (0-1)` = cv_scaled01,
                `Displacement (0-1)` = dv_scaled01, `Sensitivity (0.5-2)` = sensitivity,
                `Threat (0.5-2)` = status)
    if (is_ns()) names(rest) <- sub("^Displacement", "Coastal disturbance", names(rest))
    # round everything to 3 decimals except overlap %, which is tiny and gets 3 significant figures instead
    bind_cols(base, raw, rest) %>%
      mutate(across(where(is.numeric) & !starts_with("Overlap"), ~ round(.x, 3)),
             `Overlap (raw, %)` = signif(`Overlap (raw, %)`, 3)) %>%
    cf_apply(input$country_filter)
  })
  output$limited_note <- renderUI({
    r <- res()
    div(class = "alert alert-info",
      sprintf("%d of %d %s are data limited under these settings (%s). Change the sensitivity setting to see how this list changes.",
              sum(!r$included), nrow(r), if (is_ns()) "non-seabird migrants" else "seabirds",
              c(collision = "collision only", displacement = if (is_ns()) "coastal disturbance only" else "displacement only",
                highest = "higher of the two", sum = "sum of the two")[[input$combine]]))
  })
  output$tbl_limited <- renderDT({
    # NA shown as "NA" (DT leaves numeric NAs blank); sorting still works because only the display is changed
    na_js <- JS("function(data, type, row) { return (data === null && type === 'display') ? 'NA' : data; }")
    datatable(limited_df(), rownames = FALSE,
              options = list(pageLength = 50, scrollX = TRUE,
                             columnDefs = list(list(targets = "_all", render = na_js))))
  })
  output$dl_limited <- downloadHandler(function() paste0("eaaf_", grp_label(), "_data_limited.csv"),
                                       function(file) write.csv(limited_df(), file, row.names = FALSE, na = "NA"))

  output$scatter <- plotly::renderPlotly({
    make_vuln_scatter(res(), w = c(input$w_e, input$w_s, input$w_t), label = FALSE, interactive = TRUE)
  })

  # output$boxplot <- renderPlot({ make_boxplot_tax(res()) })   # old static version
  # was: make_boxplot_tax(res(), interactive = TRUE), which labelled the x axis with every species name
  output$boxplot <- plotly::renderPlotly({ make_boxplot_tax(res(), interactive = TRUE, x_axis = "family") })

  # ================= Scenario comparison pages =================
  # One reactive result per scenario, plus its three outputs. `tag` = "sa","sb","na","nb"; its inputs are prefixed "<tag>_".
  top10_df <- function(r) r %>% filter(included) %>% arrange(rank) %>% head(10) %>%
    transmute(Rank = rank, Priority = priority, Species = common_name, `Scientific name` = scientific_name,
              `Weighted exposure` = e_w, `Weighted sensitivity` = s_w, `Weighted threat` = t_w)

  scenario <- function(tag, group, data) {
    get <- function(n) input[[paste0(tag, "_", n)]]
    r <- reactive(run_priority(data, build_opts(group, get)))
    output[[paste0("top_", tag)]] <- renderDT({
      datatable(top10_df(r()), rownames = FALSE, options = list(dom = "t", paging = FALSE, ordering = FALSE, scrollX = TRUE)) %>%
        formatRound(c("Priority", "Weighted exposure", "Weighted sensitivity", "Weighted threat"), 3)
    })
    output[[paste0("scatter_", tag)]] <- plotly::renderPlotly({
      make_vuln_scatter(r(), w = c(get("w_e"), get("w_s"), get("w_t")), label = FALSE, interactive = TRUE)
    })
    # family plot: x axis labelled by family; hover shows the species and its metrics
    # output[[paste0("fam_", tag)]] <- renderPlot({ make_boxplot_tax(r(), interactive = FALSE, x_axis = "family") })   # static version
    output[[paste0("fam_", tag)]] <- plotly::renderPlotly({ make_boxplot_tax(r(), interactive = TRUE, x_axis = "family") })
  }
  scenario("sa", "seabird", dat_sb);    scenario("sb", "seabird", dat_sb)
  scenario("na", "nonseabird", dat_ns); scenario("nb", "nonseabird", dat_ns)

  # ---- "Copy A to B": push every Scenario A input into Scenario B so one setting can be changed at a time ----
  copy_scenario <- function(from, to, group) {
    f <- function(n) input[[paste0(from, "_", n)]]; id <- function(n) paste0(to, "_", n)
    updateSliderInput(session, id("w_e"), value = f("w_e"))
    updateSliderInput(session, id("w_s"), value = f("w_s"))
    updateSliderInput(session, id("w_t"), value = f("w_t"))
    updateRadioButtons(session, id("combine"), selected = f("combine"))
    updateRadioButtons(session, id("exp_transform"), selected = f("exp_transform"))
    if (identical(group, "nonseabird")) {
      updateRadioButtons(session, id("coll_option"), selected = f("coll_option"))
      updateRadioButtons(session, id("coastal_weight"), selected = f("coastal_weight"))
      updateCheckboxInput(session, id("fid_size_correct"), value = f("fid_size_correct"))
      updateSliderInput(session, id("fid_floor"), value = f("fid_floor"))
    } else {
      updateRadioButtons(session, id("ma_source"), selected = f("ma_source"))
      updateCheckboxInput(session, id("use_esi"), value = f("use_esi"))
      updateCheckboxGroupInput(session, id("tiers"), selected = f("tiers"))
    }
  }
  observeEvent(input$copy_sa_sb, copy_scenario("sa", "sb", "seabird"))
  observeEvent(input$copy_na_nb, copy_scenario("na", "nb", "nonseabird"))

  # ================= Definitions page =================
  output$defs_output <- renderDT(datatable(output_defs, rownames = FALSE,
    options = list(dom = "t", paging = FALSE, ordering = FALSE)))
  dict_table <- function(d) if (is.null(d)) datatable(data.frame(note = "Dictionary file not found next to app.R"), rownames = FALSE)
    else datatable(d, rownames = FALSE, options = list(pageLength = 100, dom = "ft"))
  output$defs_sb <- renderDT(dict_table(dict_sb))
  output$defs_ns <- renderDT(dict_table(dict_ns))
}

shinyApp(ui, server)
