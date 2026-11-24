#### PREP CLINICAL REPORT: SEVERITY, SIGMA, BURDEN THRESHOLD ####
# reads: objects from prep_clinical_report.R; sigma_draws (from summarise_posterior.R,
#        or artifacts/sigma_draws_by_wave.rds)
# writes: output/clinical reports/clinical_report_summary.csv
# Adapted from analysis/beta_tau_halfnormal_stz/code/prep_clinical_report_summaries.R
#
# Discriminability is sigma, the SD of the patient's utilities (higher = utilities further
# apart = symptoms easier to tell apart), in place of the beta report's
# P(higher option | not None). Posterior median and 95% HDCI, as in plot_test_retest.R.
# The gauge's axis is shared by all patients: from 0 (sigma's lower bound) to 20% of the
# range past the largest upper HDCI end among all time 1 participants (the PI's full-range
# rule), with the sample median of the participants' posterior medians as a reference mark.

sigma_interval_width <- 0.95

severity_bands <- tibble(
  band  = c("Minimal", "Mild", "Moderate", "Moderately severe", "Severe"),
  lower = c(0, 5, 10, 15, 20),
  upper = c(4, 9, 14, 19, 27))

df_severity <- df_phq9_time1 |>
  mutate(band = severity_bands$band[findInterval(phq9_sum, severity_bands$lower)]) |>
  select(prolific_id, phq9_sum, band)

# sigma for every time 1 participant (draws x prolific_id), for the shared gauge axis
if (!exists("sigma_draws")) sigma_draws <- readRDS(file.path(artifacts_dir, "sigma_draws_by_wave.rds"))
sigma_mat_time1 <- sigma_draws$time1

df_sigma_all <- tibble(
  prolific_id = colnames(sigma_mat_time1),
  sigma       = apply(sigma_mat_time1, 2, median),
  interval    = map(seq_len(ncol(sigma_mat_time1)),
                    \(k) hdci(sigma_mat_time1[, k], .width = sigma_interval_width))) |>
  mutate(sigma_lo = map_dbl(interval, \(m) m[1, 1]),
         sigma_hi = map_dbl(interval, \(m) m[1, 2])) |>
  select(-interval)

sigma_axis_max      <- 1.2 * max(df_sigma_all$sigma_hi)
sigma_sample_median <- median(df_sigma_all$sigma)

df_sigma <- filter(df_sigma_all, prolific_id %in% df_patients$prolific_id)

df_skip_counts <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE) |>
  filter(time == "time1", prolific_id %in% df_patients$prolific_id) |>
  group_by(prolific_id) |>
  summarise(n_skip = sum(choice == "skip"), n_trials = n(), .groups = "drop")

# How many symptoms clear the burden threshold, counted per draw (summary CSV only)
df_threshold <- pmap(df_subjects, \(prolific_id, subject_index) {
  U         <- u_draws[, sprintf("u_matrix[%d,%d]", subject_index, seq_len(n_items))]
  tau_s     <- tau_draws[, sprintf("tau[%d]", subject_index)]
  cnt_draws <- rowSums(U > tau_s)
  # type = 1 keeps counts on whole numbers rather than e.g. "8.5 of 15"
  tibble(prolific_id = prolific_id,
         thr         = median(tau_s),
         n_above     = unname(quantile(cnt_draws, 0.50, type = 1)),
         n_above_lo  = unname(quantile(cnt_draws, 0.05, type = 1)),
         n_above_hi  = unname(quantile(cnt_draws, 0.95, type = 1)))
}) |>
  list_rbind() |>
  left_join(df_skip_counts, by = "prolific_id") |>
  mutate(never_skipped = n_skip == 0)

df_p_none <- df_ladder |>
  filter(item == none_item) |>
  select(prolific_id, p_none = p, p_none_lo = .lower, p_none_hi = .upper)

df_report <- df_patients |>
  select(-phq9_sum) |>                      # same value comes back with df_severity
  left_join(df_severity, by = "prolific_id") |>
  left_join(df_sigma, by = "prolific_id") |>
  left_join(df_threshold, by = "prolific_id") |>
  left_join(df_p_none, by = "prolific_id")

write_csv(df_report, file.path(output_clinical_dir, "clinical_report_summary.csv"))
