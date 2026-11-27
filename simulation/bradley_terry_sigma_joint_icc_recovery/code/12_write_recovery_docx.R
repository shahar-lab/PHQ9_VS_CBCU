#### WRITE RECOVERY REPORT (WORD) ####
# reads:  artifacts/convergence_table.rds, recovery_population.rds; output/09_icc_recovery.csv,
#         output/10_individual_recovery.csv; output/07-10 figure PNGs
# writes: output/12_recovery_report.docx

convergence_table   <- readRDS(file.path(artifacts_dir, "convergence_table.rds"))
recovery_population <- readRDS(file.path(artifacts_dir, "recovery_population.rds"))
icc_recovery_table  <- read_csv(file.path(output_dir, "09_icc_recovery.csv"), show_col_types = FALSE) |>
  select(-run_label)
individual_table    <- read_csv(file.path(output_dir, "10_individual_recovery.csv"), show_col_types = FALSE)

population_table <- recovery_population |>
  filter(parameter %in% c("mu_log_sigma", "s_log_sigma", "delta_log_sigma")) |>
  select(run, parameter, true_value, median, lower, upper, covered)

round_table <- function(df) flextable(mutate(df, across(where(is.double), \(x) round(x, 3)))) |> autofit()

design_text <- sprintf(paste(
  "We simulated %d participants, each completing %d sessions of %d trials (every pair of the %d items",
  "once per session, in random order and sides). log(sigma) was drawn as %.2f + c*%.2f + %.2f*(sqrt(ICC)*z + sqrt(1-ICC)*e),",
  "with session code c = -1/2, +1/2 and z, e ~ Normal(0, 1). The 15 item utilities shared one consistency ICC",
  "(the profile ICC of Hypothesis 1) and None (tau) had its own. Three runs crossed the true consistency ICCs:",
  "sigma %s; items %s; tau %s. Item means were drawn from Normal(0, %.1f) and centred, with the None mean",
  "fixed at %.1f (about 27%% None choices, as in the real data); session shifts were drawn from Normal(0, %.1f)",
  "and centred. Agreement ICCs were derived from the consistency ICCs and the session shifts (McGraw & Wong",
  "ICC(A,1)); the item-profile agreement ICC is Hypothesis 1, eq. [2]. No logistic transform was applied."),
  n_subjects, n_sessions, n_trials, n_options, true_mu_log_sigma, true_delta_log_sigma, true_s_log_sigma,
  paste(true_icc_sigma_runs, collapse = ", "), paste(true_icc_profile_runs, collapse = ", "),
  paste(true_icc_tau_runs, collapse = ", "), true_m_sd, true_m_none, true_delta_u_sd)

captions <- c(
  "Population location and scale. (A) Posterior of the mean, the within-session SD and the session shift of log(sigma) per run (90% interval); the blue dotted line marks the true value. (B) Means and session shifts of the 16 utilities: true value against posterior median with 95% interval; the dashed line is identity.",
  "ICC posteriors. Consistency (green) and agreement (red) ICC of sigma, of the 15-item profile (Hypothesis 1; agreement = eq. [2]) and of tau, per run (90% interval). Dotted lines mark the true values.",
  "ICC recovery. True ICC against posterior median with 95% interval, for sigma, the item profile and tau in each of the three runs; the dashed line is identity.",
  "Individual recovery. True value against posterior median per participant-session for sigma, tau and the 15 item utilities; the red line is the OLS fit, the dashed line is identity, and r is Pearson's correlation. True consistency ICCs (sigma, items, tau): Run 1 = 0.5, 0.8, 0.7; Run 2 = 0.7, 0.6, 0.9; Run 3 = 0.9, 0.4, 0.5."
)
figure_files <- c("07_population_location.png", "08_icc_posteriors.png",
                  "09_icc_recovery.png", "10_individual_recovery.png")
figure_dims  <- list(c(6.5, 6.5), c(6.5, 3.8), c(6.5, 3.9), c(6.5, 6.5))

doc <- read_docx() |>
  body_add_par("Parameter recovery: joint two-session sigma model with ICC parameters", style = "heading 1") |>
  body_add_par("Design", style = "heading 2") |>
  body_add_par(design_text) |>
  body_add_par(sprintf("Fitted with Stan (cmdstanr), %d chains, %d warmup and %d sampling iterations each.",
                       n_chains, n_warmup, n_sampling)) |>
  body_add_par("Convergence", style = "heading 2") |>
  body_add_flextable(round_table(convergence_table)) |>
  body_add_par("ICCs: true value, posterior median, 95% interval", style = "heading 2") |>
  body_add_flextable(round_table(icc_recovery_table)) |>
  body_add_par("Population level: log(sigma)", style = "heading 2") |>
  body_add_flextable(round_table(population_table)) |>
  body_add_par("Individual level", style = "heading 2") |>
  body_add_flextable(round_table(individual_table))

for (f in seq_along(figure_files)) {
  doc <- doc |>
    body_add_img(file.path(output_dir, figure_files[f]), width = figure_dims[[f]][1], height = figure_dims[[f]][2]) |>
    body_add_fpar(fpar(ftext(sprintf("Figure %d. ", f), prop = fp_text(italic = TRUE)), ftext(captions[f])))
}

print(doc, target = file.path(output_dir, "12_recovery_report.docx"))
