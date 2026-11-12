# plot_functions.R - vulnerability scatter + taxonomy boxplot, each as a static ggplot or an interactive plotly
# NOT YET RUN (no R where this was written). Packages: dplyr, tidyr, ggplot2, scico, scales, plotly
library(dplyr); library(tidyr); library(ggplot2)

# ---- shared helpers -------------------------------------------------------------------
# One hover string used by both interactive plots (same values in both).
hover_text <- function(d) {
  paste0("<b>", d$common_name, "</b> (", as.character(d$rl_category), ")",
         "<br>Priority: ", signif(d$priority, 3), "  (rank ", d$rank, ")",
         "<br>Exposure: raw ", signif(d$overlap_overall, 3), ", scaled ", signif(d$exposure, 3),
         "<br>Sensitivity: scaled ", signif(d$sensitivity, 3),
         # was: "(FA ..., RSZt ..., MA ...)" written out here; now a per-group description from run_priority()
         "<br>  collision raw ", signif(d$cv_raw, 3), " (", d$coll_detail, ")",
         "<br>  ", d$disp_name, " raw ", signif(d$dv_raw, 3), " (", d$disp_detail, ")",
         "<br>Threat: scaled ", signif(d$status, 3),
         "<br>Migratory status: ", d$migration, " (1-3)",
         "<br>Seasons mapped (global): ", d$seasons_mapped_global)
}
# "#RRGGBB" -> "rgba(r,g,b,a)" (plotly wants this for translucent fills)
rgba <- function(hex, a) { v <- grDevices::col2rgb(hex); sprintf("rgba(%d,%d,%d,%.2f)", v[1], v[2], v[3], a) }
# Vulnerability colour scale: log2(priority) from -6 to 6, shown as the raw priority value
vuln_breaks <- seq(-6, 6, 2)
vuln_labels <- c("0.0156", "0.0625", "0.25", "1", "4", "16", "64")
# Point size by IUCN category: ggplot size units / plotly marker diameter in px (both made smaller than before)
size_gg   <- c(LC = 1.5, NT = 2, VU = 2.5, EN = 3, CR = 3.5)
size_px   <- c(LC = 5, NT = 6.5, VU = 8, EN = 9.5, CR = 11)

# ---- 1. Vulnerability scatter ---------------------------------------------------------------
#' @param res output of run_priority()
#' @param interactive TRUE -> native plotly figure (hover, zoom); FALSE -> static ggplot
make_vuln_scatter <- function(res, w = c(3, 2, 1), n_seg = 30, label = FALSE, interactive = FALSE) {
  d <- res %>% filter(included, !is.na(priority)) %>%
    mutate(hover = hover_text(.), x = e_w, y = s_w, ess = priority, log2_ess = log2(ess),
           rl_category = factor(rl_category, levels = c("LC", "NT", "VU", "EN", "CR")),
           id = scientific_name)
  if (interactive) return(make_vuln_scatter_plotly(d))

  # ESS along each species' exposure interval, sensitivity and status held at their central values.
  d_seg <- d %>%
    rowwise() %>%
    mutate(x_seq = list(seq(e_w_lwr, e_w_upr, length.out = n_seg)),
           ess_seq = list(x_seq * y * t_w)) %>%
    ungroup()
  d_seg <- d_seg %>% select(id, y, x_seq, ess_seq) %>% unnest(c(x_seq, ess_seq)) %>%
    group_by(id) %>%
    mutate(x_end = lead(x_seq), log2_ess_seg = log2((ess_seq + lead(ess_seq)) / 2)) %>%
    filter(!is.na(x_end)) %>% ungroup()

  vuln_cols <- scico::scico(256, palette = "lipari")
  p <- ggplot(d, aes(x = x, y = y)) +
    geom_segment(data = d_seg, aes(x = x_seq, xend = x_end, y = y, yend = y, color = log2_ess_seg),
                 linewidth = 0.4, alpha = 0.5, show.legend = FALSE) +
    # was: geom_point(aes(color = log2_ess, size = rl_category, text = hover), stroke = 0)
    # now: smaller, translucent points with a thin dark outline (shape 21 = fill + outline)
    geom_point(aes(fill = log2_ess, size = rl_category, text = hover),
               shape = 21, color = "grey15", stroke = 0.25, alpha = 0.7) +
    scale_x_log10(breaks = 2^(-3:3), labels = 2^(-3:3)) +
    scale_y_log10(breaks = 2^(-2:2), labels = 2^(-2:2)) +
    scale_color_gradientn(colours = vuln_cols, limits = c(-6, 6), oob = scales::squish, guide = "none") +
    scale_fill_gradientn(colours = vuln_cols, limits = c(-6, 6), breaks = vuln_breaks, labels = vuln_labels,
                         name = "Vulnerability", oob = scales::squish) +
    scale_size_manual(values = size_gg, name = "IUCN status", drop = FALSE) +
    guides(size = guide_legend(override.aes = list(fill = "grey60", alpha = 1))) +   # grey legend keys
    labs(x = "Weighted exposure (rescaled, log scale)", y = "Weighted sensitivity (rescaled, log scale)") +
    theme_classic() +
    theme(axis.title = element_text(size = 8), axis.text = element_text(size = 7),
          axis.title.x = element_text(face = "bold"), axis.title.y = element_text(face = "bold"),
          legend.key.width = unit(0.5, "cm"), legend.key.height = unit(0.3, "cm"),
          legend.title = element_text(size = 8), legend.text = element_text(size = 7))
  if (label && requireNamespace("ggrepel", quietly = TRUE))
    p <- p + ggrepel::geom_text_repel(aes(label = common_name), size = 2.5, max.overlaps = 30)
  p
}

