# Analysis Notebook: sigma

**Model:** `models/bradley_terry_sigma/bradley_terry_sigma.stan` (Bradley-Terry utilities with no inverse temperature; None is the 16th utility; consistency carried by the utility SD `sigma`), fit to `data/processed/cbcu.csv`.
**Recovery:** `simulation/bradley_terry_sigma_recovery/`
**Date Created:** 2026-11-24

## 1. Hypotheses

Replace beta with sigma: choice consistency (transitivity) is expressed as the spread of each
participant's utilities rather than as a multiplier on them, and the None threshold is one more
utility rather than a separate parameter. Compare with `analysis/beta_tau_halfnormal_stz/`.

## 2. Design notes

**Choice rule.** `logit(A) = u[A]`, `logit(B) = u[B]`, `logit(None) = u[None]` (= `tau`).

**Utilities.** Per participant, the 15 item utilities and None form one sum-to-zero vector
(16 values), `u ~ normal(0, sigma)` marginally, written non-centered (`u = sigma * u_raw`).
Because None is in the sum-to-zero vector, `u_1..u_15` sum to `-tau`, not 0.

**sigma.** `sigma ~ normal(sigma_location, sigma_scale) T[0, ]`, non-centered with the
truncation's normalizing constant added (same construction as beta in the halfnormal model).
Meaning: P(choose the higher of two random items) ≈ .73 at sigma = 1, .91 at 4, .96 at 10.

**Two fits, one per wave**, each with its own subject lookup (`artifacts/subject_lookup_<wave>.csv`).
Sampling: 4 chains, 3000 warmup, 5000 sampling, `init = 0.5` (set in `main.R` / `fit_model.R`).

**Posterior summary: median** per participant (`u_1..u_15`, `tau`, `sigma`).

**Join behavior.** PHQ-9 is left-joined onto the parameter table by `(prolific_id, time)`.

**Comparison with the beta model** (`code/compare_with_beta_model.R`). Same participants and
data. Compares sigma with beta, and with the beta model's implied sigma (SD of
`beta * [u, tau]`, same definition as sigma), and tau / u on the logit scale (centred within
participant over the 16 logits, since the two models fix the location differently). Needs
`analysis/beta_tau_halfnormal_stz/artifacts/participant_parameters.csv`; skipped otherwise.

## 3. Priors

Defined in the `.stan` file's `model {}` block.

| Parameter | Prior |
|---|---|
| `sigma_location` | Normal(5, 3), lower bound 0 |
| `sigma_scale` | Half-Normal(0, 3) |
| `sigma` (subject) | Normal(`sigma_location`, `sigma_scale`) truncated at 0, non-centered |
| `u` (subject, 15 items + None) | `sigma * u_raw`, `u_raw` ~ Normal(0, sqrt(16/15)) with sum-to-zero |

## 4. Outputs

- `output/diagnostics/diagnostic_<wave>.pdf` — hyperparameter ESS/R-hat, subject-level R-hat/ESS counts, rank and pairs plots.
- `output/hyperparameter_posteriors.png` — `sigma_location`, `sigma_scale`, time 1 and time 2 overlaid.
- `artifacts/participant_parameters.csv` — participant x time table (u, tau, sigma, PHQ-9).
- `artifacts/sigma_draws_by_wave.rds` — sigma draws per participant (for HDIs / a later ICC with measurement error).
- `output/test-retest across sessions/correlation/` — time 1 vs time 2 for sigma (95% HDI), tau, u, PHQ-9 sum; `test_retest_summary.pdf`.
- `output/comparison with beta model/` — sigma vs beta, sigma vs implied sigma, tau and u vs the beta model; `artifacts/comparison_with_beta_model.csv`.

- `output/test-retest across sessions/icc/` — ICC of sigma across days (`icc_sigma.csv`, posterior plots); diagnostics in `output/diagnostics/diagnostic_icc_sigma_*.pdf`.

**ICC of sigma.** Same brms models, priors (Intercept centred on the sigma_location prior, 5) and
sampling as the beta ICC in `beta_tau_halfnormal_stz`: `sigma ~ 1 + (1 | id)` on posterior medians,
without and with measurement error (posterior SD as known `se`). These put the day 2 shift in
mean sigma into the residual (absolute agreement). Two more fits add a fixed day effect
(`sigma ~ 1 + day + (1 | id)`), which removes the shared shift from the residual, so their
ICC = sigma_b^2 / (sigma_b^2 + sigma_e^2) is a consistency ICC.

Not yet ported from `beta_tau_halfnormal_stz`: choice prediction, PHQ-9 relations.

## 5. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
