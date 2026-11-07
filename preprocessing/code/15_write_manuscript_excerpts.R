# reads: artifacts/10_after_both_sessions.rds, artifacts/11_after_window_exits.rds,
#        artifacts/11b_after_quiz_errors.rds,
#        artifacts/12_after_rt_bounds.rds, data/processed/demographics.csv
# writes: output/processed/15_participants_excerpt.md,
#         output/processed/15_data_treatment_excerpt.md

#### WRITE MANUSCRIPT EXCERPTS ####

if (!exists("window_exit_max"))    window_exit_max    <- 2
if (!exists("max_window_left_ms")) max_window_left_ms <- 30000
if (!exists("quiz_error_max"))     quiz_error_max     <- 4

step10 <- readRDS(file.path(artifacts_dir, "10_after_both_sessions.rds"))
step11 <- readRDS(file.path(artifacts_dir, "11_after_window_exits.rds"))
step11b <- readRDS(file.path(artifacts_dir, "11b_after_quiz_errors.rds"))
step12 <- readRDS(file.path(artifacts_dir, "12_after_rt_bounds.rds"))
demographics <- read_csv(file.path(processed_dir, "demographics.csv"), show_col_types = FALSE)

n_recruited    <- length(step10$all_pids)
n_missing      <- n_recruited - length(step10$after_both_sessions_pids)
n_window       <- length(step11$after_both_sessions_pids) - length(step11$after_window_exits_pids)
n_quiz         <- length(step11b$after_window_exits_pids) - length(step11b$after_quiz_errors_pids)
n_trials_in    <- nrow(step12$after_window_cbcu)
n_trials_out   <- n_trials_in - nrow(step12$after_rt_bounds)
pct_trials_out <- round(100 * n_trials_out / n_trials_in, 1)
n_final        <- length(step12$after_quiz_errors_pids)
n_final_trials <- nrow(step12$after_rt_bounds)
mean_trials    <- round(n_final_trials / n_final, 2)

final_demo <- demographics |>
  mutate(prolific_id = as.character(prolific_id)) |>
  filter(prolific_id %in% step12$after_quiz_errors_pids)

n_female <- sum(final_demo$sex == "Female", na.rm = TRUE)
n_male   <- sum(final_demo$sex == "Male", na.rm = TRUE)
age_mean <- round(mean(final_demo$age, na.rm = TRUE), 1)
age_sd   <- round(sd(final_demo$age, na.rm = TRUE), 1)
age_min  <- min(final_demo$age, na.rm = TRUE)
age_max  <- max(final_demo$age, na.rm = TRUE)

participants_people <- function(n) {
  if (n == 1) "1 participant" else paste0(n, " participants")
}

n_other <- n_final - n_female - n_male

other_text <- if (n_other > 0) {
  paste0(", ", n_other, " preferred not to disclose")
} else {
  ""
}

residence_top <- final_demo |>
  count(country_of_residence, sort = TRUE) |>
  slice_head(n = 3) |>
  mutate(pct = round(100 * n / n_final, 1))

residence_text <- paste0(
  "Most participants resided in ", residence_top$country_of_residence[1],
  " (", residence_top$pct[1], "%), followed by ",
  residence_top$country_of_residence[2], " (", residence_top$pct[2], "%) and ",
  residence_top$country_of_residence[3], " (", residence_top$pct[3], "%)."
)

pct_of_final <- function(n) paste0(round(100 * n / n_final, 1), "%")
pct_where    <- function(x) pct_of_final(sum(x, na.rm = TRUE))

ethnicity_top <- final_demo |>
  count(ethnicity, sort = TRUE) |>
  slice_head(n = 3) |>
  mutate(text = paste0(ethnicity, " (", pct_of_final(n), ")"))

ethnicity_text <- paste0(
  "Participants identified as ", ethnicity_top$text[1], ", ",
  ethnicity_top$text[2], ", or ", ethnicity_top$text[3], ", among others."
)

