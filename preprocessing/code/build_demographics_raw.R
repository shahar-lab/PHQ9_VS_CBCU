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
  dplyr::select(-`Completion code`, -Status, -`Submission id`,
                -`Custom study tncs accepted at`, -`Started at`, -`Completed at`,
                -`Reviewed at`, -`Archived at`, -`Time taken`) |>
  dplyr::rename(prolific_id = `Participant id`) |>
  dplyr::mutate(
    prolific_id             = factor(prolific_id),
    `Total approvals`       = as.numeric(`Total approvals`),
    Age                     = as.numeric(Age),
    Sex                     = factor(Sex),
    `Ethnicity simplified`  = factor(`Ethnicity simplified`),
    `Country of birth`      = factor(`Country of birth`),
    `Country of residence`  = factor(`Country of residence`),
    Nationality             = factor(Nationality),
    `Student status`        = factor(`Student status`),
    `Employment status`     = factor(`Employment status`)
  )

readr::write_csv(demographics_raw, file.path(raw_dir, "demographics.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

demographics_dictionary <- tibble::tribble(
  ~column,                          ~class,      ~meaning,
  "prolific_id",                    "factor",    "Prolific participant ID, matches prolific_id in the other raw CSVs. Levels = Prolific IDs present in the data, no fixed reference.",
  "Total approvals",                "numeric",   "participant's total prior approvals on Prolific",
  "Age",                            "numeric",   "self-reported age",
  "Sex",                            "factor",    "self-reported sex",
  "Ethnicity simplified",           "factor",    "self-reported ethnicity",
  "Country of birth",               "factor",    "self-reported country of birth",
  "Country of residence",           "factor",    "self-reported country of residence",
  "Nationality",                    "factor",    "self-reported nationality",
  "Language",                       "character", "self-reported first language",
  "Student status",                 "factor",    "self-reported student status",
  "Employment status",              "factor",    "self-reported employment status",
  "Authenticity check: Bots",       "character", "Prolific bot-authenticity check result"
)

write_data_validation_report(demographics_raw, demographics_dictionary, "demographics")
