# Analysis Notebook: beta_tau_lognormal_stz

**Model:** `models/bradley_terry_beta_tau_lognormal_stz/bradley_terry_beta_tau_lognormal_stz.stan` (Bradley-Terry utilities + burden threshold `tau` scaled by `beta`, no perseveration, sum-to-zero utilities, lognormal `beta`), fit to `data/processed/cbcu.csv`.
**Date Created:** 2026-11-12

## 1. Hypotheses

Refit `beta_tau_noncentered` with two changes to the model: sum-to-zero utilities and a
lognormal `beta`. Produce a participant-level parameter table (item utilities, `beta`, `tau`)
per wave, joined with PHQ9 scores. Evaluate convergence, the test-retest stability of each
parameter across waves, and the relationships between parameters and with PHQ9. Results can
be compared with `analysis/beta_tau_noncentered/` (e.g. LOO via `log_lik`).

## 2. Design notes

**Cloned from `analysis/beta_tau_noncentered`.** Same pipeline and plot conventions; only
the model file differs.

**Choice rule.**
`logit(A) = beta * u[A]`, `logit(B) = beta * u[B]`, `logit(None) = beta * tau`.

**Changes from `beta_tau_noncentered`.**
- Utilities: `sum_to_zero_vector` per subject (instead of standardizing to mean 0 / SD 1).
  The utility prior is scaled so each utility has a marginal SD of 1; this prior, not a hard
  constraint, sets the scale of `u` relative to `beta`.
- `beta`: lognormal, `log(beta) = beta_location + beta_scale * beta_raw`, then `exp()`
  (instead of a normal truncated at 0).

**Saved quantities.** `beta`, `tau`, `u_matrix` (subject x item), and `log_lik` (per trial)
are all transformed parameters, so they are in the saved draws.

**Two fits, one per wave.** Each wave (`time1`, `time2`) is fit once, pooling all
subjects in that wave, with its own subject-index lookup
(`artifacts/subject_lookup_time1.csv`, `artifacts/subject_lookup_time2.csv`).

**Sampling.** 4 chains, 2000 warmup, 4000 sampling iterations per wave (set in `main.R`).

**Runs (separate folders, set by `run_name` in `main.R`).**
* `artifacts/`, `output/`: first fit, wide beta prior (`beta_location ~ normal(2, 1.5)`,
  `beta_scale ~ half-normal(0, 1)`).
* `artifacts_beta_prior_narrow/`, `output_beta_prior_narrow/`: narrower beta prior
  (`beta_location ~ normal(2, 0.75)`, `beta_scale ~ half-normal(0, 0.5)`); implied beta
  97.5% quantile ~44 instead of ~258.

**Posterior summary: median.** Participant-level estimates (`u_1`...`u_15`, `beta`,
`tau`) are posterior medians.

**Beta test-retest with full posteriors** (`code/plot_beta_test_retest_posterior.R` →
`output/test-retest across sessions/beta_test_retest_posterior_scatter.png`;
`artifacts/beta_draws_by_wave.rds`). A version of `beta_test_retest_scatter.png` that
shows the full time 2 posterior instead of the time 2 median: each participant sits at
their time 1 posterior median on the x axis, with a vertical violin of their time 2
posterior draws (0.5%-99.5% quantiles) and the time 2 median as a dot. Panel A:
participants with time 1 median beta > 7 (`beta_threshold_time1`); panel B: <= 7. Shared
y axis; log axes, since beta is lognormal with long posterior tails. Each panel reports
the Pearson r of the log medians.

**Beta posterior width vs beta** (`code/plot_beta_posterior_width.R` →
`output/beta_posterior_width.png`; `artifacts/beta_posterior_width.csv`). Per participant
and wave, the width of the 95% HDI of beta against its posterior median: (A) in beta
units, (B) on the log scale (relative width). Both rise with beta (Spearman rho 0.98 and
~0.89 in both waves): high-beta participants are measured less precisely, also in
relative terms.

**Join behavior.** PHQ9 is left-joined onto the parameter table by `(prolific_id, time)`.

