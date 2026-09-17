# reads: data/raw/cbcu_results.csv, data/raw/phq9_results.csv, artifacts/time_levels.rds · writes: artifacts/08_raw_participant_review.rds

#### REVIEW RAW PARTICIPANT EXCLUSIONS ####

cbcu_results <- read_csv(file.path(raw_dir, "cbcu_results.csv"), show_col_types = FALSE)
phq9_results <- read_csv(file.path(raw_dir, "phq9_results.csv"), show_col_types = FALSE)
time_levels  <- readRDS(file.path(artifacts_dir, "time_levels.rds"))

phq_item_cols <- paste0("phq9_", seq_len(required_phq_responses))

all_review_pids <- union(
  as.character(cbcu_results$prolific_id),
  as.character(phq9_results$prolific_id)
)

participant_session_grid <- tidyr::expand_grid(
  prolific_id = all_review_pids,
  time = time_levels
)

cbcu_session_counts <- cbcu_results |>
  dplyr::mutate(prolific_id = as.character(prolific_id),
                time = as.character(time)) |>
  dplyr::count(prolific_id, time, name = "n_cbcu_trials")

phq_session_counts <- phq9_results |>
  dplyr::mutate(
    prolific_id = as.character(prolific_id),
    time = as.character(time),
    n_phq_responses = rowSums(!is.na(dplyr::pick(dplyr::all_of(phq_item_cols))))
  ) |>
  dplyr::group_by(prolific_id, time) |>
  dplyr::summarise(n_phq_responses = max(n_phq_responses), .groups = "drop")

participant_completeness <- participant_session_grid |>
  dplyr::left_join(cbcu_session_counts, by = c("prolific_id", "time")) |>
  dplyr::left_join(phq_session_counts, by = c("prolific_id", "time")) |>
  dplyr::mutate(
    n_cbcu_trials = dplyr::coalesce(n_cbcu_trials, 0L),
    n_phq_responses = dplyr::coalesce(n_phq_responses, 0)
  )

incomplete_participant_details <- participant_completeness |>
  dplyr::filter(
    n_cbcu_trials != expected_cbcu_trials |
      n_phq_responses != required_phq_responses
  ) |>
  dplyr::mutate(
    session_detail = paste0(
      time, " (", n_cbcu_trials, " CBCU trials; ",
      n_phq_responses, "/", required_phq_responses, " PHQ responses)"
    )
  ) |>
  dplyr::group_by(prolific_id) |>
  dplyr::summarise(
    reason = paste0("Incomplete required data: ",
                    paste(session_detail, collapse = "; ")),
    .groups = "drop"
  )

complete_review_pids <- setdiff(
  all_review_pids,
  incomplete_participant_details$prolific_id
)

saveRDS(
  list(
    all_review_pids = all_review_pids,
    incomplete_participant_details = incomplete_participant_details,
    complete_review_pids = complete_review_pids
  ),
  file.path(artifacts_dir, "08_raw_participant_review.rds")
)
