#### PREP CLINICAL REPORT: LADDER (TIME 1) ####
# reads: artifacts/profile_patients.csv, artifacts/discriminability_pairs.csv,
#        artifacts/subject_lookup_time1.csv,
#        fit_list$time1 (or artifacts/fit_time1.rds), data/processed/cbcu.csv, phq.csv
# Adapted from PHQ9_pairwise_pilot/analysis/beta_tau_pairwise/code/prep_clinical_report.R
#
# For each picked patient: the 15 items ordered by utility (posterior median, 90% HDCI),
# split into tiers wherever the next item down is lower with probability >= tier_threshold,
# and each item's time 1 PHQ-9 answer (0-3) for the PHQ-9 item it belongs to.

tier_threshold    <- 0.90
n_items           <- 15
profiles_excluded <- 1   # profile 1 left out of the article figures (the user's choice)

# Profile patients are numbered 1, 2, ... in order of their PHQ-9 sum score. The
# discriminability pairs (select_discriminability_pairs.R) are added with no patient
# number and their own pair / discriminability columns; a subject in both sets has two rows.
df_patients <- bind_rows(
  read_csv(file.path(artifacts_dir, "profile_patients.csv"), show_col_types = FALSE) |>
    filter(!profile %in% profiles_excluded) |>
    arrange(phq9_sum) |>
    mutate(patient = row_number()),
  read_csv(file.path(artifacts_dir, "discriminability_pairs.csv"), show_col_types = FALSE) |>
    select(prolific_id, phq9_sum, pair, discriminability)) |>
  left_join(read_csv(file.path(artifacts_dir, "subject_lookup_time1.csv"), show_col_types = FALSE),
            by = "prolific_id")

# Ladders and thresholds are built once per subject
df_subjects <- distinct(df_patients, prolific_id, subject_index)

fit_time1 <- if (exists("fit_list")) fit_list$time1 else readRDS(file.path(artifacts_dir, "fit_time1.rds"))

# Draws for the picked subjects only
u_vars    <- as.vector(outer(df_subjects$subject_index, seq_len(n_items),
                             \(s, i) sprintf("u_matrix[%d,%d]", s, i)))
u_draws   <- unclass(fit_time1$draws(u_vars, format = "draws_matrix"))
tau_draws <- unclass(fit_time1$draws(sprintf("tau[%d]", df_subjects$subject_index), format = "draws_matrix"))

df_item_short <- tribble(
  ~item, ~item_short,
  1,  "Little interest",   2,  "Feeling down",      3,  "Hopeless",
  4,  "Insomnia",          5,  "Oversleeping",      6,  "Fatigue",
  7,  "Poor appetite",     8,  "Overeating",        9,  "Bad about self",
  10, "Let self/family down", 11, "Concentration",  12, "Slowed down",
  13, "Restless",          14, "Better off dead",   15, "Thoughts of self-harm"
)

df_items <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE) |>
  distinct(item = item_number_left, phq9_code = item_phq9_left) |>
  mutate(phq9_item = paste0("phq9_", str_extract(phq9_code, "^\\d"))) |>
  left_join(df_item_short, by = "item")

df_phq9_time1 <- read_csv(file.path(data_path, "phq.csv"), show_col_types = FALSE) |>
  filter(time == "time1", prolific_id %in% df_patients$prolific_id)

df_phq9_answers <- df_phq9_time1 |>
  pivot_longer(phq9_1:phq9_9, names_to = "phq9_item", values_to = "phq9_answer") |>
  select(prolific_id, phq9_item, phq9_answer)

df_ladder <- pmap(df_subjects, \(prolific_id, subject_index) {
  U      <- u_draws[, sprintf("u_matrix[%d,%d]", subject_index, seq_len(n_items))]
  ord    <- order(apply(U, 2, median), decreasing = TRUE)
  p_next <- map_dbl(seq_len(n_items - 1), \(k) mean(U[, ord[k]] > U[, ord[k + 1]]))
  interval <- map(ord, \(i) hdci(U[, i], .width = 0.90))
  tibble(prolific_id = prolific_id,
         item        = ord,
         position    = seq_len(n_items),
         u           = apply(U[, ord], 2, median),
         .lower      = map_dbl(interval, \(m) m[1, 1]),
         .upper      = map_dbl(interval, \(m) m[1, 2]),
         tier        = cumsum(c(1, as.integer(p_next >= tier_threshold))))
}) |>
  list_rbind() |>
  left_join(df_items, by = "item") |>
  left_join(df_phq9_answers, by = c("prolific_id", "phq9_item"))
