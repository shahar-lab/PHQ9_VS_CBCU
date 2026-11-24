#### PREP CLINICAL REPORT: P(BOTHERS MOST) LADDER (TIME 1) ####
# reads: analysis/beta_tau_halfnormal_stz/artifacts/profile_patients.csv and
#        discriminability_pairs.csv (same patients and pairs as the beta report, the user's choice),
#        artifacts/subject_lookup_time1.csv, fit_list$time1 (or artifacts/fit_time1.rds),
#        data/processed/cbcu.csv, phq.csv
# Adapted from analysis/beta_tau_halfnormal_stz/code/prep_clinical_report.R
#
# For each picked patient, all 15 symptoms and None ("Neither"), ordered by the probability
# that each one bothers the patient most. Per posterior draw:
#   - the symptoms whose utility is above the burden threshold tau (= u[None]) are kept,
#   - a softmax is taken over those symptoms plus None itself (the user's choice), so
#       P(symptom i) = exp(u_i) / (exp(tau) + sum over kept j of exp(u_j))   if u_i > tau, else 0
#       P(None)      = exp(tau) / (exp(tau) + sum over kept j of exp(u_j))
#     (a draw where no symptom clears tau gives P(None) = 1).
# The draws of each probability are then summarised by their posterior mean (the user's
# choice: the median of a symptom above tau in < half the draws is exactly 0) and 90% HDCI.
# No tiers (the user's choice).

n_items           <- 15
interval_width    <- 0.90
profiles_excluded <- 1   # profile 1 left out of the article figures (as in the beta report)
none_item         <- n_items + 1
none_label        <- "Neither"

beta_artifacts_dir <- file.path(project_root, "analysis", "beta_tau_halfnormal_stz", "artifacts")

# Profile patients are numbered 1, 2, ... in order of their PHQ-9 sum score (same numbers as
# the beta report). The discriminability pairs are added with no patient number and their own
# pair / discriminability columns; a subject in both sets has two rows. The pairs' "high" and
# "low" labels are the beta model's discriminability (P(higher option | not None)).
df_patients <- bind_rows(
  read_csv(file.path(beta_artifacts_dir, "profile_patients.csv"), show_col_types = FALSE) |>
    filter(!profile %in% profiles_excluded) |>
    arrange(phq9_sum) |>
    mutate(patient = row_number()),
  read_csv(file.path(beta_artifacts_dir, "discriminability_pairs.csv"), show_col_types = FALSE) |>
    select(prolific_id, phq9_sum, pair, contrast, shared_bar, discriminability)) |>
  left_join(read_csv(file.path(artifacts_dir, "subject_lookup_time1.csv"), show_col_types = FALSE),
            by = "prolific_id")

stopifnot(!anyNA(df_patients$subject_index))   # every picked patient was fitted at time 1

# Ladders are built once per subject
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
  13, "Restless",          14, "Better off dead",   15, "Thoughts of self-harm",
  none_item, none_label
)

df_items <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE) |>
  distinct(item = item_number_left, phq9_code = item_phq9_left) |>
  mutate(phq9_item = paste0("phq9_", str_extract(phq9_code, "^\\d"))) |>
  right_join(df_item_short, by = "item")   # None has no PHQ-9 item (NA)

df_phq9_time1 <- read_csv(file.path(data_path, "phq.csv"), show_col_types = FALSE) |>
  filter(time == "time1", prolific_id %in% df_patients$prolific_id)

df_phq9_answers <- df_phq9_time1 |>
  pivot_longer(phq9_1:phq9_9, names_to = "phq9_item", values_to = "phq9_answer") |>
  select(prolific_id, phq9_item, phq9_answer)

# draws x 16 matrix of P(bothers most): columns 1-15 the symptoms, 16 None.
# Exponents are shifted by each draw's largest utility (U or tau) to avoid overflow;
# the shift cancels in the ratio.
p_bothers_most <- function(U, tau_s) {
  above  <- U > tau_s                          # tau_s (one value per draw) is compared with each row
  shift  <- pmax(apply(U, 1, max), tau_s)
  w      <- exp(U - shift) * above             # symptoms below tau get weight 0
  w_none <- exp(tau_s - shift)
  cbind(w, w_none) / (rowSums(w) + w_none)
}

df_ladder <- pmap(df_subjects, \(prolific_id, subject_index) {
  U     <- u_draws[, sprintf("u_matrix[%d,%d]", subject_index, seq_len(n_items))]
  tau_s <- tau_draws[, sprintf("tau[%d]", subject_index)]
  P     <- p_bothers_most(U, tau_s)
  p_mean   <- colMeans(P)
  ord      <- order(p_mean, decreasing = TRUE)
  interval <- map(ord, \(i) hdci(P[, i], .width = interval_width))
  tibble(prolific_id = prolific_id,
         item        = ord,
         position    = seq_len(none_item),
         p           = p_mean[ord],
         .lower      = map_dbl(interval, \(m) m[1, 1]),
         .upper      = map_dbl(interval, \(m) m[1, 2]),
         # share of draws in which the option enters the softmax (None always does)
         p_above_threshold = c(colMeans(U > tau_s), 1)[ord])
}) |>
  list_rbind() |>
  left_join(df_items, by = "item") |>
  left_join(df_phq9_answers, by = c("prolific_id", "phq9_item"))