education_text <- paste0(
  "Educationally, ", pct_where(final_demo$education %in% c("Bachelor's degree", "Master's degree", "Doctoral degree")),
  " held at least a bachelor's degree, and ",
  pct_where(final_demo$student == "Yes"), " were currently students."
)

employment_text <- paste0(
  "Regarding employment, ",
  pct_where(final_demo$employment_status == "Employed full time"), " worked full time, ",
  pct_where(final_demo$employment_status == "Employed part time"), " part time, ",
  pct_where(grepl("^Unemployed", final_demo$employment_status)), " were unemployed, and ",
  pct_where(final_demo$employment_status == "Retired"), " were retired."
)

clinical_text <- paste0(
  "Clinically, ", pct_where(final_demo$depression_diagnosis == "Yes"),
  " reported a prior diagnosis of depression; ",
  pct_where(final_demo$medication == "Yes, currently"),
  " reported currently taking prescribed medication for depression and ",
  pct_where(final_demo$medication == "Yes, in the past (but not currently)"),
  " reported having done so in the past."
)

marital_text <- paste0(
  "In terms of marital status, ",
  pct_where(final_demo$marital_status == "Married"), " were married, ",
  pct_where(final_demo$marital_status == "single, never married"), " were single (never married), and ",
  pct_where(final_demo$marital_status %in% c("Divorced", "Separated", "Widowed")),
  " were divorced, separated, or widowed."
)

hand_text <- paste0(
  "As for handedness, ", pct_where(final_demo$hand == "Right"), " were right-handed, ",
  pct_where(final_demo$hand == "Left"), " left-handed, and ",
  pct_where(final_demo$hand == "Ambidextrous"), " ambidextrous."
)

ladder_text <- paste0(
  "Mean subjective social status, measured with the MacArthur ladder, was ",
  round(mean(final_demo$ladder_rung, na.rm = TRUE), 2), " (*SD* = ",
  round(sd(final_demo$ladder_rung, na.rm = TRUE), 2), ")."
)

participants_excerpt <- paste0(
  "**Participants.** ", n_recruited,
  " adults recruited via Prolific began the study. Of these, ", n_final,
  " participants (", n_female, " women, ", n_male, " men", other_text,
  "; *M*<sub>age</sub> = ", age_mean, " years, *SD* = ", age_sd,
  ", range = ", age_min, "–", age_max, ") met our inclusion criteria and ",
  "constituted the final sample; the exclusion criteria are detailed in the ",
  "Data Treatment section. ", residence_text, " ", ethnicity_text, " ",
  education_text, " ", employment_text, " ", marital_text, " ", hand_text, " ", ladder_text, " ",
  clinical_text
)

trials_text <- if (n_trials_out > 0) {
  paste0(
    "Trials with a missing response time or choice were omitted (",
    format(n_trials_out, big.mark = ","), " trials, ", pct_trials_out,
    "% of the remaining trials). "
  )
} else {
  "No trials had a missing response time or choice. "
}

data_treatment_excerpt <- paste0(
  "**Data treatment.** Of the ", n_recruited, " participants who began the study, ",
  n_missing, " did not complete both sessions and were excluded. Among the ",
  "remaining participants, we excluded ", n_window,
  " who left the study window more than ", window_exit_max,
  " times, or for more than ", max_window_left_ms / 1000,
  " seconds in total, during the PHQ-9 or the CBCU task in either session, and ",
  n_quiz, " who made more than ", quiz_error_max,
  " errors on the task quiz in either session. ",
  trials_text,
  "No exclusion was based on response times, which were examined only ",
  "descriptively. The final dataset comprised ",
  format(n_final_trials, big.mark = ","), " CBCU trials from ", n_final,
  " participants (", mean_trials, " trials per participant on average)."
)

writeLines(
  c("# Participants", "", participants_excerpt),
  file.path(output_processed_dir, "15_participants_excerpt.md")
)
writeLines(
  c("# Data treatment", "", data_treatment_excerpt),
  file.path(output_processed_dir, "15_data_treatment_excerpt.md")
)
