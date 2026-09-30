# Recovery Notebook: Bradley-Terry Beta Tau Alpha_per

**Generative model:** `models/bradley_terry_beta_tau_alpha_per/`
**Fitted model:** `models/bradley_terry_beta_tau_alpha_per/`
**Job-folder:** `simulation/bradley_terry_beta_tau_alpha_per_recovery/`
**Date Created:** 2026-09-30

## 1. Design (set in `main.R`)
* n_subjects: 200
* n_options: 15 (2 offered per trial, plus a None option)
* n_trials: 105 per subject
* n_sessions: 1 (the task has no sessions)
* Population location (mu_*): mu_log_beta = 0.5, mu_tau = 0, mu_rho = 0, mu_logit_alpha = 0
* Population scale (sigma_*): sigma_log_beta = 0.3, sigma_tau = 1, sigma_rho = 0.75, sigma_alpha = 1
* Unit-interval transforms: alpha_per = plogis(logit_alpha_per), logit_alpha_per ~ normal(mu_logit_alpha, sigma_alpha); passed to sim.block() on the probability scale. beta = exp(log_beta), log_beta ~ normal(mu_log_beta, sigma_log_beta).
* Sampler: Stan via cmdstanr; 4 chains, 3000 warmup, 2000 sampling iterations.
* Recovery criteria (approved):
  * Pearson r between true and recovered (posterior mean) >= 0.75
  * Bias (mean of recovered - true) within 10% of the true SD
  * 90% credible-interval coverage between 80% and 95%
  * No rhat / ess threshold was specified; convergence is reported without a cutoff.

## 2. Generating true parameters
* u: standard-normal draws standardized per subject (mean 0, sd 1), matching the u_matrix constraint in the Stan model.
* beta, tau, alpha_per, rho: one draw per subject from the population values above, in the same population form as the Stan model. No set.seed(), so each run draws fresh truth.
* Artifacts: true_population.rds, true_parameters.rds, true_u.rds
* Figure: output/02_true_parameters.{pdf,png} (dot histograms with theoretical density overlay).

## 3. Generating data
* sim.block() from models/bradley_terry_beta_tau_alpha_per/bradley_terry_beta_tau_alpha_per.R, once per subject.
* Choice recoded to integer 1/2/3 (A/B/None); first_trial_in_block marks each subject's first trial.
* Artifacts: simulated_data.rds, simulated_data.csv, stan_data.rds

## 4. Recovering parameters
* Fitting definition: models/bradley_terry_beta_tau_alpha_per/bradley_terry_beta_tau_alpha_per.stan
* Artifacts: bt_beta_tau_alpha_per_fit.rds, diagnostic_summary.rds, draws_pop.rds, draws_sbj.rds, recovered_parameters.rds, recovery_metrics.rds
* 06_recovery_metrics.R prints convergence (rhat, ess_bulk, divergences), then per-parameter r, bias, slope, 90% coverage, posterior SD and shrinkage, then population-level median and 90% interval against the truth, then the correlation of recovery errors between parameters. Each is flagged against the criteria above.
* Figures in output/: 07-11 individual recovery scatters (u, beta, tau, alpha_per, rho), 12 combined panel, 14 group-level posteriors, 15 mu and sigma posteriors, 16_combined_summary.pdf (four sheets).

## 5. Findings / Summary
* (Leave blank until the model is fitted and the report has been inspected.)
* The Word .docx narrative was not part of the Job Card and is not produced.

## 6. Manuscript excerpt - example 1
[Placeholder: recovery design paragraph.]

## 7. Manuscript excerpt - example 2
[Placeholder: recovery result paragraph.]
