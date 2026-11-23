#### PREP CLINICAL REPORT: SEVERITY, CONSISTENCY, BURDEN THRESHOLD, HEADER ####
# reads: objects from prep_clinical_report.R, artifacts/p_higher_option.csv
# writes: output/clinical reports/clinical_report_summary.csv
#
# Burden threshold: in this model None beats an item when beta * u < beta * tau, i.e.
# when u < tau, so tau itself is the threshold on the ladder's utility scale (in the pilot
# model it was tau / beta). Utilities sum to zero, so 0 is the patient's average symptom.
# How many items clear the bar is counted per posterior draw.

severity_bands <- tibble(
  band  = c("Minimal", "Mild", "Moderate", "Moderately severe", "Severe"),
  lower = c(0, 5, 10, 15, 20),
  upper = c(4, 9, 14, 19, 27))

df_severity <- df_phq9_time1 |>
  mutate(band = severity_bands$band[findInterval(phq9_sum, severity_bands$lower)]) |>
  select(prolific_id, phq9_sum, band)

# Consistency: time 1 P(higher-utility option | not None), from plot_p_higher_test_retest.R
p_higher_path <- file.path(artifacts_dir, "p_higher_option.csv")
if (!file.exists(p_higher_path) ||
    file.mtime(p_higher_path) < file.mtime(file.path(artifacts_dir, "fit_time1.rds"))) {
  stop("artifacts/p_higher_option.csv is missing or older than the fit: run plot_p_higher_test_retest.R first")
}
df_consistency <- read_csv(p_higher_path, show_col_types = FALSE) |>
  filter(time == "time1", prolific_id %in% df_patients$prolific_id) |>
  transmute(prolific_id, consistency = p_higher, cons_lo = p_higher_lower, cons_hi = p_higher_upper,
            cons_verdict = case_when(
              consistency < 0.70 ~ "low - choices near random; rely on severity score and interview",
              consistency < 0.85 ~ "moderate - broad tiers informative, exact positions less so",
              TRUE               ~ "high - ordering can be discussed with confidence"))

df_skip_counts <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE) |>
  filter(time == "time1", prolific_id %in% df_patients$prolific_id) |>
  group_by(prolific_id) |>
  summarise(n_skip = sum(choice == "skip"), n_trials = n(), .groups = "drop")

df_threshold <- pmap(df_subjects, \(prolific_id, subject_index) {
  U         <- u_draws[, sprintf("u_matrix[%d,%d]", subject_index, seq_len(n_items))]
  tau_s     <- tau_draws[, sprintf("tau[%d]", subject_index)]
  cnt_draws <- rowSums(U > tau_s)   # tau_s (one value per draw) is compared with each row
  # type = 1 keeps counts on whole numbers rather than e.g. "8.5 of 15"
  tibble(prolific_id = prolific_id,
         thr         = median(tau_s),
         thr_lo      = unname(quantile(tau_s, 0.05)),
         thr_hi      = unname(quantile(tau_s, 0.95)),
         n_above     = unname(quantile(cnt_draws, 0.50, type = 1)),
         n_above_lo  = unname(quantile(cnt_draws, 0.05, type = 1)),
         n_above_hi  = unname(quantile(cnt_draws, 0.95, type = 1)),
         n_at_median = unname(quantile(rowSums(U > 0), 0.50, type = 1)))
}) |>
  list_rbind() |>
  left_join(df_skip_counts, by = "prolific_id") |>
  mutate(never_skipped = n_skip == 0,
         thr_verdict = case_when(
           never_skipped ~ "never declined a pair - bar sits below every symptom, lower bound only",
           n_above >= 13 ~ "permissive - nearly every symptom clears the bar",
           n_above >= 8  ~ "balanced - concern reaches past their average symptom",
           n_above >= 4  ~ "selective - only the most burdensome symptoms clear the bar",
           TRUE          ~ "highly selective - concern confined to a few symptoms"))

df_report <- df_patients |>
  select(-phq9_sum) |>                      # same value comes back with df_severity
  left_join(df_severity, by = "prolific_id") |>
  left_join(df_consistency, by = "prolific_id") |>
  left_join(df_threshold, by = "prolific_id") |>
  mutate(header_text = paste0(
    "Participant ", prolific_id, "   (",
    case_when(
      !is.na(pair) ~ paste0(discriminability, " discriminability, ", pair, " PHQ-9 pair"),
      is.na(matches_profile) ~
        paste0("profile ", profile, " of ", sum(!is.na(df_patients$profile) & is.na(df_patients$matches_profile)),
               ": typical of ", cluster_size, " subjects"),
      TRUE ~ sprintf("higher-severity match to profile %d: rank correlation r = %.2f",
                     matches_profile, spearman_r_to_match)),
    ")\n\n",
    "PHQ-9 sum score: ", phq9_sum, " / 27  -  ", toupper(band), "\n",
    "Choice consistency: ", sprintf("%.0f%%", consistency * 100), " - ", cons_verdict, "\n",
    "Burden threshold: ", n_above, " of ", n_items, " symptoms clear it [", n_above_lo, "-",
    n_above_hi, "] - ", thr_verdict))

write_csv(select(df_report, -header_text), file.path(output_clinical_dir, "clinical_report_summary.csv"))
