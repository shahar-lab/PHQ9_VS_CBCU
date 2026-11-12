#### PREP CHOICE SHARES AND STAY RATES ####
# reads: data/processed/cbcu.csv · writes: artifacts/choice_stay_rates.csv
# Per participant and session (A = left, B = right, neither = skip):
#   share_a, share_b, share_neither = proportion of all trials with that choice
#   stay_neither = of the trials with neither, share followed by neither on the next trial
#   stay_a       = of the trials with A, share followed by A
#   stay_b       = of the trials with B, share followed by B
#   stay_key     = of the trials with A or B, share followed by A or B (A -> B counts as staying)
# "Next trial" is within block: the last trial of a block has no next trial and is not
# counted in the stay rates. A stay rate is NA when the participant never made that choice
# on a trial with a next trial.

stay_rate <- function(choice, next_choice, from, to) {
  keep <- choice %in% from & !is.na(next_choice)
  if (!any(keep)) return(NA_real_)
  mean(next_choice[keep] %in% to)
}

df_choice_stay_rates <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE) |>
  arrange(prolific_id, time, block, trial) |>
  group_by(prolific_id, time, block) |>
  mutate(next_choice = lead(choice)) |>
  group_by(prolific_id, time) |>
  summarise(
    share_a       = mean(choice == "left"),
    share_b       = mean(choice == "right"),
    share_neither = mean(choice == "skip"),
    stay_neither  = stay_rate(choice, next_choice, "skip", "skip"),
    stay_a        = stay_rate(choice, next_choice, "left", "left"),
    stay_b        = stay_rate(choice, next_choice, "right", "right"),
    stay_key      = stay_rate(choice, next_choice, c("left", "right"), c("left", "right")),
    .groups = "drop"
  )

write_csv(df_choice_stay_rates, file.path(artifacts_dir, "choice_stay_rates.csv"))
