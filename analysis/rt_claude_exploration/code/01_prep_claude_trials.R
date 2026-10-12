#### CLEAN CLAUDE'S RAW SESSIONS ####
# reads: analysis/rt_claude_exploration/PHQ9_pairwise_*.csv · writes: artifacts/df_claude_trials.rds, cleaning_summary.rds

# One file per Claude run; file names carry the date, so alphabetical order is chronological
claude_files <- sort(list.files(claude_dir, pattern = "^PHQ9_pairwise_.*csv$", full.names = TRUE))
stopifnot(length(claude_files) >= 1)

df_claude     <- tibble()
cleaning_runs <- tibble()

for (run in seq_along(claude_files)) {
  df_raw <- read_csv(claude_files[run], col_types = cols(.default = col_character()))
  cat("Claude run", run, "- raw rows:", nrow(df_raw), "\n")
  print(table(df_raw$trial_type, df_raw$phase, useNA = "ifany"))

  df_row_types <- df_raw |>
    count(trial_type, phase) |>
    mutate(
      phase = replace_na(phase, "(none)"),
      kept  = trial_type == "html-button-response" & phase == "pairwise"
    )

  # Keep only the choice rows; ITI, instruction, quiz, break, PHQ-9, text and system rows are dropped
  df <- df_raw |>
    filter(trial_type == "html-button-response", phase == "pairwise") |>
    transmute(
      trial       = as.integer(phase_trial_num),
      left_item   = left_item_number,
      right_item  = right_item_number,
      choice      = chosen_side,
      raw_chosen  = chosen_item_number,
      rt          = as.numeric(rt_from_stim_ms),
      skipped     = skipped == "true",
      window_status
    ) |>
    arrange(trial)

  stopifnot(
    nrow(df) == n_trials_expected,
    identical(df$trial, seq_len(n_trials_expected)),
    !anyDuplicated(paste(pmin(df$left_item, df$right_item), pmax(df$left_item, df$right_item))),
    !anyNA(df$rt),
    all(df$window_status == "ok"),
    all(df$choice %in% c("left", "right", "skip")),
    all(df$left_item %in% phq9_item_order),
    all(df$right_item %in% phq9_item_order),
    all((df$choice == "skip") == df$skipped)
  )

  df <- df |>
    mutate(chosen_item = case_when(
      choice == "left"  ~ left_item,
      choice == "right" ~ right_item,
      .default = NA_character_
    ))

  # The item named in the raw file must be the one on the chosen side
  stopifnot(all(df$chosen_item == df$raw_chosen | (is.na(df$chosen_item) & is.na(df$raw_chosen))))

  df_claude <- bind_rows(df_claude, df |>
    mutate(agent = "Claude", unit = paste0("Claude_run", run)))
  cleaning_runs <- bind_rows(cleaning_runs, tibble(
    run = run, file = basename(claude_files[run]), n_raw = nrow(df_raw),
    n_kept = nrow(df), row_types = list(df_row_types)
  ))
}

df_claude <- df_claude |>
  select(agent, unit, trial, left_item, right_item, choice, chosen_item, rt, skipped)

saveRDS(df_claude, file.path(artifacts_dir, "df_claude_trials.rds"))
saveRDS(cleaning_runs, file.path(artifacts_dir, "cleaning_summary.rds"))
