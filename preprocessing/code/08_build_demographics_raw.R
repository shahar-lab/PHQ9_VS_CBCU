# reads: artifacts/demographics_collected.rds · writes: data/raw/demographics.csv

#### CLEAN EACH QUALTRICS EXPORT ####

na_if_all <- function(df) {
  df |> mutate(across(everything(), \(x) na_if(na_if(x, "NA"), "")))
}

# General rules, applied to every Qualtrics export: preview responses, rows whose id is
# blank or "test", and the lab test accounts in `test_prolific_ids` are always excluded;
# a participant who submitted twice keeps the first submission. Qualtrics metadata
# columns are dropped by keeping only the id and the columns named in `keep`.
clean_qualtrics <- function(df, id_col, keep) {
  df |>
    na_if_all() |>
    filter(Status != "Survey Preview",
           !is.na(.data[[id_col]]),
           str_to_lower(str_trim(.data[[id_col]])) != "test",
           !.data[[id_col]] %in% test_prolific_ids) |>
    arrange(StartDate) |>
    distinct(across(all_of(id_col)), .keep_all = TRUE) |>
    select(prolific_id = all_of(id_col), all_of(keep))
}

survey_file    <- "demographic survey.csv"
macarthur_file <- names(demographics_collected) |> str_subset("^MacArthur")

survey <- demographics_collected[[survey_file]] |>
  clean_qualtrics("PROLIFIC_PID",
                  keep = c(ai_check = "AI", gender = "gender", sex = "sex",
                           age = "age_1", country_of_birth = "country of birth",
                           country_of_residence = "country of residence",
                           marital_status = "marital status", ethnicity = "ethnicity",
                           student = "student", education = "education",
                           employment_status = "employment status", hand = "hand",
                           depression_diagnosis = "depression diagnosis",
                           medication = "medication"))

macarthur <- demographics_collected[[macarthur_file]] |>
  clean_qualtrics("prolifc_id", keep = c(ladder_rung = "__js_ladder"))

#### COMBINE EXPORTS INTO ONE DEMOGRAPHICS TABLE ####

# TEMPORARY: the survey and the MacArthur ladder were collected as two separate
# Qualtrics surveys. Remove this block once all demographics come in a single export.
demographics_combined <- full_join(survey, macarthur, by = "prolific_id")

#### TYPE COERCION ####

factor_cols <- c("gender", "sex", "country_of_birth", "country_of_residence",
                 "marital_status", "ethnicity", "student", "education",
                 "employment_status", "hand", "depression_diagnosis", "medication")

demographics_raw <- demographics_combined |>
  mutate(prolific_id = factor(prolific_id),
         age         = as.integer(age),
         ladder_rung = as.integer(ladder_rung),
         across(all_of(factor_cols), \(x) factor(x, levels = sort(unique(x))))) |>
  arrange(prolific_id)

write_csv(demographics_raw, file.path(raw_dir, "demographics.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

demographics_dictionary <- tribble(
  ~column,                 ~class,    ~meaning,
  "prolific_id",           "factor",  "Prolific participant ID, matches prolific_id in the other raw CSVs.",
  "ai_check",              "character", "Free-text answer to the human-or-AI check.",
  "gender",                "factor",  "self-reported gender",
  "sex",                   "factor",  "self-reported sex",
  "age",                   "integer", "self-reported age in years",
  "country_of_birth",      "factor",  "self-reported country of birth",
  "country_of_residence",  "factor",  "self-reported country of residence",
  "marital_status",        "factor",  "self-reported marital status",
  "ethnicity",             "factor",  "self-reported ethnicity",
  "student",               "factor",  "currently a student (Yes/No)",
  "education",             "factor",  "highest education completed",
  "employment_status",     "factor",  "self-reported employment status",
  "hand",                  "factor",  "dominant hand",
  "depression_diagnosis",  "factor",  "ever formally diagnosed with depression",
  "medication",            "factor",  "ever took prescribed medication for depression",
  "ladder_rung",           "integer", "MacArthur subjective social status ladder rung, 1-10"
)

write_data_validation_report(demographics_raw, demographics_dictionary, "demographics",
                             freetext_cols = "ai_check")
