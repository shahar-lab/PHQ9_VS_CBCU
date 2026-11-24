# Recovery Notebook: Bradley-Terry sigma (no beta; None as the 16th utility), test-retest

**Generative model:** `models/bradley_terry_sigma/bradley_terry_sigma.R` (`draw.u()`, `sim.block()`)
**Fitted model:** `models/bradley_terry_sigma/bradley_terry_sigma.stan`
**Job-folder:** `simulation/bradley_terry_sigma_recovery/`
**Date Created:** 2026-11-24

## 1. Model in one line

logit(A) = u[A], logit(B) = u[B], logit(None) = u[None]. The 15 item utilities and None are one sum-to-zero vector per subject with marginal SD `sigma`; `sigma` replaces beta as the consistency parameter. `tau` is reported as the None utility.

## 2. Design (set in `main.R`)

* **n_subjects:** 200
* **n_options:** 15 (+ None as utility 16)
* **n_trials:** 105 per subject per session
* **n_sessions:** 2. Both sessions are generated from the **same** true parameters (a perfectly stable trait), each with its own random offers and choices. The test-retest correlations therefore show only choice noise and estimation error, and are an upper bound on what the real data can show.
* **sigma:** normal(location = 6, scale = 2) truncated at 0 (the truncation removes P = 0.13%); 95% of subjects in about [2.1, 9.9], close to the sigma implied by the beta-model fits of the real data (median 6.9, 5th-95th percentile 2.5-10.8)
* **u (items + None):** drawn with `draw.u()`, the model's own prior: 16 iid normals, centered to sum to zero and scaled so each has marginal SD `sigma`
* **Fitted-model priors:** `sigma_location ~ normal(5, 3)`, `sigma_scale ~ half-normal(0, 3)`
* **Sampler:** Stan via cmdstanr, one fit per session; 4 chains, 3000 warmup, 2000 sampling iterations; `init = 0.5`
* **Seed:** none, so each run draws fresh truth

## 3. Pipeline

1. `01_generate_true_parameters.R`: `sigma_raw` from a standard normal truncated below at `-location / scale` (inverse CDF), then `u` per subject with `draw.u()`. Artifacts: `true_population.rds`, `true_parameters.rds` (sigma, tau = u[None]), `true_u.rds` (200 x 16, last column None).
2. `02_generate_data.R`: `sim.block()` per subject per session. Artifacts: `simulated_data.rds` (includes the true `prob_A/B/None` per trial), `stan_data_list.rds`.
3. `03_fit_model.R`: one fit per session. The full fit is not saved (`log_lik` would make it several GB). Artifacts: `draws_session<k>.rds` (sigma_location, sigma_scale, sigma, tau, u_matrix), `diagnostic_summary_session<k>.rds`, `hyperparameter_summary_session<k>.rds`.
4. `04_extract_subject_estimates.R`: posterior median per subject per parameter per session, plus the true values. Artifact: `participant_parameters.csv/.rds`.
5. `05_compute_choice_prediction.R`: per trial, the model's probability of the option actually chosen under the 3-way softmax (logits `u[A]`, `u[B]`, `tau`), averaged over draws; per participant the mean over A/B trials (`choice_prediction`) and over all trials (`choice_prediction_all`), with the same means from the true parameters. Artifacts: `trial_choice_prediction.rds`, `choice_prediction_by_subject.csv/.rds`.
6. `06_plot_true_vs_estimated.R`: true value vs posterior median, one panel per session, for sigma, tau and u. Figures: `output/true vs estimated/`.
7. `07_plot_parameter_test_retest.R`, `08_plot_choice_prediction_test_retest.R`: session 1 vs session 2 scatters (identity line dashed, least-squares line red, Pearson r; sigma with 95% HDI whiskers). Figures: `output/test-retest across sessions/`.
8. `09_plot_hyperparameter_recovery.R`: posterior of `sigma_location`, `sigma_scale` per session, with the population value, the sampled value (mean and SD of the 200 true sigmas) and the posterior median. Artifacts: `hyperparameter_recovery.csv/.rds`. Figure: `output/hyperparameter_recovery.png/.pdf`.
9. `10_mcmc_diagnostics.R` → `output/mcmc_diagnostics.pdf` and `artifacts/mcmc_diagnostics.rds` (same pages as the halfnormal recovery).
10. `11_compile_recovery_pdf.R` → `output/recovery_summary.pdf` (10 pages): hyperparameter recovery; true vs estimated for sigma, tau, u; the five test-retest scatters on one page; then each scatter on its own page.

All axes cover the parameter's range: sigma and the hyperparameters start at 0; tau and u are symmetric about 0; choice prediction runs over [0, 1].

## 4. What to look at

* **sigma, true vs estimated:** at high sigma choices are near-deterministic and the data barely separate sigma values, so expect wider HDIs and more shrinkage at the top. The low-sigma subjects (2-3) are the ones most relevant to the clinical question.
* **tau:** None is now one of the 16 utilities rather than its own hierarchy; check that it recovers as well as the items.

## 5. Findings / Summary

(Leave this section blank until the pipeline is run and the figures have been inspected.)
