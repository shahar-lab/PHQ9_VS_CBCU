#### BUILD DEMOGRAPHICS RAW (exclude returned participants, drop completion code) ####

# Values that only look like data become proper NA before any coercion.
demographics_collected <- demographics_collected |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ dplyr::na_if(.x, "NA"))) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ dplyr::na_if(.x, "")))

returned_participants <- demographics_collected |>
  dplyr::filter(Status == "RETURNED") |>
  dplyr::pull(`Participant id`)

demographics_raw <- demographics_collected |>
  dplyr::filter(Status != "RETURNED") |>
  dplyr::select(-`Completion code`) |>
  dplyr::mutate(`Participant id` = factor(`Participant id`))

readr::write_csv(demographics_raw, file.path(raw_dir, "demographics.csv"), na = "NA")

#### DESCRIBE: DEMOGRAPHICS ####

demographics_numeric <- describe_numeric(demographics_raw)
demographics_categorical <- describe_categorical(demographics_raw)

demographics_dictionary <- tibble::tribble(
  ~column,                          ~class,      ~meaning,
  "Submission id",                  "character", "Prolific submission identifier",
  "Participant id",                 "factor",    "Prolific participant ID, matches prolific_pid in the other raw CSVs. Levels = Prolific IDs present in the data, no fixed reference.",
  "Status",                         "character", "Prolific submission status. RETURNED participants have already been excluded from this file.",
  "Custom study tncs accepted at",  "character", "timestamp the study terms were accepted",
  "Started at",                     "character", "timestamp the Prolific submission started",
  "Completed at",                   "character", "timestamp the Prolific submission completed",
  "Reviewed at",                    "character", "timestamp the submission was reviewed",
  "Archived at",                    "character", "timestamp the submission was archived",
  "Time taken",                     "numeric",   "total time taken on Prolific, seconds",
  "Total approvals",                "numeric",   "participant's total prior approvals on Prolific",
  "Age",                            "numeric",   "self-reported age",
  "Sex",                            "character", "self-reported sex",
  "Ethnicity simplified",           "character", "self-reported ethnicity",
  "Country of birth",               "character", "self-reported country of birth",
  "Country of residence",           "character", "self-reported country of residence",
  "Nationality",                    "character", "self-reported nationality",
  "Language",                       "character", "self-reported first language",
  "Student status",                 "character", "self-reported student status",
  "Employment status",              "character", "self-reported employment status",
  "Authenticity check: Bots",       "character", "Prolific bot-authenticity check result"
)

demographics_report_lines <- c(
  "", "## demographics.csv", "",
  "Excludes participants with Prolific `Status == \"RETURNED\"` and drops the",
  "`Completion code` column.", "",
  "### Numeric columns", "", knitr::kable(demographics_numeric, format = "pipe"), "",
  "### Categorical columns", "", knitr::kable(demographics_categorical, format = "pipe"), "",
  "### Data dictionary", "", knitr::kable(demographics_dictionary, format = "pipe")
)

raw_report_path <- file.path(output_dir, "raw-data-structure-report.md")
write(demographics_report_lines, file = raw_report_path, append = TRUE, sep = "\n")
