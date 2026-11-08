# Simulation Notebook: Bradley-Terry Beta Tau Per -- Recovery in the Empirical Beta Range

**Model:** `models/bradley_terry_beta_tau_per/bradley_terry_beta_tau_per.stan`
**Date Created:** 2026-11-07
**Based on:** `simulation/bradley_terry_beta_tau_per_recovery` (identical pipeline, only beta hyperparameters changed)

## 1. Hypotheses
Are beta (and the other parameters) still recovered when true beta spans the range observed in
the real data? The original recovery used `mu_log_beta = 0.5`, `sigma_log_beta = 0.3`
(median beta ~1.65, almost all < 3.5), far below the empirical range.

## 2. Design
* Empirical beta (`analysis/beta_tau_per_pairwise/artifacts/participant_parameters.csv`, 370 fits,
  both sessions): median 8.1, 95% range 1.8-23.2, max 26.6; log(beta) mean 2.02, sd 0.64.
* Changed: `mu_log_beta = 2.0`, `sigma_log_beta = 0.65` -> simulated beta median ~7.4,
  95% range ~2-26.
* All other settings as in the original simulation (N_subjects = 200, N_options = 15,
  N_trials = 105, same tau / key_decay / rho hyperparameters, same fit settings).

## 3. Findings / Summary
Single run (fresh random truth, 2026-11-08). Diagnostics clean: 0 divergences, 0 max-treedepth hits,
E-BFMI 0.67-0.85. Realized true beta range 1.3-47 (median 7.7); the max exceeds the empirical max (~26.6).

Posterior-mean vs true (n = 200): beta r = .81 (log-scale r = .88, log-log slope = .77), tau r = .70,
key_decay r = .59, rho r = .92.

Beta recovery by true-beta bin (r / median % bias / RMSE on log scale):
* 0-5 (n = 57): .64 / +19% / .32
* 5-10 (n = 86): .55 / +17% / .32
* 10-20 (n = 41): .41 / -4% / .26
* >20 (n = 16): .41 / -27% / .45
Beta is recovered in rank order and without catastrophic failure, but shrinks toward the group mean:
overestimated at the low end, underestimated above ~20 (ordering within the top bins is weak).
The within-bin r values are range-restricted, so they understate overall recovery.

Group level: mu_log_beta 2.00 -> 2.03, sigma_log_beta 0.65 -> 0.64, sigma_tau 1.0 -> 1.0,
sigma_rho 1.5 -> 1.49; sigma_key_decay 1.5 -> 1.19 (attenuated).
