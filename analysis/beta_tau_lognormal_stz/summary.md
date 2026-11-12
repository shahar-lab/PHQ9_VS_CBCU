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

**Sampling.** 4 chains, 2000 warmup, 2000 sampling iterations per wave (set in `main.R`).

**Posterior summary: median.** Participant-level estimates (`u_1`...`u_15`, `beta`,
`tau`) are posterior medians.

**Join behavior.** PHQ9 is left-joined onto the parameter table by `(prolific_id, time)`.

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
