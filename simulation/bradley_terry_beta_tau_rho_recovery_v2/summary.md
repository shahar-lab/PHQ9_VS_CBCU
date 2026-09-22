# Simulation Notebook: Bradley-Terry Beta Tau Rho -- Parameter Recovery (rho mu=0, sigma=0.75)

**Model:** `models/bradley_terry_beta_tau_rho/bradley_terry_beta_tau_rho.stan`
**Date Created:** 2026-09-22

## 1. Hypotheses
Parameter-recovery check for the Bradley-Terry Beta Tau Rho model (perfect decay, no
key_decay parameter), rerun with a different true rho distribution requested by the PI:
`mu_rho = 0`, `sigma_rho = 0.75` (rather than the `mu_rho = 1`, `sigma_rho = 0.5` used in
`bradley_terry_beta_tau_rho_recovery`). The Stan model itself is unchanged -- mu_rho and
sigma_rho remain free parameters estimated with the same hyperpriors
(`mu_rho ~ normal(0, 2)`, `sigma_rho ~ exponential(2)`); only the true generative values
used to simulate the data change.

## 2. Design
* N_subjects = 200, N_options = 15, N_trials per subject = 105 (21000 trials total).
* Ground-truth group-level hyperparameters fixed at specific values within each prior's
  plausible range (bradley_terry_beta_tau_rho.stan, model block), rather than drawn from
  the priors: `mu_log_beta = 0.5`, `sigma_log_beta = 0.3`, `mu_tau = 0`, `sigma_tau = 1`,
  `mu_rho = 0`, `sigma_rho = 0.75`.
* Per-subject true parameters drawn from those hyperparameters, matching the Stan model exactly:
  `beta ~ lognormal(mu_log_beta, sigma_log_beta)`, `tau ~ normal(mu_tau, sigma_tau)`,
  `rho ~ normal(mu_rho, sigma_rho)`.
* Per-subject true utilities: standardized per subject to mean 0 / sd 1 (matching the u_matrix
  hard constraint in the Stan model).
* No `set.seed()` used -- each run draws fresh truth.
* Data simulated via `sim.block()` per subject (one call per subject, looped in
  `code/simulated_data.R`); choice factor (A/B/None) recoded to integer 1/2/3 for Stan's
  `categorical_logit`. `first_trial_in_block` is set to 1 on each subject's first trial in the
  combined trial ordering so the Stan model's key_value running pass resets per subject.
* Fit via cmdstanr: 4 chains, parallel_chains = 4, iter_warmup = 3000, iter_sampling = 2000.
* Single simulate -> fit -> compare run (not repeated across multiple simulated datasets).

## 3. Findings / Summary
Recovery was good across individual- and group-level parameters. Posterior means correlated
with true generating values as follows: u (utilities) r = .89 (n = 3000 subject-option pairs),
beta r = .83, tau r = .95, rho r = .94 (all n = 200 subjects).

Group-level hyperparameters recovered close to their generating values:
mu_log_beta true 0.5 / posterior median 0.48; sigma_log_beta true 0.3 / 0.34;
mu_tau true 0 / -0.01; sigma_tau true 1.0 / 1.04;
mu_rho true 0 / -0.14; sigma_rho true 0.75 / 0.74.

mu_rho's posterior median (-0.14) missed the true value (0) more than the other group
parameters, with only 0.78% of the posterior mass above 0 (pd = 99.22%). This tracks the raw
sample mean of the 200 simulated subjects' true rho values (~-0.10, also below 0) rather than
reflecting a fitting problem -- with sigma_rho = 0.75 and n = 200 subjects, the sampling error
of the mean is ~0.053, so a single simulated draw landing this far from 0 is expected sampling
variation, not bias in the model.

Sampling diagnostics were clean: E-BFMI per chain 0.71-0.75, no max-treedepth hits, no
divergent transitions, and Rhat = 1.00 for all group-level parameters.
