# Analysis Notebook: beta_tau_noncentered

**Model:** `models/bradley_terry_beta_tau_noncentered/bradley_terry_beta_tau_noncentered.stan` (Bradley-Terry utilities + burden threshold `tau` scaled by `beta`, no perseveration, non-centered), fit to `data/processed/cbcu.csv`.
**Date Created:** 2026-11-10

## 1. Hypotheses

Fit the no-rho variant of `bradley_terry_beta_tau_rho_noncentered` to the real data and
produce a participant-level parameter table (item utilities, `beta`, `tau`) per wave,
joined with PHQ9 scores. Evaluate convergence, the test-retest stability of each parameter
across waves, and the relationships between parameters and with PHQ9. Results can be
compared with `analysis/beta_tau_rho_noncentered/`.

## 2. Design notes

**Cloned from `analysis/beta_tau_per_pairwise`.** Same pipeline and plot conventions;
only the model, the parameter set, and the sampling settings differ.

**Choice rule.**
`logit(A) = beta * u[A]`, `logit(B) = beta * u[B]`, `logit(None) = beta * tau`.
Utilities are standardized within subject to mean 0 / SD 1. Without perseveration the
model does not need the `first_trial_of_subject` flag, so `prep_data.R` no longer builds it.

**Two fits, one per wave.** Each wave (`time1`, `time2`) is fit once, pooling all
subjects in that wave, with its own subject-index lookup
(`artifacts/subject_lookup_time1.csv`, `artifacts/subject_lookup_time2.csv`).

**Sampling.** 4 chains, 2000 warmup, 2000 sampling iterations per wave (set in `main.R`).

**Posterior summary: median.** Participant-level estimates (`u_1`...`u_15`, `beta`,
`tau`) are posterior medians.

**Join behavior.** PHQ9 is left-joined onto the parameter table by `(prolific_id, time)`.

## 3. Priors

Defined in the `.stan` file's `model {}` block (same as the rho model, minus `rho`).

| Parameter | Prior |
|---|---|
| `beta_location` | Half-Normal(0, 3) |
| `beta_scale` | Half-Normal(0, 2) |
| `beta` (subject) | Normal(`beta_location`, `beta_scale`) truncated at 0, non-centered |
| `tau_location` | Normal(0, 2) |
| `tau_scale` | Half-Normal(0, 2) |
| `tau` (subject) | Normal(`tau_location`, `tau_scale`), non-centered |
| `u_raw` | Normal(0, 1), then standardized per subject |

## 4. Outputs

- `output/diagnostic_time1.pdf`, `output/diagnostic_time2.pdf` — ESS/R-hat table, trank plot, pairs plot for the four population parameters.
- `output/test-retest across sessions/` — time1 vs time2 scatters for utilities, `beta`, `tau`, PHQ9 sum and items; `test_retest_summary.pdf`.
- `output/relations between parameters/` — u vs `tau`/`beta`, `beta` vs `tau` (per wave); PHQ9 sum and PHQ9 item SD vs `beta`/`tau`; utility vs mapped PHQ9 item; `parameter_relationships_summary.pdf`. PHQ9 vs subject mean utility is not plotted: utilities are standardized to mean 0 within subject, so that mean is ~0 for everyone.
- `artifacts/participant_parameters.csv` — the participant-level table.

## 5. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
