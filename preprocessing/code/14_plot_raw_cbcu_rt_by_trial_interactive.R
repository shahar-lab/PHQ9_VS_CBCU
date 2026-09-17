# reads: data/raw/cbcu_results.csv · writes: reports-raw/14_cbcu_rt_by_trial_interactive.html + companion dependency directory

#### PLOT INTERACTIVE RAW CBCU RT BY TRIAL ####

interactive_cbcu_rt_data <- read_csv(
  file.path(raw_dir, "cbcu_results.csv"),
  show_col_types = FALSE
) |>
  dplyr::mutate(
    prolific_id = as.character(prolific_id),
    time = as.character(time)
  ) |>
  dplyr::filter(stats::complete.cases(trial, rt)) |>
  dplyr::arrange(prolific_id)

if (nrow(interactive_cbcu_rt_data) == 0) {
  stop("Cannot build the interactive RT plot without complete trial and RT values.")
}

x_limits <- range(interactive_cbcu_rt_data$trial)
x_breaks <- round(seq(x_limits[1], x_limits[2], length.out = 4))
pearson_r <- stats::cor(
  interactive_cbcu_rt_data$trial,
  interactive_cbcu_rt_data$rt,
  method = "pearson"
)
maximum_complete_rt <- max(interactive_cbcu_rt_data$rt)
maximum_complete_rt_text <- format(
  maximum_complete_rt,
  scientific = FALSE,
  trim = TRUE
)
interactive_participant_ids <- unique(interactive_cbcu_rt_data$prolific_id)
interactive_y_ticks <- seq(0, maximum_complete_rt, length.out = 4)
interactive_y_ticks[1] <- 0
interactive_y_ticks[length(interactive_y_ticks)] <- maximum_complete_rt
interactive_y_tick_text <- format(
  interactive_y_ticks,
  scientific = FALSE,
  trim = TRUE
)

slider_number_input <- function(id, label, value) {
  htmltools::tags$label(
    label,
    htmltools::tags$div(
      class = "cbcu-slider-row",
      htmltools::tags$input(
        id = paste0(id, "-slider"),
        type = "range",
        min = "0",
        max = maximum_complete_rt_text,
        step = "any",
        value = value
      ),
      htmltools::tags$input(
        id = id,
        type = "number",
        step = "any",
        value = value
      )
    )
  )
}

# ASSUMED[interactive canvas]: drop the square aspect ratio and the participant
# legend so ggplotly keeps a fixed 450px height instead of a blank fill layout.
# ASSUMED[point transparency not quantified]: alpha = 0.35 keeps dense,
# participant-coloured observations visible while preserving overlap.
interactive_cbcu_rt_plot <- ggplot2::ggplot(
  interactive_cbcu_rt_data,
  ggplot2::aes(x = trial, y = rt, colour = prolific_id)
) +
  ggplot2::geom_point(alpha = 0.35, size = 1.5) +
  ggplot2::geom_smooth(
    ggplot2::aes(group = 1),
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    colour = "#EE6677",
    linewidth = 0.8
  ) +
  ggplot2::annotate(
    "text", x = Inf, y = Inf,
    label = sprintf("[Pearson r = %.2f]", pearson_r),
    hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30"
  ) +
  ggplot2::scale_colour_viridis_d(option = "D", end = 0.9) +
  ggplot2::scale_x_continuous(breaks = x_breaks) +
  ggplot2::scale_y_continuous(breaks = interactive_y_ticks) +
  ggplot2::coord_cartesian(ylim = c(0, maximum_complete_rt)) +
  ggplot2::theme_minimal(base_size = 13) +
  ggplot2::theme(
    legend.position = "none",
    panel.grid.minor = ggplot2::element_blank()
  ) +
  ggplot2::labs(
    title = "Raw CBCU response time by trial",
    x = "CBCU trial number",
    y = "RT (ms)",
    colour = "Participant"
  )

interactive_cbcu_rt_widget <- plotly::ggplotly(
  interactive_cbcu_rt_plot,
  tooltip = c("trial", "rt", "prolific_id"),
  width = NULL,
  height = 450
) |>
  plotly::layout(
    yaxis = list(
      range = c(0, maximum_complete_rt),
      autorange = FALSE,
      tickmode = "array",
      tickvals = interactive_y_ticks,
      ticktext = interactive_y_tick_text,
      showticklabels = TRUE,
      ticks = "outside"
    ),
    showlegend = FALSE,
    autosize = TRUE
  ) |>
  plotly::config(displaylogo = FALSE, responsive = TRUE)

interactive_cbcu_rt_widget$sizingPolicy$browser$fill <- FALSE
interactive_cbcu_rt_widget$sizingPolicy$viewer$fill <- FALSE
interactive_cbcu_rt_widget$sizingPolicy$browser$defaultHeight <- 450
interactive_cbcu_rt_widget$sizingPolicy$viewer$defaultHeight <- 450
interactive_cbcu_rt_widget$height <- 450

