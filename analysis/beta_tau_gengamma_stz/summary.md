# Analysis Notebook: beta_tau_gengamma_stz

**Model:** `models/bradley_terry_beta_tau_gengamma_stz/bradley_terry_beta_tau_gengamma_stz.stan` (Bradley-Terry utilities + burden threshold `tau` scaled by `beta`, sum-to-zero utilities, `beta` generalized gamma across subjects), fit to `data/processed/cbcu.csv`.
**Date Created:** 2026-11-19

## 1. Hypotheses

The subject betas from the earlier fits look left-skewed (a tail towards low beta).
Does the population distribution of `beta` have a left tail beyond what a lognormal
allows? The generalized gamma contains the lognormal as a limit (`beta_Q -> 0`) and adds
a left tail as `beta_Q` grows, so the posterior of `beta_Q` answers this directly.
Compare with `analysis/beta_tau_lognormal_stz_v2/` and `analysis/beta_tau_halfnormal_stz/`.

## 2. Design notes

**Cloned from `analysis/beta_tau_halfnormal_stz`.** Same data, pipeline and plots; only
the population distribution of `beta`, its hyperpriors, and two new scripts
(`prior_predictive_beta.R`, `plot_beta_population.R`) differ.

**Choice rule.**
`logit(A) = beta * u[A]`, `logit(B) = beta * u[B]`, `logit(None) = beta * tau`.

**Beta: generalized gamma, re-parameterized.**
`log(beta) = beta_mu + beta_sigma * z`, with `z = (log(G) - digamma(k)) / sqrt(trigamma(k))`,
`G ~ gamma(k, 1)`, `k = 1 / beta_Q^2`.
`z` is a standardized log-gamma variable (mean 0, SD 1, skewed left). This is the Prentice
(1974) generalized gamma, rescaled so that:
- `beta_mu` = mean of log(beta) and `beta_sigma` = SD of log(beta), for every `beta_Q`;
- `beta_Q` changes only the shape. Skewness of log(beta): 0 as `beta_Q -> 0` (lognormal),
  about -1.14 at `beta_Q = 1` (Weibull), towards -2 as `beta_Q` grows.

Because `beta_mu` and `beta_sigma` mean the same thing as in the lognormal models, their
priors are on the same scale as `lognormal_stz_v2`'s, and `beta_mu` and `beta_Q` are less
correlated in the posterior than in the standard parameterization.

**Non-centered.** The sampled parameter is `beta_raw = log(G)`, whose density
`k * x - exp(x) - lgamma(k)` is added to the target. `lgamma(k)` is kept because `k`
depends on `beta_Q`. `beta = exp(...)` is positive by construction, so there is no
truncation and no bound on `beta_raw`.

**Bounds on `beta_Q`: [0.2, 3].** The lower bound keeps the sampler away from `Q = 0`,
where `k = 1 / Q^2` blows up; `Q = 0.2` is already close to lognormal (skewness of
log(beta) about -0.2). Above 3 the shape barely changes (skewness already close to -2).
`beta_raw`'s spread shrinks as `beta_Q` gets small, so the model is not fully
non-centered with respect to `beta_Q`: check divergences and the `beta_Q` vs
`beta_sigma` pairs plot in the diagnostic PDFs.

**New-subject beta.** `beta_new` (generated quantities) is beta for a new subject drawn
from the fitted population; its draws are the population prior to carry into a
single-subject model (`artifacts/beta_new_draws_by_wave.rds`).

**Scale of beta.** As in all these models, the scale of `beta` is set by the utility
prior (SD ~1); values of beta are only comparable across models that share it.

**Saved quantities.** `beta`, `tau`, `u_matrix`, `log_lik` (transformed parameters) and
`beta_new` (generated quantities).

**Two fits, one per wave.** Each wave (`time1`, `time2`) is fit once, pooling all
subjects in that wave, with its own subject-index lookup.

**Sampling.** 4 chains, 2000 warmup, 4000 sampling iterations per wave (set in `main.R`).

**Posterior summary: median.** Participant-level estimates (`u_1`...`u_15`, `beta`,
`tau`) are posterior medians.

**Plots.** Same as `beta_tau_halfnormal_stz` (log axes for beta). The beta test-retest
plot splits at time 1 median beta = 7 (`beta_threshold_time1`); check that both panels
have enough participants and adjust if not.

**Model comparison.** Not part of this job. Trial-level LOO is expected to separate the
population distributions only weakly (each subject's beta is mostly set by their own
trials); the posterior of `beta_Q` is the main result. To add this model to the LOO
comparison, clone `analysis/loo_comparison_two_models`.

**Join behavior.** PHQ9 is left-joined onto the parameter table by `(prolific_id, time)`.

## 3. Priors

Defined in the `.stan` file's `model {}` block; repeated in `code/prior_predictive_beta.R`
(`prior_beta`), which must be kept in sync.

| Parameter | Prior |
|---|---|
| `beta_mu` | Normal(1.4, 0.3) (mean of log(beta); exp(1.4) ~ 4) |
| `beta_sigma` | Half-Normal(0, 0.4) (SD of log(beta)) |
| `beta_Q` | Normal(1, 0.6), bounded to [0.2, 3] |
| `beta` (subject) | Generalized gamma(`beta_mu`, `beta_sigma`, `beta_Q`), non-centered via `beta_raw = log(G)` |
| `tau_location` | Normal(0, 1.5) |
| `tau_scale` | Half-Normal(0, 1.5) |
| `tau` (subject) | Normal(`tau_location`, `tau_scale`), non-centered |
| `u` (subject) | Normal(0, sqrt(N/(N-1))) with sum-to-zero, N = 15 items |

## 4. Outputs

- `output/prior_predictive_beta.png`, `artifacts/prior_predictive_beta_quantiles.csv` — prior predictive of beta, population shapes allowed by the prior, skewness of log(beta) vs `beta_Q`. Made before the fit (no data).
- `output/diagnostic_time1.pdf`, `output/diagnostic_time2.pdf` — ESS/R-hat table, trank plot, pairs plot for `beta_mu`, `beta_sigma`, `beta_Q`, `tau_location`, `tau_scale`.
- `output/beta_population.png`, `artifacts/beta_population_summary.csv` — posterior of `beta_Q` vs prior; subject betas vs fitted population (`beta_new`); median and 95% interval of `beta_mu`, `beta_sigma`, `beta_Q`, skewness of log(beta), `beta_new` per wave.
- `artifacts/beta_new_draws_by_wave.rds` — draws of `beta_new` per wave.
- `output/test-retest across sessions/` — time1 vs time2 scatters for utilities, `beta`, `tau`, PHQ9 sum and items; `test_retest_summary.pdf`.
- `output/relations between parameters/` — u vs `tau`/`beta`, `beta` vs `tau` (per wave); PHQ9 sum and PHQ9 item SD vs `beta`/`tau`; utility vs mapped PHQ9 item; `parameter_relationships_summary.pdf`.
- `output/beta_posterior_width.png`, `artifacts/beta_posterior_width.csv` — beta posterior width vs beta.
- `artifacts/participant_parameters.csv` — the participant-level table.

## 5. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
