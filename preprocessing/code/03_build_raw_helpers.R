# reads: artifacts/collected.rds · writes: artifacts/collected.rds, artifacts/time_levels.rds

#### CLEAN COMMON COLUMNS ####

# Values that only look like data become proper NA before any coercion.
collected <- readRDS(file.path(artifacts_dir, "collected.rds"))
collected <- collected |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ dplyr::na_if(.x, "NA"))) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ dplyr::na_if(.x, "")))

common_cols <- c("participant_id", "session", "prolific_id", "rt", "time_elapsed", "time")

# ASSUMED[no criterion given]: time coded as factor with levels
# c("time1", "time2"), matching prolific_id's factor treatment.
time_levels <- c("time1", "time2")

saveRDS(collected, file.path(artifacts_dir, "collected.rds"))
saveRDS(time_levels, file.path(artifacts_dir, "time_levels.rds"))

#### DESCRIBE: PER-COLUMN CLASS/VALUES ROWS (shared across raw datasets) ####

# One row of column classes and one of their possible values, meant to sit directly under
# the head-of-data header: numeric -> [min to max]; freetext (named in freetext_cols) -> no
# value; other character/factor -> its distinct values listed, or a count if there are more
# than 6.
describe_class_row <- function(df) {
  purrr::map_chr(df, ~ class(.x)[1])
}

describe_values_row <- function(df, freetext_cols) {
  purrr::imap_chr(df, function(col, col_name) {
    if (col_name %in% freetext_cols) return("")
    if (is.numeric(col)) return(paste0("[", min(col, na.rm = TRUE), " to ", max(col, na.rm = TRUE), "]"))
    values <- sort(unique(as.character(col[!is.na(col)])))
    if (length(values) <= 6) paste(values, collapse = ", ") else paste(length(values), "distinct values")
  })
}

#### WRITE DATA-TYPE VALIDATION REPORT (shared across raw datasets) ####

validation_report_css <- "
body { font-family: -apple-system, Segoe UI, Helvetica, Arial, sans-serif;
       max-width: 1100px; margin: 2rem auto; padding: 0 1rem; color: #222; }
h1 { border-bottom: 2px solid #333; padding-bottom: 0.3rem; }
h2 { margin-top: 2rem; color: #333; }
table { border-collapse: separate; border-spacing: 0; margin: 0.5rem 0 1.5rem; font-size: 0.9rem; }
th, td { border: 1px solid #ddd; padding: 4px 10px; text-align: left; white-space: nowrap; }
tbody tr:nth-child(even) { background: #f6f6f6; }
tbody tr:hover { background: #eef4fb; }
.scroll-x { overflow: auto; max-height: 20rem; border: 1px solid #ddd; margin-bottom: 1.5rem; }
.scroll-x table { margin: 0; border: none; }
.scroll-x thead th,
.scroll-x thead td { position: sticky; z-index: 3; }
.scroll-x thead tr:nth-child(1) th { top: 0; background: #333; color: #fff; }
.scroll-x thead tr:nth-child(2) td { top: 2em; background: #e2e6ea; }
.scroll-x thead tr:nth-child(3) td { top: 4em; background: #e2e6ea; }
.meta-row { background: #e2e6ea !important; font-style: italic; }
"

# Wraps the full table (scrollable on both axes, with class/values meta-rows
# frozen under the header as the first three thead rows) into one styled HTML file,
# matching NN_data-type-validation-<name>-<suffix>.html when step is the producing
# script's two-digit prefix.
# freetext_cols names columns with genuinely open-ended text (no possible-values list shown).
# suffix defaults to "raw" for the raw-step call sites; pass "processed" for processed-step reports.
write_data_validation_report <- function(df, dictionary, name, freetext_cols = character(), suffix = "raw", step = NULL) {
  class_values  <- describe_class_row(df)
  values_values <- describe_values_row(df, freetext_cols)
  class_row  <- paste0("<tr class=\"meta-row\">",
                        paste0("<td>", class_values, "</td>", collapse = ""),
                        "</tr>")
  values_row <- paste0("<tr class=\"meta-row\">",
                        paste0("<td>", values_values, "</td>", collapse = ""),
                        "</tr>")
  table_html <- knitr::kable(df, format = "html") |>
    stringr::str_replace("</thead>", paste0(class_row, "\n", values_row, "\n</thead>"))

  report_html <- c(
    "<html><head><meta charset=\"UTF-8\">",
    paste0("<title>Data type validation: ", name, "</title>"),
    paste0("<style>", validation_report_css, "</style></head><body>"),
    paste0("<h1>Data type validation: ", name, "</h1>"),
    paste0("<h2>Data (", nrow(df), " rows)</h2>"),
    "<div class=\"scroll-x\">", table_html, "</div>",
    "</body></html>"
  )
  prefix <- if (is.null(step)) "" else paste0(step, "_")
  report_dir <- if (identical(suffix, "processed")) output_processed_dir else output_raw_dir
  writeLines(report_html, file.path(report_dir, paste0(prefix, "data-type-validation-", name, "-", suffix, ".html")))
}
