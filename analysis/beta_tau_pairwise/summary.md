# Analysis Notebook: beta_tau_pairwise

**Model:** `models/bradley_terry_beta_tau/bradley_terry_beta_tau.stan` (Bradley-Terry utilities + choice sensitivity `beta` + burden threshold `tau`; **no perseveration components**), fit to `data/processed/cbcu.csv`.
**Date Created:** 2026-11-06

## 1. Hypotheses

Same outputs as `analysis/beta_tau_per_pairwise`, but from a model without perseveration
(`key_decay` / `rho`): one participant-level parameter table per wave (utilities, `tau`, `beta`)
joined with PHQ9, plus test-retest and parameter-relationship figures. The two jobs can be compared
to see what the perseveration terms add.

## 2. Design notes

**Two fits, one per wave** (`time1`, `time2`), as in `beta_tau_per_pairwise`: the model is
hierarchical (`mu_log_beta`/`sigma_log_beta`, `mu_tau`/`sigma_tau`), so each wave is fit once,
pooling all subjects in that wave. Subject-index mappings are in
`artifacts/subject_lookup_time1.csv` / `subject_lookup_time2.csv` and are independent across waves.

**Data.** `cbcu.csv` coded 1 = left (A), 2 = right (B), 3 = skip (None). Trials are sorted by
`prolific_id, block, trial`; the Stan data block takes the subject index as `subject` and has no
`first_trial_of_subject` flag (only needed by the perseveration model).

**Posterior summary: median.** Participant-level `u_1`...`u_15`, `tau`, `beta` are posterior medians.

**Join behavior.** PHQ9 is left-joined on `(prolific_id, time)`; the CBCU table defines the rows.

**Outputs.**
* `output/test-retest across sessions/`: utility, tau, beta scatters + `test_retest_summary.pdf`.
  PHQ9 test-retest plots are intentionally omitted (model-independent, already in `beta_tau_per_pairwise`).
* `output/relations between parameters/`: u/beta/tau cross-parameter scatters per wave, PHQ9 sum / item-SD vs
  session-averaged u/beta/tau, utility vs mapped PHQ9 item (subject-level and group-mean), and
  `parameter_relationships_summary.pdf`.

## 3. Priors

Defined in the `model {}` block of `bradley_terry_beta_tau.stan` (centered parameterization).

| Parameter | Prior |
|---|---|
| `mu_log_beta` | Normal(0, 2) |
| `sigma_log_beta` | Exponential(2) |
| `beta` (subject) | Lognormal(`mu_log_beta`, `sigma_log_beta`) |
| `mu_tau` | Normal(0, 2) |
| `sigma_tau` | Exponential(2) |
| `tau` (subject) | Normal(`mu_tau`, `sigma_tau`) |
| `u_raw` | Normal(0, 1), then standardized per subject to mean 0 / SD 1 (`u_matrix`) |

Sampling: 4 chains, 1000 warmup / 1000 sampling (same as `beta_tau_per_pairwise`).

## 4. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
