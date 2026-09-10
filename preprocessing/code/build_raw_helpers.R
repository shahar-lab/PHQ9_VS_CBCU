#### CLEAN COMMON COLUMNS ####

# Values that only look like data become proper NA before any coercion.
collected <- collected |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ dplyr::na_if(.x, "NA"))) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ dplyr::na_if(.x, "")))

common_cols <- c("participant_id", "session", "prolific_id", "rt", "time_elapsed", "time")

# ASSUMED[no criterion given]: time coded as factor with levels
# c("time1", "time2"), matching prolific_id's factor treatment.
time_levels <- c("time1", "time2")

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
table { border-collapse: collapse; margin: 0.5rem 0 1.5rem; font-size: 0.9rem; }
th, td { border: 1px solid #ddd; padding: 4px 10px; text-align: left; white-space: nowrap; }
thead th { background: #333; color: #fff; position: sticky; top: 0; }
tbody tr:nth-child(even) { background: #f6f6f6; }
tbody tr:hover { background: #eef4fb; }
.scroll-x { overflow-x: auto; border: 1px solid #ddd; margin-bottom: 1.5rem; }
.scroll-x table { margin: 0; border: none; }
.meta-row { background: #e2e6ea !important; font-style: italic; }
"

# Wraps a head-of-data preview (scrollable when wide, with class/values meta-rows under the
# header) into one styled HTML file, matching data-type-validation-<name>-raw.html.
# freetext_cols names columns with genuinely open-ended text (no possible-values list shown).
write_data_validation_report <- function(df, dictionary, name, freetext_cols = character()) {
  class_values  <- describe_class_row(df)
  values_values <- describe_values_row(df, freetext_cols)
  class_row  <- paste0("<tr class=\"meta-row\">",
                        paste0("<td>", class_values, "</td>", collapse = ""),
                        "</tr>")
  values_row <- paste0("<tr class=\"meta-row\">",
                        paste0("<td>", values_values, "</td>", collapse = ""),
                        "</tr>")
  head_table_html <- knitr::kable(head(df, 10), format = "html") |>
    stringr::str_replace("</thead>\n<tbody>", paste0("</thead>\n<tbody>\n", class_row, "\n", values_row))

  report_html <- c(
    "<html><head><meta charset=\"UTF-8\">",
    paste0("<title>Data type validation: ", name, "</title>"),
    paste0("<style>", validation_report_css, "</style></head><body>"),
    paste0("<h1>Data type validation: ", name, "</h1>"),
    "<h2>Head of data (first 10 rows)</h2>",
    "<div class=\"scroll-x\">", head_table_html, "</div>",
    "</body></html>"
  )
  writeLines(report_html, file.path(output_dir, paste0("data-type-validation-", name, "-raw.html")))
}
