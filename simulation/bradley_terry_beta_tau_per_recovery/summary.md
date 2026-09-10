# Simulation Notebook: Bradley-Terry Beta Tau Per -- Parameter Recovery

**Model:** `models/bradley_terry_beta_tau_per/bradley_terry_beta_tau_per.stan`
**Date Created:** 2026-09-10

## 1. Hypotheses
Full parameter-recovery check for the Bradley-Terry Beta Tau Per model: can the hierarchical
Stan model recover per-subject utilities (u), choice sensitivity (beta), the no-choice burden
threshold (tau), and the per-outcome perseveration parameters (key_decay, rho) from simulated
3-way (A / B / None) choice data with trial-to-trial perseveration dynamics?

## 2. Design
* N_subjects = 20, N_options = 15, N_trials per subject = 100 (2000 trials total).
* Ground-truth group-level hyperparameters fixed at specific values within each prior's
  plausible range (bradley_terry_beta_tau_per.stan, model block), rather than drawn from
  the priors: `mu_log_beta = 0.5`, `sigma_log_beta = 0.3`, `mu_tau = 0`, `sigma_tau = 1`,
  `mu_logit_key_decay = 1`, `sigma_key_decay = 0.5`, `mu_rho = 1`, `sigma_rho = 0.5`.
* Per-subject true parameters drawn from those hyperparameters, matching the Stan model exactly:
  `beta ~ lognormal(mu_log_beta, sigma_log_beta)`, `tau ~ normal(mu_tau, sigma_tau)`,
  `key_decay = inv_logit(logit_key_decay)` with `logit_key_decay ~ normal(mu_logit_key_decay, sigma_key_decay)`,
  `rho ~ normal(mu_rho, sigma_rho)`.
* Per-subject true utilities: standardized per subject to mean 0 / sd 1 (matching the u_matrix
  hard constraint in the Stan model).
* No `set.seed()` used -- each run draws fresh truth.
* Data simulated via `sim.block()` per subject (one call per subject, looped in
  `code/simulated_data.R`); choice factor (A/B/None) recoded to integer 1/2/3 for Stan's
  `categorical_logit`. `first_trial_in_block` is set to 1 on each subject's first trial in the
  combined trial ordering so the Stan model's key_value running pass resets per subject.
* Fit via cmdstanr: 4 chains, parallel_chains = 4, iter_warmup = 1000, iter_sampling = 1000.
* Single simulate -> fit -> compare run (not repeated across multiple simulated datasets).

## 3. Findings / Summary
Not yet run. Run `main.R` to simulate, fit, and populate this section with diagnostics and
recovery correlations for u, beta, tau, key_decay, and rho.
