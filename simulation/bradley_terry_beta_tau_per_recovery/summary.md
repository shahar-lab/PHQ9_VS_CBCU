# Simulation Notebook: Bradley-Terry Beta Tau Per -- Parameter Recovery

**Model:** `models/bradley_terry_beta_tau_per/bradley_terry_beta_tau_per.stan`
**Date Created:** 2026-09-10

## 1. Hypotheses
Full parameter-recovery check for the Bradley-Terry Beta Tau Per model: can the hierarchical
Stan model recover per-subject utilities (u), choice sensitivity (beta), the no-choice burden
threshold (tau), and the per-outcome perseveration parameters (key_decay, rho) from simulated
3-way (A / B / None) choice data with trial-to-trial perseveration dynamics?

## 2. Design
* N_subjects = 20, N_options = 15, N_trials per subject = 105 (2100 trials total).
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
Recovery was good across individual- and group-level parameters. Posterior means correlated
with true generating values as follows: u (utilities) r = .84 (n = 300 subject-option pairs),
beta r = .80, tau r = .83, key_decay r = .71, rho r = .73 (all n = 20 subjects).

Group-level hyperparameters recovered close to their generating values:
mu_log_beta true 0.5 / recovered 0.62; sigma_log_beta true 0.3 / recovered 0.39;
mu_tau true 0 / recovered 0.13; sigma_tau true 1.0 / recovered 0.73;
mu_logit_key_decay true 1.0 / recovered 1.02; sigma_key_decay true 0.5 / recovered 0.47;
mu_rho true 1.0 / recovered 1.10; sigma_rho true 0.5 / recovered 0.60.
Between-subject variance terms (e.g., sigma_tau) showed some attenuation relative to their
generating values.

Sampling diagnostics were clean: E-BFMI per chain ~0.60-0.67, no max-treedepth hits, and a
small number of divergent transitions (1, 3, 12, 0 across the four chains).
