# Analysis Notebook: beta_tau_rho_pairwise

**Model:** `models/bradley_terry_beta_tau_rho/bradley_terry_beta_tau_rho.stan` (utilities + `beta` + burden threshold `tau` + perseveration weight `rho`, with `key_decay` fixed at 0: only the previous trial's chosen option gets a `rho` bump; no decay parameter), fit to `data/processed/cbcu.csv`.
**Date Created:** 2026-11-06

## 1. Hypotheses

Fit the rho-only (no-decay) perseveration model to the real data, one fit per wave, as the third model in the LOO comparison
(`analysis/loo_comparison_three_models`) alongside `beta_tau_pairwise` (no perseveration) and `beta_tau_per_pairwise` (perseveration with decay).

## 2. Design notes

* Two fits (`time1`, `time2`), same sampling as the other jobs: 4 chains, 1000 warmup / 1000 sampling.
* Perseveration state resets between participants (`first_trial_of_subject`), not between blocks.
* Participant table (`artifacts/participant_parameters.csv`): posterior medians of `u_1`...`u_15`, `tau`, `beta`, `rho`, joined with PHQ9.
* No figures yet (test-retest / relationship plots were not requested for this model).
* Priors are in the `model {}` block of the `.stan` file (centered parameterization, as in `bradley_terry_beta_tau`):
  `sigma_beta ~ N(0,3)` (lower=0), `beta[i] ~ N(0, sigma_beta)` (lower=0, half-normal), `mu_tau ~ N(0,2)`, `sigma_tau ~ Exp(2)`, `mu_rho ~ N(0,2)`, `sigma_rho ~ Exp(2)`, `u_raw ~ N(0,1)`.

## 3. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