interactive_cbcu_rt_controls <- htmltools::tags$div(
  id = "cbcu-rt-controls",
  htmltools::tags$style(htmltools::HTML(
    paste0(
      "html,body{margin:0;background:#fff;overflow-x:hidden;overflow-y:auto}",
      "#htmlwidget_container{box-sizing:border-box;width:min(100%,1100px);margin:0 auto;padding:16px clamp(12px,2vw,24px) 32px}",
      "#htmlwidget_container>.plotly.html-widget,.html-widget.html-fill-item{box-sizing:border-box;width:100%!important;height:450px!important;flex:none!important}",
      ".cbcu-controls{display:flex;flex-wrap:wrap;gap:16px;margin:12px 0 18px}",
      ".cbcu-controls label{display:flex;flex:1 1 210px;max-width:260px;min-width:0;flex-direction:column;font:14px sans-serif;gap:5px}",
      ".cbcu-slider-row{display:flex;gap:8px;align-items:center}",
      ".cbcu-slider-row input[type=range]{flex:1;min-width:0}",
      ".cbcu-slider-row input[type=number]{box-sizing:border-box;width:7.5em;padding:6px}",
      ".cbcu-top-filter,.cbcu-participant-filter{display:flex;flex-direction:column;font:14px sans-serif;gap:5px;max-width:320px;margin:0 0 12px}",
      ".cbcu-top-filter select,.cbcu-participant-filter select{box-sizing:border-box;width:100%;padding:6px}",
      ".cbcu-table-wrapper{width:100%;margin-top:18px;overflow-x:auto}",
      ".cbcu-count-table{border-collapse:collapse;table-layout:fixed;width:100%;font:14px sans-serif}",
      ".cbcu-count-table th,.cbcu-count-table td{border:1px solid #d9d9d9;padding:7px 10px;text-align:right;overflow-wrap:anywhere}",
      ".cbcu-count-table th:first-child,.cbcu-count-table td:first-child{text-align:left}",
      ".cbcu-count-table th{background:#f3f3f3}"
    )
  )),
  htmltools::tags$label(
    class = "cbcu-top-filter",
    "Session",
    htmltools::tags$select(
      id = "cbcu-time",
      htmltools::tags$option(value = "", "Both sessions"),
      htmltools::tags$option(value = "time1", "time1"),
      htmltools::tags$option(value = "time2", "time2")
    )
  ),
  htmltools::tags$div(
    class = "cbcu-controls",
    slider_number_input("cbcu-y-min", "Displayed y-axis minimum", "0"),
    slider_number_input("cbcu-y-max", "Displayed y-axis maximum", maximum_complete_rt_text),
    slider_number_input("cbcu-count-lower", "Lower RT counting limit", "0"),
    slider_number_input("cbcu-count-upper", "Upper RT counting limit", maximum_complete_rt_text)
  ),
  htmltools::tags$label(
    class = "cbcu-participant-filter",
    "Participant",
    htmltools::tags$select(
      id = "cbcu-participant",
      htmltools::tags$option(value = "", "All participants"),
      lapply(
        interactive_participant_ids,
        function(id) htmltools::tags$option(value = id, id)
      )
    )
  )
)

interactive_cbcu_rt_table <- htmltools::tags$div(
  class = "cbcu-table-wrapper",
  htmltools::tags$table(
    class = "cbcu-count-table",
    htmltools::tags$thead(
      htmltools::tags$tr(
        htmltools::tags$th("Participant ID"),
        htmltools::tags$th("Trials below lower limit"),
        htmltools::tags$th("Trials above upper limit")
      )
    ),
    htmltools::tags$tbody(id = "cbcu-count-table-body")
  )
)

interactive_cbcu_rt_javascript <- paste(
  readLines(file.path(code_dir, "14_cbcu_rt_by_trial_interactive.js"), warn = FALSE),
  collapse = "\n"
)

interactive_cbcu_rt_widget <- interactive_cbcu_rt_widget |>
  htmlwidgets::prependContent(interactive_cbcu_rt_controls) |>
  htmlwidgets::appendContent(interactive_cbcu_rt_table) |>
  htmlwidgets::onRender(
    interactive_cbcu_rt_javascript,
    data = list(
      participant = interactive_cbcu_rt_data$prolific_id,
      rt = interactive_cbcu_rt_data$rt,
      trial = interactive_cbcu_rt_data$trial,
      time = as.character(interactive_cbcu_rt_data$time)
    )
  )

interactive_cbcu_rt_html_path <- file.path(
  reports_raw_dir,
  "14_cbcu_rt_by_trial_interactive.html"
)
interactive_cbcu_rt_dependency_dir <- file.path(
  reports_raw_dir,
  "14_cbcu_rt_by_trial_interactive_files"
)

htmlwidgets::saveWidget(
  interactive_cbcu_rt_widget,
  interactive_cbcu_rt_html_path,
  selfcontained = FALSE,
  libdir = basename(interactive_cbcu_rt_dependency_dir),
  title = "Raw CBCU response time by trial"
)

interactive_cbcu_rt_dependencies <- list.files(
  interactive_cbcu_rt_dependency_dir,
  recursive = TRUE,
  full.names = TRUE
)

if (
  !file.exists(interactive_cbcu_rt_html_path) ||
  !dir.exists(interactive_cbcu_rt_dependency_dir) ||
  length(interactive_cbcu_rt_dependencies) == 0
) {
  stop("Interactive CBCU RT export is missing its HTML or companion dependencies.")
}
