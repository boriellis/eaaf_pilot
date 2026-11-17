# =============================================================================
# country_filter.R  --  "Occurs in" filter for the ranked-table and data-limited tabs
#
# Reads map_data/species_countries.csv (made by build_country_data.R). The filter only HIDES rows:
# ranks, scores and all the maths stay exactly as calculated across the whole group.
# If the file is missing the filter box simply does not appear.
# =============================================================================

cf_file <- file.path("map_data", "species_countries.csv")
cf_ok   <- file.exists(cf_file)

if (cf_ok) {
  cf_data <- read.csv(cf_file, stringsAsFactors = FALSE)
  cf_list <- strsplit(cf_data$countries, "; ", fixed = TRUE)          # one character vector of countries per species
  names(cf_list) <- cf_data$scientific_name
  cf_all  <- sort(unique(unlist(cf_list)))
  # country list, with high seas last
  cf_all  <- c(setdiff(cf_all, "High seas (no EEZ)"), intersect(cf_all, "High seas (no EEZ)"))
}

# the input box (put above the ranked table); empty = no filter
cf_ui <- function() {
  if (!cf_ok) return(NULL)
  tagList(
    selectizeInput("country_filter", "Occurs in (any of):", choices = cf_all, multiple = TRUE, width = "100%",
                   options = list(placeholder = "All countries. Type or pick one or more to filter...")),
    helpText("Lists species whose seasonal range overlaps a country's land or exclusive economic zone (EEZ) inside the flyway. ",
             "This only filters the list: ranks and scores are not recalculated."))
}

# keep rows whose scientific name occurs in any selected country (data frames with a `Scientific name` column)
cf_apply <- function(df, sel) {
  if (!cf_ok || length(sel) == 0) return(df)
  keep <- vapply(df[["Scientific name"]], function(s) any(sel %in% cf_list[[s]]), logical(1))
  df[keep, , drop = FALSE]
}

# one-line note under the box: what is being shown
cf_note <- function(sel, n_shown, n_total) {
  if (!cf_ok || length(sel) == 0) return(NULL)
  div(class = "alert alert-info",
      sprintf("Showing %d of %d species that occur in: %s. Species with no range mapped inside the flyway are hidden while a filter is on.",
              n_shown, n_total, paste(sel, collapse = ", ")))
}