**Beta ICC with measurement error** (`code/fit_icc_beta.R` → `output/test-retest across
sessions/icc_beta.csv`, `icc_beta_posterior.png`; `output/diagnostic_icc_beta.pdf`;
`artifacts/brms_icc_beta_me.rds`, `artifacts/beta_icc_data.csv`). Hypothesis 2, eq. [3]–[4]
on log(beta), with a measurement layer: per participant and day, the posterior mean of
log(beta) is the outcome and its posterior SD is a known standard error,
`log_beta | se(se_log_beta, sigma = TRUE) ~ 1 + (1 | id)`. ICC = sd(id)² / (sd(id)² + sigma²)
per posterior draw; reports median, 95% CrI and P(ICC > 0.80). Priors (log scale):
Intercept ~ Normal(1.5, 1), sd(id) ~ half-t(3, 0, 1), sigma ~ half-t(3, 0, 1).
185 participants with both days. Only the measurement-error model is fit (no plain model).
**Superseded by the joint model below.** Result: ICC 0.96 (95% CrI 0.82–1.00), sigma ~0.09,
but the posterior predictive check failed: predicted day 1 vs day 2 r of the point estimates
0.54 (0.42–0.64) vs observed 0.67. The posterior SDs overstate the noise in the posterior
means (each per-session fit shrinks beta toward its own population mean), so the model
attributes almost all day-to-day change to estimation error and the ICC is too high.

**Joint model for the beta ICC** (`models/bradley_terry_beta_tau_lognormal_stz_joint_icc/`;
`code/prep_data_joint.R`, `code/fit_model_joint.R`, `code/icc_beta_joint.R` →
`artifacts/fit_joint.rds`, `artifacts/unit_lookup_joint.csv`, `output/diagnostic_joint.pdf`,
`output/test-retest across sessions/icc_beta_joint.csv`, `icc_beta_joint_posterior.png`).
One Bradley-Terry fit to both sessions. A unit = one participant in one session, with its
own `u`, `beta`, `tau`. Hypothesis 2, eq. [3] is the prior on beta:
`log(beta_ij) = b_0 + b_0i + e_ij`, `b_0i ~ N(0, sigma_b²)`, `e_ij ~ N(0, sigma_e²)`, no
session effect (absolute agreement). `icc_beta = sigma_b² / (sigma_b² + sigma_e²)` is in
generated quantities, so beta's uncertainty is accounted for directly, without the two-step
approximation. `tau` keeps a separate location and scale per session; `u` prior unchanged.
Priors: `b_0 ~ N(2, 0.75)`, `sigma_b`, `sigma_e ~ half-N(0, 0.5)` (the narrow beta prior of
the per-session model). No `log_lik` output, to keep the output files small.

## 3. Priors

Defined in the `.stan` file's `model {}` block.

| Parameter | Prior |
|---|---|
| `beta_location` | Normal(1, 1), log scale |
| `beta_scale` | Half-Normal(0, 1), log scale |
| `beta` (subject) | LogNormal(`beta_location`, `beta_scale`), non-centered |
| `tau_location` | Normal(0, 2) |
| `tau_scale` | Half-Normal(0, 2) |
| `tau` (subject) | Normal(`tau_location`, `tau_scale`), non-centered |
| `u` (subject) | Normal(0, sqrt(N/(N-1))) with sum-to-zero, N = 15 items |

## 4. Outputs

- `output/diagnostic_time1.pdf`, `output/diagnostic_time2.pdf` — ESS/R-hat table, trank plot, pairs plot for the four population parameters.
- `output/test-retest across sessions/` — time1 vs time2 scatters for utilities, `beta`, `tau`, PHQ9 sum and items; `test_retest_summary.pdf`.
- `output/relations between parameters/` — u vs `tau`/`beta`, `beta` vs `tau` (per wave); PHQ9 sum and PHQ9 item SD vs `beta`/`tau`; utility vs mapped PHQ9 item; `parameter_relationships_summary.pdf`. PHQ9 vs subject mean utility is not plotted: utilities sum to zero within subject, so that mean is 0 for everyone.
- `artifacts/participant_parameters.csv` — the participant-level table.

## 5. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
