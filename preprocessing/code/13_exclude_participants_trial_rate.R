# reads: artifacts/12_after_rt_bounds.rds
# writes: artifacts/13_after_trial_rate.rds, output/processed/exclusion.md

#### EXCLUDE PARTICIPANTS: TOO MANY TRIALS EXCLUDED IN EITHER SESSION ####

if (!exists("max_trial_exclusion_pct")) max_trial_exclusion_pct <- 15

step12 <- readRDS(file.path(artifacts_dir, "12_after_rt_bounds.rds"))

after_window_exits_pids <- step12$after_window_exits_pids
after_window_cbcu       <- step12$after_window_cbcu
after_rt_bounds         <- step12$after_rt_bounds
exclusion_report_lines  <- step12$exclusion_report_lines

n_before <- after_window_cbcu |>
  count(prolific_id, time, name = "n_before")

n_after <- after_rt_bounds |>
  count(prolific_id, time, name = "n_after")

session_trial_rate <- n_before |>
  left_join(n_after, by = c("prolific_id", "time")) |>
  mutate(
    n_after              = coalesce(n_after, 0L),
    pct_trials_excluded  = 100 * (n_before - n_after) / n_before
  )

high_trial_rate_details <- session_trial_rate |>
  filter(pct_trials_excluded > max_trial_exclusion_pct) |>
  distinct(prolific_id)

after_trial_rate_pids <- setdiff(
  after_window_exits_pids,
  high_trial_rate_details$prolific_id
)

after_trial_rate_cbcu <- after_rt_bounds |>
  filter(prolific_id %in% after_trial_rate_pids)

n_started  <- length(after_window_exits_pids)
n_excluded <- n_started - length(after_trial_rate_pids)
n_left     <- length(after_trial_rate_pids)

trial_rate_criterion_text <- paste0(
  "Trial exclusion took more than ",
  max_trial_exclusion_pct,
  "% of trials on either time1 or time2"
)

exclusion_report_lines <- c(
  exclusion_report_lines,
  paste0(
    "4. ", trial_rate_criterion_text, ". Started with ", n_started,
    " participants, excluded ", n_excluded, ", ", n_left, " left."
  )
)

writeLines(exclusion_report_lines, file.path(output_processed_dir, "exclusion.md"))

saveRDS(
  list(
    after_window_exits_pids    = after_window_exits_pids,
    after_trial_rate_pids      = after_trial_rate_pids,
    after_trial_rate_cbcu      = after_trial_rate_cbcu,
    session_trial_rate         = session_trial_rate,
    high_trial_rate_details    = high_trial_rate_details,
    trial_rate_criterion_text  = trial_rate_criterion_text,
    exclusion_report_lines     = exclusion_report_lines
  ),
  file.path(artifacts_dir, "13_after_trial_rate.rds")
)
