# Recovery Notebook: Bradley-Terry Beta Tau Rho (non-centered)

**Generative model:** `models/bradley_terry_beta_tau_rho_noncentered/` (`sim.block()`)
**Fitted model:** `models/bradley_terry_beta_tau_rho_noncentered/bradley_terry_beta_tau_rho_noncentered.stan`
**Job-folder:** `simulation/parameter_recovery_noncentered_model/`
**Date Created:** 2026-11-10

## 1. Design (set in `main.R`)

* **n_subjects:** 200
* **n_options:** 15
* **n_trials:** 105 per subject (21,000 trials in total)
* **n_sessions:** 1
* **Population location (`mu_*`):** `mu_beta = 3`, `mu_tau = 0`, `mu_rho = 0`
* **Population scale (`sigma_*`):** `sigma_beta = 1`, `sigma_tau = 1`, `sigma_rho = 1`
* **Unit-interval transforms:** none
* **Sampler:** Stan via cmdstanr; 4 chains, 2000 warmup, 2000 sampling iterations
* **Seed:** none, so each run draws fresh truth
* **Criteria:** report-only. The result is read as numbers (convergence, Pearson r, bias, precision, interval coverage), with no pass/fail thresholds.

## 2. Generating true parameters

* `beta ~ normal(mu_beta, sigma_beta)` truncated at 0, drawn by inverting the CDF above 0. This matches the Stan model's population form, where `mu_beta` and `sigma_beta` are `beta_location` and `beta_scale`.
* `tau ~ normal(mu_tau, sigma_tau)`; `rho ~ normal(mu_rho, sigma_rho)`.
* `u`: normal draws standardized within subject to mean 0 and SD 1, as in the Stan model.
* Artifacts: `true_population.rds`, `true_parameters.rds`, `true_u.rds`
* Figure: `output/02_true_parameters` (dot histograms with the theoretical density overlaid).

## 3. Generating data

* `sim.block()` is loaded from `models/bradley_terry_beta_tau_rho_noncentered/`, called once per subject. It uses the same choice rule as the `.stan` likelihood: a three-way softmax over A, B, and None, with `beta * tau` as the None weight and `rho` added to the response chosen on the previous trial.
* Artifacts: `simulated_data.rds`, `stan_data.rds`

## 4. Recovering parameters

* Fitting definition: `bradley_terry_beta_tau_rho_noncentered.stan`
* Artifacts: `stan_fit.rds`, `diagnostic_summary.rds`, `draws_pop.rds`, `draws_sbj.rds`, `recovered_parameters.rds` (true value, posterior mean, and posterior SD per subject and parameter), `convergence_table.rds`, `recovery_table.rds`, `population_table.rds`, `error_correlations.rds`
* The fit stores `key_contrib` and `log_lik` for every trial, so the fit object is large. Draws are extracted from it for the plots.

## 5. Findings / Summary

(Leave this section blank until the model is fitted and the figures have been inspected.)

* Figures in `output/`: `02_true_parameters`, `06_u/beta/tau/rho_recovery`, `06_full_recovery_panel`, `07_mu_posteriors`, `07_sigma_posteriors` (each as PDF and PNG), and `08_combined_summary.pdf` (4 pages).

## 6. Manuscript excerpt — example 1

[Placeholder. After the researcher runs the pipeline, a short publication-ready paragraph describing the recovery *design*.]

## 7. Manuscript excerpt — example 2

[Placeholder. After the researcher runs the pipeline, a short publication-ready paragraph reporting the recovery *result*.]
