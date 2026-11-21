# Recovery Notebook: Bradley-Terry Beta Tau (half-normal / truncated-normal beta, sum-to-zero utilities), test-retest

**Generative model:** `models/bradley_terry_beta_tau_halfnormal_stz/bradley_terry_beta_tau_halfnormal_stz.R` (`sim.block()`)
**Fitted model:** `models/bradley_terry_beta_tau_halfnormal_stz/bradley_terry_beta_tau_halfnormal_stz.stan`
**Job-folder:** `simulation/bradley_terry_beta_tau_halfnormal_stz_recovery/`
**Date Created:** 2026-11-20

## 1. Design (set in `main.R`)

* **n_subjects:** 200
* **n_options:** 15
* **n_trials:** 105 per subject per session
* **n_sessions:** 2. Both sessions are generated from the **same** true parameters (a perfectly stable trait), each with its own random offers and choices. The test-retest correlations therefore show only choice noise and estimation error, and are an upper bound on what the real data can show.
* **beta:** normal(location = 4, scale = 1) truncated at 0 (the truncation removes only P = 3e-5)
* **tau:** normal(0, 1)
* **u:** drawn from the model's prior: iid normal(0, sqrt(N / (N - 1))) per subject, centered to sum to zero (marginal SD 1)
* **Sampler:** Stan via cmdstanr, one fit per session; 4 chains, 3000 warmup, 2000 sampling iterations; `init = 0.5`
* **Seed:** none, so each run draws fresh truth

## 2. Pipeline

1. `01_generate_true_parameters.R`: non-centered draws; `beta_raw` from a standard normal truncated below at `-location / scale` (inverse CDF). Artifacts: `true_population.rds`, `true_parameters.rds`, `true_u.rds`.
2. `02_generate_data.R`: `sim.block()` per subject per session. Artifacts: `simulated_data.rds` (includes the true `prob_A/B/None` per trial), `stan_data_list.rds`.
3. `03_fit_model.R`: one fit per session. The full fit is not saved, because `log_lik` (one column per trial) would make it several GB. Artifacts: `draws_session<k>.rds` (hyperparameters, beta, tau, u_matrix), `diagnostic_summary_session<k>.rds`, `hyperparameter_summary_session<k>.rds`.
4. `04_extract_subject_estimates.R`: posterior median per subject per parameter per session, as in the analysis of the real data, plus the true values. Artifact: `participant_parameters.csv/.rds`.
5. `05_compute_choice_prediction.R`: **choice prediction.** For each trial where the participant chose A or B ("None" trials skipped), the model's probability of the option actually chosen, under the 3-way softmax (logits `beta*u[A]`, `beta*u[B]`, `beta*tau`), averaged over posterior draws. Per participant per session it is the mean over those trials. The same mean computed from the true parameters is kept as `true_choice_prediction`. A participant with a high tau can choose None on every trial of a session; they stay in the table with `n_trials_AB = 0` and an NA choice prediction, and are left out of the scatter. A second version, `choice_prediction_all` (and `true_choice_prediction_all`), averages over all trials, None included (the probability of None on trials where None was chosen), so every participant has a value. Artifacts: `trial_choice_prediction.rds`, `choice_prediction_by_subject.csv/.rds`.
6. `06_plot_parameter_test_retest.R`, `07_plot_choice_prediction_test_retest.R`: session 1 vs session 2 scatters, in the style of `analysis/beta_tau_halfnormal_stz` (identity line dashed, least-squares line red, Pearson r).

7. `08_plot_hyperparameter_recovery.R`: posterior of `beta_location`, `beta_scale`, `tau_location`, `tau_scale` per session, with the population value (set in `main.R`), the sampled value (mean and SD of the 200 true betas and taus actually drawn; the truncation of beta at 0 removes only 3e-5, so these match location and scale) and the posterior median. Artifacts: `hyperparameter_recovery.csv/.rds` (median, 90% interval, and whether each reference value falls inside it). Figure: `output/hyperparameter_recovery.png/.pdf`.

8. `09_mcmc_diagnostics.R` → `output/mcmc_diagnostics.pdf` (8 pages per session, 16 in all) and `artifacts/mcmc_diagnostics.rds`: sampler diagnostics per chain (divergences, max-treedepth hits, E-BFMI, per-chain hyperparameter means); R-hat and bulk/tail ESS for the hyperparameters and for every subject-level parameter (also without flagged chains, if any: E-BFMI < 0.3 or any max-treedepth hit); trace, rank-overlay and pairs plots of the hyperparameters; histograms of subject-level R-hat and ESS; trace plots of the 6 subject-level parameters with the highest R-hat. Same pages as `bradley_terry_beta_tau_lognormal_stz_recovery/code/10_mcmc_diagnostics.R`.
9. `10_compile_recovery_pdf.R` → `output/recovery_summary.pdf` (7 pages): hyperparameter recovery; the five test-retest scatters on one page (A beta, B tau, C u, D choice prediction A/B only, E choice prediction with None); then each scatter on its own page. Reads the plot objects 06–08 save as `artifacts/p_*.rds`.

## 3. Outputs (`output/test-retest across sessions/`)

* `beta_test_retest_scatter.png`
* `tau_test_retest_scatter.png`
* `utility_test_retest_scatter.png` (one point per subject x item)
* `choice_prediction_test_retest_scatter.png` (one point per participant; A/B choices only)
* `choice_prediction_all_test_retest_scatter.png` (one point per participant; A, B and None)

## 4. Findings / Summary

(Leave this section blank until the pipeline is run and the figures have been inspected.)
