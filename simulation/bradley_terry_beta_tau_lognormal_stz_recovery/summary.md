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
* **Sampler:** Stan via cmdstanr; 4 chains, 2000 warmup, 2000 sampling iterations; initial values uniform(-0.5, 0.5) on the unconstrained scale (`init = 0.5`)
* **Why these sampler settings:** an earlier run with 1000 warmup and Stan's default initial values (uniform(-2, 2)) left one of four chains stuck (seed 2062324528, chain 1: step size 0.001 vs ~0.03 in the other chains, 1904/2000 max-treedepth hits, E-BFMI 0.002). Replaying that chain with its seed and saved warmup showed the cause. Its starting point was ordinary (betas 1.4-4.0), but in the first ~10 warmup iterations, while the step size was still being searched for, it jumped into a region with beta_location ~ -2, beta_scale ~ 3, tau_scale ~ 1e-5 and log(beta) spanning -10 to 20 (log density ~ -20,000 vs ~ -9,300 in the posterior). It needed ~1,250 iterations to leave that region. With 1000 warmup, the last adaptation window (iterations 451-950) lay entirely inside it, so the step size and mass matrix were tuned there and stayed fixed during sampling. Replayed with 2000 warmup, the same chain reached the posterior at iteration ~1,264, inside the last adaptation window (851-1950), and sampled correctly. The other three chains agreed (R-hat <= 1.01).
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

* Utility recovery by extreme subjects (`11_plot_u_recovery_by_extremes.R` → `output/11_u_recovery_by_beta`, `11_u_recovery_by_tau`, `11_u_recovery_by_beta_groups`, `11_u_recovery_by_tau_groups`; `artifacts/u_recovery_by_subject.rds`): the utility scatter split by subjects' true beta, and separately by true tau, two ways: lowest 10% / middle 80% / highest 10% (`extreme_quantile` in `main.R`), and 10 equal groups of 20 subjects (`n_quantile_groups`). Points coloured by each subject's share of "None" choices; each group panel reports Pearson r and the group's mean share of None.
* Utility uncertainty vs beta and tau (`12_utility_hdi_vs_beta_tau.R` → `output/12_u_hdi_width_vs_beta`, `12_u_hdi_width_vs_tau`; `artifacts/u_hdi_width_by_subject.csv/.rds`, `u_hdi_width_correlations.rds`): per subject (and session; 1 in the simulation), the 95% HDI width of each of the 15 utilities from the posterior draws, averaged over the 15, plotted against the posterior means of beta (log axis) and tau. The table also holds each subject's share of None choices and true beta and tau. Interaction of beta and tau (`output/12_u_hdi_width_vs_beta_by_tau`, `12_u_hdi_width_vs_tau_by_beta`; `artifacts/u_hdi_width_interaction_model.rds`): the beta scatter with points coloured by posterior mean tau, and the tau scatter with points coloured by posterior mean beta (log colour scale); plus `lm(mean_hdi_width ~ log(beta_mean) * tau_mean)`.
* MCMC diagnostics (`10_mcmc_diagnostics.R` → `output/10_mcmc_diagnostics.pdf`, `artifacts/mcmc_diagnostics.rds`): sampler diagnostics and per-chain hyperparameter means per chain; R-hat and bulk/tail ESS for the hyperparameters and for every subject-level parameter, with all chains and again without flagged chains (E-BFMI < 0.3 or any max-treedepth hit); trace, rank-overlay and pairs plots of the hyperparameters; trace plots of the 6 subject-level parameters with the highest R-hat.

## 5. Findings / Summary

(Leave this section blank until the model is fitted and the figures have been inspected.)

* Figures in `output/`: `02_true_parameters`, `06_u/beta/beta_log/tau_recovery`, `06_full_recovery_panel`, `07_location_posteriors`, `07_scale_posteriors`, `08_parameter_relationships` (each as PDF and PNG), and `09_combined_summary.pdf` (5 pages).

## 6. Manuscript excerpt — example 1

[Placeholder. After the researcher runs the pipeline, a short publication-ready paragraph describing the recovery *design*.]

## 7. Manuscript excerpt — example 2

[Placeholder. After the researcher runs the pipeline, a short publication-ready paragraph reporting the recovery *result*.]
