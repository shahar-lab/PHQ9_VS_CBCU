# Recovery Notebook: Bradley-Terry Beta Tau (lognormal beta, sum-to-zero utilities)

**Generative model:** `models/bradley_terry_beta_tau_lognormal_stz/` (`sim.block()`)
**Fitted model:** `models/bradley_terry_beta_tau_lognormal_stz/bradley_terry_beta_tau_lognormal_stz.stan`
**Job-folder:** `simulation/bradley_terry_beta_tau_lognormal_stz_recovery/`
**Date Created:** 2026-11-13

## 1. Design (set in `main.R`)

* **n_subjects:** 200
* **n_options:** 15
* **n_trials:** 105 per subject (21,000 trials in total)
* **n_sessions:** 1
* **Population location:** `true_beta_location = 1.5` (log scale), `true_tau_location = 0`
* **Population scale:** `true_beta_scale = 0.75` (log scale), `true_tau_scale = 1`
* **Implied beta on the natural scale:** median 4.48, mean 5.94, SD 5.16, 95% interval [1.00, 20.09]
* **Sampler:** Stan via cmdstanr; 4 chains, 1000 warmup, 2000 sampling iterations
* **Seed:** none, so each run draws fresh truth
* **Criteria:** report-only (convergence, Pearson r, bias, slope, 90% coverage, posterior SD), with no pass/fail thresholds.

## 2. Generating true parameters

* Non-centered, as in the Stan model: `beta_raw, tau_raw ~ normal(0, 1)`; `beta = exp(beta_location + beta_scale * beta_raw)`; `tau = tau_location + tau_scale * tau_raw`.
* `u`: drawn from the model's own prior. Each subject gets iid `normal(0, sqrt(N / (N - 1)))` draws, centered to sum to zero, so each utility has marginal SD 1 (the scale `tau` is defined on). Within-subject SD varies around 1. It is not fixed at exactly 1.
* Artifacts: `true_population.rds`, `true_parameters.rds` (includes `beta_raw`, `tau_raw`), `true_u.rds`
* Figure: `output/02_true_parameters` (beta, tau, u; dot histograms with the theoretical density overlaid).

## 3. Generating data

* `sim.block()` from `models/bradley_terry_beta_tau_lognormal_stz/`, called once per subject. It uses the same choice rule as the `.stan` likelihood: a three-way softmax over A, B, and None with logits `beta * u[A]`, `beta * u[B]`, `beta * tau`.
* Artifacts: `simulated_data.rds`, `stan_data.rds`

## 4. Recovering parameters

* Fitting definition: `bradley_terry_beta_tau_lognormal_stz.stan`
* Artifacts: `stan_fit.rds`, `diagnostic_summary.rds`, `draws_pop.rds`, `draws_sbj.rds`, `recovered_parameters.rds` (true value, posterior mean, SD, and 90% interval per subject and parameter), `convergence_table.rds`, `recovery_table.rds`, `log_beta_recovery.rds`, `population_table.rds`, `error_correlations.rds`
* beta is lognormal, so its recovery is also reported on the log scale (`log_beta_recovery.rds`, `06_beta_log_recovery`). On the natural scale, a few very large betas dominate the Pearson r.
* Relationships between beta and tau (`08_parameter_relationships`): (A) true beta vs true tau, (B) recovered beta vs recovered tau, (C) recovery error of log(beta) vs error of tau, (D) per-subject posterior correlation of beta and tau across draws. True beta and tau are drawn independently, so a correlation in B, C, or D that is absent from A comes from the fit. Artifact: `beta_tau_posterior_correlation.rds`.

## 5. Findings / Summary

(Leave this section blank until the model is fitted and the figures have been inspected.)

* Figures in `output/`: `02_true_parameters`, `06_u/beta/beta_log/tau_recovery`, `06_full_recovery_panel`, `07_location_posteriors`, `07_scale_posteriors`, `08_parameter_relationships` (each as PDF and PNG), and `09_combined_summary.pdf` (5 pages).

## 6. Manuscript excerpt — example 1

[Placeholder. After the researcher runs the pipeline, a short publication-ready paragraph describing the recovery *design*.]

## 7. Manuscript excerpt — example 2

[Placeholder. After the researcher runs the pipeline, a short publication-ready paragraph reporting the recovery *result*.]
