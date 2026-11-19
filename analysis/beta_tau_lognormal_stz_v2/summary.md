# Analysis Notebook: beta_tau_lognormal_stz_v2

**Model:** `models/bradley_terry_beta_tau_lognormal_stz_v2/bradley_terry_beta_tau_lognormal_stz_v2.stan` (Bradley-Terry utilities + burden threshold `tau` scaled by `beta`, sum-to-zero utilities, lognormal `beta`), fit to `data/processed/cbcu.csv`.
**Date Created:** 2026-11-18

## 1. Hypotheses

Refit `beta_tau_lognormal_stz` with a different prior on the population distribution of
`beta` (requested by the PI). Everything else (model structure, data, pipeline, plots) is
unchanged. Compare with `analysis/beta_tau_lognormal_stz/` and with the half-normal
version, `analysis/beta_tau_halfnormal_stz/`.

## 2. Design notes

**Cloned from `analysis/beta_tau_lognormal_stz`.** Same pipeline and plot conventions; only
the beta hyperpriors in the `.stan` file differ.

**Choice rule.**
`logit(A) = beta * u[A]`, `logit(B) = beta * u[B]`, `logit(None) = beta * tau`.

**Beta.** Lognormal, `log(beta) = beta_location + beta_scale * beta_raw`, then `exp()`
(non-centered). The hyperparameters are on the log scale.

**Change from `beta_tau_lognormal_stz`.**
- `beta_location ~ normal(1.25, 0.25)` (was `normal(2, 0.75)`): typical beta
  `exp(1.25) = 3.49` instead of `exp(2) = 7.39`.
- `beta_scale ~ half-normal(0, 0.35)` (was `half-normal(0, 0.5)`).

**Saved quantities.** `beta`, `tau`, `u_matrix` (subject x item), and `log_lik` (per trial)
are all transformed parameters, so they are in the saved draws.

**Two fits, one per wave.** Each wave (`time1`, `time2`) is fit once, pooling all
subjects in that wave, with its own subject-index lookup
(`artifacts/subject_lookup_time1.csv`, `artifacts/subject_lookup_time2.csv`).

**Sampling.** 4 chains, 2000 warmup, 4000 sampling iterations per wave (set in `main.R`).

**Posterior summary: median.** Participant-level estimates (`u_1`...`u_15`, `beta`,
`tau`) are posterior medians.

**Beta test-retest with full posteriors** (`code/plot_beta_test_retest_posterior.R`). Same
plot as in `beta_tau_lognormal_stz`; panels split at time 1 median beta = 7
(`beta_threshold_time1`). With this prior the beta medians may sit lower, so check that
both panels have enough participants and adjust the threshold if not.

**Join behavior.** PHQ9 is left-joined onto the parameter table by `(prolific_id, time)`.

## 3. Priors

Defined in the `.stan` file's `model {}` block.

| Parameter | Prior |
|---|---|
| `beta_location` | Normal(1.25, 0.25), log scale |
| `beta_scale` | Half-Normal(0, 0.35), log scale |
| `beta` (subject) | LogNormal(`beta_location`, `beta_scale`), non-centered |
| `tau_location` | Normal(0, 1.5) |
| `tau_scale` | Half-Normal(0, 1.5) |
| `tau` (subject) | Normal(`tau_location`, `tau_scale`), non-centered |
| `u` (subject) | Normal(0, sqrt(N/(N-1))) with sum-to-zero, N = 15 items |

## 4. Outputs

- `output/diagnostic_time1.pdf`, `output/diagnostic_time2.pdf` — ESS/R-hat table, trank plot, pairs plot for the four population parameters.
- `output/test-retest across sessions/` — time1 vs time2 scatters for utilities, `beta`, `tau`, PHQ9 sum and items; `test_retest_summary.pdf`.
- `output/relations between parameters/` — u vs `tau`/`beta`, `beta` vs `tau` (per wave); PHQ9 sum and PHQ9 item SD vs `beta`/`tau`; utility vs mapped PHQ9 item; `parameter_relationships_summary.pdf`.
- `output/beta_posterior_width.png`, `artifacts/beta_posterior_width.csv` — beta posterior width vs beta.
- `artifacts/participant_parameters.csv` — the participant-level table.

## 5. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
