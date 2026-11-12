# =============================================================================
# EAAF bird vulnerability prototype (point estimates): seabirds OR non-seabird migrants
# Run from the folder containing: app.R, core_functions.R, plot_functions.R,
# seabird_all_species_v2.csv, nonseabird_data_v1.csv.   shiny::runApp()
# NOT YET RUN: written without R available; expect to fix small typos on first launch.
# Packages: shiny, DT, dplyr, tidyr, ggplot2, scico, scales, plotly
# =============================================================================
library(shiny); library(DT); library(dplyr)
source("app/core_functions.R"); source("app/plot_functions.R")

# dat <- read.csv("seabird_test_data_v1.csv", stringsAsFactors = FALSE)   # old 34-species complete-case test set
# All seabird-tab species; missing values are "NA" and read in as NA. Which species can be scored depends
# on the sensitivity setting; the rest go to the "Data limited" tab.
# dat <- read.csv("seabird_all_species_v1.csv", stringsAsFactors = FALSE)   # before seasons_mapped_global was added
dat_sb <- read.csv("app/seabird_all_species_v2.csv", stringsAsFactors = FALSE)
# Non-seabird migrants (55 species). Seabirds and non-seabirds are never ranked together.
dat_ns <- read.csv("app/nonseabird_data_v1.csv", stringsAsFactors = FALSE)

ui <- fluidPage(
  titlePanel(title = div("EAAF bird vulnerability: prototype",
                         tags$small(style = "margin-left:15px;",
                                    tags$a("Methods & decisions (GitHub)",
                                           href = "https://boriellis.github.io/eaaf_pilot/",
                                           target = "_blank"))),
             windowTitle = "EAAF bird vulnerability"),
  sidebarLayout(
    sidebarPanel(width = 3,
      radioButtons("group", "Species group",
        choices = c("Seabirds" = "seabird", "Non-seabird migrants" = "nonseabird")),
      hr(), h4("Exponents (weights)"),
      sliderInput("w_e", "Exposure",    min = 0, max = 3, value = 3, step = 1),
      sliderInput("w_s", "Sensitivity", min = 0, max = 3, value = 2, step = 1),
      sliderInput("w_t", "Threat (IUCN)", min = 0, max = 3, value = 1, step = 1),
      hr(), h4("Sensitivity"),
      radioButtons("combine", "Combine collision and displacement",
        choices = c("Collision only" = "collision", "Displacement / disturbance only" = "displacement",
                    "Higher of the two" = "highest", "Sum of the two" = "sum"),
        selected = "highest"),
      # ---- seabird-only options ----
      conditionalPanel("input.group == 'seabird'",
        radioButtons("ma_source", "Collision: avoidance rate (MA) from",
          choices = c("Kelsey et al. 2025 (as published)" = "kelsey",
                      "Lamb et al. 2024 displacement rate" = "lamb")),
        checkboxInput("use_esi", "Displacement: multiply Lamb rate by ESI", value = FALSE),
        checkboxGroupInput("tiers", "Lamb match tiers to use",
          choices = c("A: species" = "A", "B: congener" = "B", "C: family / clade" = "C"),
          selected = c("A", "B", "C"))
      ),
      # ---- non-seabird-only options ----
      conditionalPanel("input.group == 'nonseabird'",
        radioButtons("coll_option", "Collision measure (rescaled 0-1)",
          choices = c("Thaxter et al. 2017 predicted collision vulnerability" = "thaxter",
                      "Proportion at collision risk height x (1 - avoidance rate)" = "pcrh")),
        helpText("Coastal disturbance = flight initiation distance (log, 0-1) x coastal habitat use."),
        checkboxInput("fid_size_correct", "Coastal disturbance: correct flight initiation distance for body mass", value = FALSE),
        sliderInput("fid_floor", "Coastal disturbance: floor for species not known to use coastal habitat (0 = pure gate)",
                    min = 0, max = 0.5, value = 0, step = 0.05)
      ),
      hr(), h4("Exposure"),
      radioButtons("exp_transform", "Transform before rescaling",
        choices = c("log10 (zeros set to half the smallest non-zero value)" = "log10",
                    "Linear" = "linear"))
    ),
    mainPanel(width = 9,
      tabsetPanel(
        tabPanel("Ranked table", br(), uiOutput("excluded_note"), DTOutput("tbl"),
                 br(), downloadButton("dl", "Download table (csv)")),
        tabPanel("Data limited", br(), uiOutput("limited_note"), DTOutput("tbl_limited"),
                 br(), downloadButton("dl_limited", "Download table (csv)")),
        tabPanel("Vulnerability scatter", br(),
                 plotly::plotlyOutput("scatter", height = "650px")),
        tabPanel("Priority by family", br(),
                 plotly::plotlyOutput("boxplot", height = "750px"))
      )
    )
  )
)

server <- function(input, output, session) {
  is_ns <- reactive(identical(input$group, "nonseabird"))
  dat <- reactive(if (is_ns()) dat_ns else dat_sb)      # dataset follows the group switch
  grp_label <- reactive(if (is_ns()) "nonseabird" else "seabird")   # used in download file names

  res <- reactive({
    opts <- list(group = input$group, w = c(input$w_e, input$w_s, input$w_t), combine = input$combine,
                 exp_transform = input$exp_transform)
    if (is_ns()) {
      opts$coll_option <- input$coll_option; opts$fid_size_correct <- input$fid_size_correct
      opts$fid_floor <- input$fid_floor
    } else {
      req(length(input$tiers) > 0)
      opts$ma_source <- input$ma_source; opts$use_esi <- input$use_esi; opts$tiers <- input$tiers
    }
    run_priority(dat(), opts)
  })

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
                `Seasons mapped (global)` = seasons_mapped_global, Exposure = exposure, Sensitivity = sensitivity,
                Threat = status, `Weighted exposure` = e_w, `Weighted sensitivity` = s_w,
                `Weighted threat` = t_w, Priority = priority)
  })
  output$tbl <- renderDT({
    datatable(table_df(), rownames = FALSE, options = list(pageLength = 50, scrollX = TRUE)) %>%
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
                `Missing for these settings` = missing_inputs, `Overlap (raw)` = overlap_overall)
    # raw inputs differ by group
    raw <- if (is_ns()) r %>% transmute(`Thaxter predicted` = thaxter, `Prop. at risk height` = pcrh,
                                        `Avoidance rate` = avoid, `Flight initiation distance (m)` = fid_m,
                                        `Coastal habitat used` = coastal)
           else r %>% transmute(FA = fa, RSZt = rszt, MA = ma)
    dname <- if (is_ns()) "Coastal disturbance" else "Displacement"
    rest <- r %>% transmute(`Collision (raw)` = cv_raw, `Displacement (raw)` = dv_raw,
                `Exposure (0.5-2)` = exposure, `Collision (0-1)` = cv_scaled01,
                `Displacement (0-1)` = dv_scaled01, `Sensitivity (0.5-2)` = sensitivity,
                `Threat (0.5-2)` = status)
    if (is_ns()) names(rest) <- sub("^Displacement", "Coastal disturbance", names(rest))
    bind_cols(base, raw, rest) %>% mutate(across(where(is.numeric), ~ round(.x, 3)))
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
  output$boxplot <- plotly::renderPlotly({ make_boxplot_tax(res(), interactive = TRUE) })
}

shinyApp(ui, server)
