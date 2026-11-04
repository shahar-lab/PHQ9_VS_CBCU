# reads: artifacts/12_after_rt_bounds.rds, data/raw/cbcu_quizz.csv
# writes: data/processed/quiz_errors.csv

#### WRITE PROCESSED QUIZ ERRORS (SURVIVING PARTICIPANTS ONLY) ####

# Participants with too many quiz errors are already excluded in step 11b; this writes
# the counts for the survivors. An error is a quiz attempt with correct == FALSE; every wrong attempt counts,
# including repeated attempts on the same question. Participants with no wrong attempt
# get 0.
step12      <- readRDS(file.path(artifacts_dir, "12_after_rt_bounds.rds"))
cbcu_quizz  <- read_csv(file.path(raw_dir, "cbcu_quizz.csv"), show_col_types = FALSE)

quiz_errors <- cbcu_quizz |>
  mutate(prolific_id = as.character(prolific_id)) |>
  filter(prolific_id %in% step12$after_quiz_errors_pids) |>
  group_by(prolific_id, time) |>
  summarise(n_errors = sum(!correct, na.rm = TRUE), .groups = "drop") |>
  complete(prolific_id = step12$after_quiz_errors_pids, time = c("time1", "time2"),
           fill = list(n_errors = 0)) |>
  pivot_wider(names_from = time, values_from = n_errors, names_prefix = "quiz_errors_") |>
  mutate(quiz_errors_total = quiz_errors_time1 + quiz_errors_time2)

write_csv(quiz_errors, file.path(processed_dir, "quiz_errors.csv"), na = "NA")
