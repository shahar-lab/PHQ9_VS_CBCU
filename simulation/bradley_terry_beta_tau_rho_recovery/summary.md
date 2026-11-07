# Simulation Notebook: Bradley-Terry Beta Tau Rho -- Parameter Recovery

**Model:** `models/bradley_terry_beta_tau_rho/bradley_terry_beta_tau_rho.stan`
**Date Created:** 2026-09-22

## 1. Hypotheses
Full parameter-recovery check for the Bradley-Terry Beta Tau Rho model: can the hierarchical
Stan model recover per-subject utilities (u), choice sensitivity (beta), the no-choice burden
threshold (tau), and the perseveration parameter (rho) from simulated 3-way (A / B / None)
choice data, with perfect (one-trial) perseveration decay -- key_decay is fixed at 0, so only
the immediately preceding trial's chosen slot carries a perseveration bump, with no key_decay
parameter to recover?

## 2. Design
* N_subjects = 200, N_options = 15, N_trials per subject = 105 (21000 trials total).
* Ground-truth group-level hyperparameters fixed at specific values within each prior's
  plausible range (bradley_terry_beta_tau_rho.stan, model block), rather than drawn from
  the priors: `mu_log_beta = 0.5`, `sigma_log_beta = 0.3`, `mu_tau = 0`, `sigma_tau = 1`,
  `mu_rho = 1`, `sigma_rho = 0.5`.
* Per-subject true parameters drawn from those hyperparameters, matching the Stan model exactly:
  `beta ~ lognormal(mu_log_beta, sigma_log_beta)`, `tau ~ normal(mu_tau, sigma_tau)`,
  `rho ~ normal(mu_rho, sigma_rho)`.
* Per-subject true utilities: standardized per subject to mean 0 / sd 1 (matching the u_matrix
  hard constraint in the Stan model).
* No `set.seed()` used -- each run draws fresh truth.
* Data simulated via `sim.block()` per subject (one call per subject, looped in
  `code/simulated_data.R`); choice factor (A/B/None) recoded to integer 1/2/3 for Stan's
  `categorical_logit`. `first_trial_of_subject` is set to 1 on each subject's first trial in the
  combined trial ordering so the Stan model's key_value running pass resets per subject.
* Fit via cmdstanr: 4 chains, parallel_chains = 4, iter_warmup = 3000, iter_sampling = 2000.
* Single simulate -> fit -> compare run (not repeated across multiple simulated datasets).

## 3. Findings / Summary
Recovery was good across individual- and group-level parameters. Posterior means correlated
with true generating values as follows: u (utilities) r = .89 (n = 3000 subject-option pairs),
beta r = .83, tau r = .96, rho r = .87 (all n = 200 subjects).

Group-level hyperparameters recovered close to their generating values:
mu_log_beta true 0.5 / posterior median 0.47; sigma_log_beta true 0.3 / 0.33;
mu_tau true 0 / -0.05; sigma_tau true 1.0 / 0.98;
mu_rho true 1.0 / 1.02; sigma_rho true 0.5 / 0.49.

Sampling diagnostics were clean: E-BFMI per chain 0.66-0.72, no max-treedepth hits, no
divergent transitions, and Rhat = 1.00 for all group-level parameters.