# Native plotly version (not ggplotly): gives full control of the legend. Exposure bars (the ggplot
# segments) are not drawn here; at D = 1 they collapse to the point. Add them back when D > 1.
make_vuln_scatter_plotly <- function(d) {
  cols <- scico::scico(256, palette = "lipari")
  cscale <- lapply(seq_along(cols), function(i) list((i - 1) / (length(cols) - 1), cols[i]))
  p <- plotly::plot_ly() %>%
    plotly::add_trace(
      x = d$x, y = d$y, type = "scatter", mode = "markers", text = d$hover, hoverinfo = "text",
      showlegend = FALSE,
      marker = list(size = unname(size_px[as.character(d$rl_category)]), color = d$log2_ess,
                    colorscale = cscale, cmin = -6, cmax = 6, opacity = 0.7,
                    line = list(color = "rgba(30,30,30,0.9)", width = 0.6),
                    colorbar = list(title = "Vulnerability", tickvals = vuln_breaks, ticktext = vuln_labels,
                                    len = 0.45, y = 1, yanchor = "top")))
  # legend for point size only: grey dummy traces (no data), one per IUCN category
  for (cat in names(size_px)) {
    p <- p %>% plotly::add_trace(
      x = NA_real_, y = NA_real_, type = "scatter", mode = "markers", name = cat, hoverinfo = "skip",
      marker = list(size = size_px[[cat]], color = "rgba(150,150,150,0.8)",
                    line = list(color = "rgba(30,30,30,0.9)", width = 0.6)))
  }
  p %>% plotly::layout(
    xaxis = list(type = "log", title = list(text = "<b>Weighted exposure (rescaled, log scale)</b>", font = list(size = 12)),
                 tickvals = 2^(-3:3), ticktext = as.character(2^(-3:3)), showline = TRUE, showgrid = FALSE,
                 zeroline = FALSE, ticks = "outside"),
    yaxis = list(type = "log", title = list(text = "<b>Weighted sensitivity (rescaled, log scale)</b>", font = list(size = 12)),
                 tickvals = 2^(-2:2), ticktext = as.character(2^(-2:2)), showline = TRUE, showgrid = FALSE,
                 zeroline = FALSE, ticks = "outside"),
    legend = list(title = list(text = "IUCN status"), x = 1.02, y = 0.4, yanchor = "top"),
    plot_bgcolor = "white", paper_bgcolor = "white")
}


# ---- 2. Priority by family (boxplot, taxonomic order) ---------------------------------------------
# Adapted from make_boxplot_app(). Box = 25-75%, whiskers = 2.5-97.5% of the priority draws per species.
# With point estimates (D = 1) every box collapses to a line, so the median is also drawn as a point
# (the point carries the hover text). interactive = TRUE: plotly, zoom on the x axis (drag a box, or use the
# slider under the axis; double-click resets) and hover shows the same values as the scatter.
make_boxplot_tax <- function(res, interactive = FALSE) {
  dr <- attr(res, "priority_draws")
  q <- function(p) apply(dr, 1, stats::quantile, p, na.rm = TRUE, names = FALSE)
  stats_df <- data.frame(scientific_name = rownames(dr), ymin = q(.025), lower = q(.25),
                         middle = q(.5), upper = q(.75), ymax = q(.975), stringsAsFactors = FALSE)
  # was: select(common_name, scientific_name, family, tax_index) only; now keeps every column for the hover text
  d <- res %>% filter(included, !is.na(priority)) %>%
    left_join(stats_df, by = "scientific_name") %>%
    arrange(tax_index) %>%
    mutate(hover = hover_text(.), x_pos = row_number())

  fam_order <- unique(d$family)
  pal <- c("#001959", "#0E395E", "#165061", "#27635F", "#47704F", "#6C7B3B",
           "#97882C", "#C49138", "#EA995E", "#FBA894", "#FCB9C6", "#F9CCF9")
  pal <- setNames(pal[round(seq(1, length(pal), length.out = length(fam_order)))], fam_order)
  if (interactive) return(make_boxplot_plotly(d, fam_order, pal))

  d <- d %>% mutate(common_name = factor(common_name, levels = common_name))
  d$family <- factor(d$family, levels = fam_order)
  rects <- d %>% mutate(x_start = x_pos - 0.5, x_end = x_pos + 0.5,
                        ymin_r = min(ymin, na.rm = TRUE) / 1.2, ymax_r = max(ymax, na.rm = TRUE) * 1.2)

  ggplot(d, aes(x = common_name)) +
    geom_rect(data = rects, aes(xmin = x_start, xmax = x_end, ymin = ymin_r, ymax = ymax_r, fill = family),
              inherit.aes = FALSE, alpha = 0.4, color = NA) +
    geom_boxplot(aes(ymin = ymin, lower = lower, middle = middle, upper = upper, ymax = ymax, fill = family),
                 stat = "identity", show.legend = FALSE) +
    geom_point(aes(y = middle), size = 1.5) +
    scale_y_log10() +
    scale_x_discrete() +
    scale_fill_manual(values = pal, limits = fam_order) +
    guides(fill = guide_legend(ncol = 3)) +
    labs(x = "Species", y = "Priority score", fill = "Family") +
    theme_classic() +
    theme(axis.title = element_text(size = 15), axis.text = element_text(size = 12),
          axis.title.x = element_text(face = "bold", margin = margin(t = 15)),
          axis.title.y = element_text(face = "bold"),
          # was size 12 (default from axis.text), labels overlapped; smaller now
          axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 7),
          legend.position = "bottom", legend.title = element_text(size = 15),
          legend.text = element_text(size = 12))
}

