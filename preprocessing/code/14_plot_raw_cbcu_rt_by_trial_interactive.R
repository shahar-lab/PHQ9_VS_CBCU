# reads: raw_cbcu_rt_plot_data, p_raw_cbcu_rt_by_trial · writes: raw_outputs/14_cbcu_rt_by_trial_interactive.html + companion dependency directory

#### PLOT INTERACTIVE RAW CBCU RT BY TRIAL ####

if (nrow(raw_cbcu_rt_plot_data) == 0) {
  stop("Cannot build the interactive RT plot without complete trial and RT values.")
}

# ASSUMED[participant table order not specified]: sort participant IDs for scanning.
interactive_cbcu_rt_data <- raw_cbcu_rt_plot_data |>
  dplyr::arrange(prolific_id)

maximum_complete_rt <- max(interactive_cbcu_rt_data$rt)
maximum_complete_rt_text <- format(
  maximum_complete_rt,
  scientific = FALSE,
  trim = TRUE
)

interactive_cbcu_rt_plot <- p_raw_cbcu_rt_by_trial +
  ggplot2::coord_cartesian(ylim = c(0, maximum_complete_rt))

interactive_cbcu_rt_widget <- plotly::ggplotly(
  interactive_cbcu_rt_plot,
  tooltip = c("trial", "rt", "prolific_id")
) |>
  plotly::layout(
    yaxis = list(range = c(0, maximum_complete_rt), autorange = FALSE)
  ) |>
  plotly::config(displaylogo = FALSE, responsive = TRUE)

# ASSUMED[exact responsive plot height not specified]: use 52vh capped at 450px with a 300px minimum.
interactive_cbcu_rt_controls <- htmltools::tags$div(
  id = "cbcu-rt-controls",
  htmltools::tags$style(htmltools::HTML(
    "html,body{height:auto!important;min-height:100%;margin:0;overflow-x:hidden!important;overflow-y:auto!important}body{background:#fff}#htmlwidget_container{box-sizing:border-box;width:min(100%,1100px);margin:0 auto;padding:16px clamp(12px,2vw,24px) 32px;overflow:visible}#htmlwidget_container>.plotly.html-widget{box-sizing:border-box;width:100%!important;height:clamp(300px,52vh,450px)!important;min-height:300px;max-height:450px}.cbcu-controls{display:flex;flex-wrap:wrap;gap:16px;margin:12px 0 18px}.cbcu-controls label{display:flex;flex:1 1 170px;max-width:230px;min-width:0;flex-direction:column;font:14px sans-serif;gap:5px}.cbcu-controls input{box-sizing:border-box;width:100%;max-width:100%;padding:6px}.cbcu-table-wrapper{width:100%;margin-top:18px;overflow-x:auto}.cbcu-count-table{border-collapse:collapse;table-layout:fixed;width:100%;font:14px sans-serif}.cbcu-count-table th,.cbcu-count-table td{border:1px solid #d9d9d9;padding:7px 10px;text-align:right;overflow-wrap:anywhere}.cbcu-count-table th:first-child,.cbcu-count-table td:first-child{text-align:left}.cbcu-count-table th{background:#f3f3f3}"
  )),
  htmltools::tags$div(
    class = "cbcu-controls",
    htmltools::tags$label(
      "Displayed y-axis minimum",
      htmltools::tags$input(id = "cbcu-y-min", type = "number", step = "any", value = "0")
    ),
    htmltools::tags$label(
      "Displayed y-axis maximum",
      htmltools::tags$input(id = "cbcu-y-max", type = "number", step = "any", value = maximum_complete_rt_text)
    ),
    htmltools::tags$label(
      "Lower RT counting limit",
      htmltools::tags$input(id = "cbcu-count-lower", type = "number", step = "any", value = "0")
    ),
    htmltools::tags$label(
      "Upper RT counting limit",
      htmltools::tags$input(id = "cbcu-count-upper", type = "number", step = "any", value = maximum_complete_rt_text)
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
      rt = interactive_cbcu_rt_data$rt
    )
  )

interactive_cbcu_rt_html_path <- file.path(
  raw_output_dir,
  "14_cbcu_rt_by_trial_interactive.html"
)
interactive_cbcu_rt_dependency_dir <- file.path(
  raw_output_dir,
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
