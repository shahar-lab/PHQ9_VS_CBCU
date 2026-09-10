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
  dplyr::mutate(
    `Participant id`        = factor(`Participant id`),
    Status                  = factor(Status),
    Sex                     = factor(Sex),
    `Ethnicity simplified`  = factor(`Ethnicity simplified`),
    `Student status`        = factor(`Student status`),
    `Employment status`     = factor(`Employment status`)
  )

readr::write_csv(demographics_raw, file.path(raw_dir, "demographics.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

demographics_dictionary <- tibble::tribble(
  ~column,                          ~class,      ~meaning,
  "Submission id",                  "character", "Prolific submission identifier",
  "Participant id",                 "factor",    "Prolific participant ID, matches prolific_pid in the other raw CSVs. Levels = Prolific IDs present in the data, no fixed reference.",
  "Status",                         "factor",    "Prolific submission status. RETURNED participants have already been excluded from this file.",
  "Custom study tncs accepted at",  "character", "timestamp the study terms were accepted",
  "Started at",                     "character", "timestamp the Prolific submission started",
  "Completed at",                   "character", "timestamp the Prolific submission completed",
  "Reviewed at",                    "character", "timestamp the submission was reviewed",
  "Archived at",                    "character", "timestamp the submission was archived",
  "Time taken",                     "numeric",   "total time taken on Prolific, seconds",
  "Total approvals",                "numeric",   "participant's total prior approvals on Prolific",
  "Age",                            "numeric",   "self-reported age",
  "Sex",                            "factor",    "self-reported sex",
  "Ethnicity simplified",           "factor",    "self-reported ethnicity",
  "Country of birth",               "character", "self-reported country of birth",
  "Country of residence",           "character", "self-reported country of residence",
  "Nationality",                    "character", "self-reported nationality",
  "Language",                       "character", "self-reported first language",
  "Student status",                 "factor",    "self-reported student status",
  "Employment status",              "factor",    "self-reported employment status",
  "Authenticity check: Bots",       "character", "Prolific bot-authenticity check result"
)

write_data_validation_report(demographics_raw, demographics_dictionary, "demographics")