make_boxplot_plotly <- function(d, fam_order, pal) {
  p <- plotly::plot_ly()
  for (f in fam_order) {
    df <- d[d$family == f, ]; col <- pal[[f]]
    # was: a plotly box trace from the precomputed quantiles. plotly R guessed horizontal boxes (x given, no y) and
    # piled every box at the left edge, so it is replaced by error bars on the median points (below).
    # p <- p %>% plotly::add_trace(x = df$x_pos, type = "box", q1 = df$lower, median = df$middle, q3 = df$upper,
    #                              lowerfence = df$ymin, upperfence = df$ymax, width = 0.7,
    #                              fillcolor = rgba(col, 0.6), line = list(color = col, width = 1),
    #                              name = f, legendgroup = f, showlegend = FALSE, hoverinfo = "skip")
    p <- p %>%
      # thick translucent bar = interquartile range (25-75%); zero length while D = 1
      plotly::add_trace(x = df$x_pos, y = df$middle, type = "scatter", mode = "markers",
                        marker = list(size = 1, opacity = 0), hoverinfo = "skip", showlegend = FALSE,
                        legendgroup = f, name = f,
                        error_y = list(type = "data", symmetric = FALSE, array = df$upper - df$middle,
                                       arrayminus = df$middle - df$lower, color = rgba(col, 0.6),
                                       thickness = 7, width = 0)) %>%
      # thin whiskers = 2.5-97.5%, on the median point, which carries the hover text and the family legend entry
      plotly::add_trace(x = df$x_pos, y = df$middle, type = "scatter", mode = "markers",
                        marker = list(size = 6, color = col, line = list(color = "black", width = 0.5)),
                        error_y = list(type = "data", symmetric = FALSE, array = df$ymax - df$middle,
                                       arrayminus = df$middle - df$ymin, color = col, thickness = 1, width = 3),
                        text = df$hover, hoverinfo = "text", name = f, legendgroup = f, showlegend = TRUE)
  }
  # family background bands (one rectangle per family, drawn under the data, full plot height)
  bands <- lapply(fam_order, function(f) {
    xs <- d$x_pos[d$family == f]
    list(type = "rect", xref = "x", yref = "paper", x0 = min(xs) - 0.5, x1 = max(xs) + 0.5, y0 = 0, y1 = 1,
         fillcolor = rgba(pal[[f]], 0.18), line = list(width = 0), layer = "below")
  })
  p %>% plotly::layout(
    shapes = bands,
    xaxis = list(title = "", tickmode = "array", tickvals = d$x_pos, ticktext = as.character(d$common_name),
                 tickangle = -90, tickfont = list(size = 8), automargin = TRUE, showgrid = FALSE,
                 range = c(0.5, max(d$x_pos) + 0.5),
                 rangeslider = list(visible = TRUE, thickness = 0.05)),   # drag the slider to zoom to a chunk
    yaxis = list(type = "log", title = list(text = "<b>Priority score</b>", font = list(size = 13)),
                 tickvals = c(0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20), ticktext = c("0.05", "0.1", "0.2", "0.5", "1", "2", "5", "10", "20"),
                 showline = TRUE, showgrid = FALSE, automargin = TRUE),
    # legend moved to the right (it was below the plot and ran into the slider)
    legend = list(title = list(text = "Family"), orientation = "v", x = 1.02, y = 1, yanchor = "top"),
    margin = list(r = 140),
    plot_bgcolor = "white", paper_bgcolor = "white")
}
