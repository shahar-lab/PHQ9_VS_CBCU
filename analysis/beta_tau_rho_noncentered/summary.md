# Analysis Notebook: beta_tau_rho_noncentered

**Model:** `models/bradley_terry_beta_tau_rho_noncentered/bradley_terry_beta_tau_rho_noncentered.stan` (Bradley-Terry utilities + burden threshold `tau` scaled by `beta` + one-trial perseveration `rho`, non-centered), fit to `data/processed/cbcu.csv`.
**Date Created:** 2026-11-10

## 1. Hypotheses

Fit the model whose recovery was tested in `simulation/parameter_recovery_noncentered_model/`
to the real data, and produce a participant-level parameter table (item utilities, `beta`,
`tau`, `rho`) per wave, joined with PHQ9 scores. Evaluate convergence, the test-retest
stability of each parameter across waves, and the relationships between parameters and
with PHQ9.

## 2. Design notes

**Cloned from `analysis/beta_tau_per_pairwise`.** Same pipeline and plot conventions;
only the model, the parameter set, and the sampling settings differ.

**Choice rule.**
`logit(A) = beta * u[A] + rho * [A chosen last trial]`,
`logit(B) = beta * u[B] + rho * [B chosen last trial]`,
`logit(None) = beta * tau + rho * [None chosen last trial]`.
Utilities are standardized within subject to mean 0 / SD 1.

**Two fits, one per wave.** Each wave (`time1`, `time2`) is fit once, pooling all
subjects in that wave, with its own subject-index lookup
(`artifacts/subject_lookup_time1.csv`, `artifacts/subject_lookup_time2.csv`).

**Sampling.** 4 chains, 2000 warmup, 2000 sampling iterations per wave (set in `main.R`).

**Posterior summary: median.** Participant-level estimates (`u_1`...`u_15`, `beta`,
`tau`, `rho`) are posterior medians.

**Join behavior.** PHQ9 is left-joined onto the parameter table by `(prolific_id, time)`.

## 3. Priors

Defined in the `.stan` file's `model {}` block.

| Parameter | Prior |
|---|---|
| `beta_location` | Half-Normal(0, 3) |
| `beta_scale` | Half-Normal(0, 2) |
| `beta` (subject) | Normal(`beta_location`, `beta_scale`) truncated at 0, non-centered |
| `tau_location` | Normal(0, 2) |
| `tau_scale` | Half-Normal(0, 2) |
| `tau` (subject) | Normal(`tau_location`, `tau_scale`), non-centered |
| `rho_location` | Normal(0, 3) |
| `rho_scale` | Half-Normal(0, 2) |
| `rho` (subject) | Normal(`rho_location`, `rho_scale`), non-centered |
| `u_raw` | Normal(0, 1), then standardized per subject |

## 4. Outputs

- `output/diagnostic_time1.pdf`, `output/diagnostic_time2.pdf` — ESS/R-hat table, trank plot, pairs plot for the six population parameters.
- `output/test-retest across sessions/` — time1 vs time2 scatters for utilities, `beta`, `tau`, `rho`, PHQ9 sum and items; `test_retest_summary.pdf`.
- `output/relations between parameters/` — u vs `tau`/`beta`/`rho`, `beta` vs `tau`, `beta` vs `rho`, `tau` vs `rho` (per wave); PHQ9 sum and PHQ9 item SD vs `beta`/`tau`/`rho`; utility vs mapped PHQ9 item; `parameter_relationships_summary.pdf`. PHQ9 vs subject mean utility is not plotted: utilities are standardized to mean 0 within subject, so that mean is ~0 for everyone.
- `output/test-retest across sessions/key_repeat_prop_test_retest_scatter.png` — descriptive: proportion of trials on which the participant pressed the same key (left / right / skip) as on the previous trial, time1 vs time2. Computed within block: the first trial of each block has no previous trial and is not counted. Trial-level flags in `artifacts/key_repeat_trials.csv`, proportions in `artifacts/key_repeat_proportion.csv`.
- `output/relations between parameters/tau_vs_rho_skip_flag_time1` / `_time2` (.pdf, .png) — tau vs rho per session, with participants who chose skip on at least 85% of that session's trials (`skip_flag_threshold` in `main.R`) in green; Pearson r with and without them. Per-participant skip proportions and flags in `artifacts/tau_rho_skip_flag.csv`.
- `output/repeat types vs rho/` — rho compared between key repeaters (A->A, B->B) and neither repeaters (skip->skip), per session. Raw repeat rates over within-block consecutive pairs, chance rates from each participant's own choice frequencies (key: pA^2 + pB^2; neither: pNeither^2), excess = raw - chance. Quartile tables, correlations and a joint standardized regression of rho on both excess rates, a Welch test of rho in the top key vs top neither quartile, and an intercept check of whether neither repeating explains the positive average rho. Everything is shown for all participants and for those with at least `min_neither_trials` (10, set in `main.R`) neither choices. Report: `repeat_types_vs_rho.md`; tables as CSV; per-participant rates in `artifacts/repeat_types.csv`. `rho_by_repeat_type_dot_histogram` (.pdf, .png): dot histogram of rho per session for A/B repeaters (A->A or B->B on at least `repeater_threshold`, 60%, of within-block consecutive pairs), neither repeaters (skip->skip on at least 60%), and everyone else in grey. Descriptive only: the A/B group has 1 (time 1) and 3 (time 2) participants, too few for a test. Group membership in `artifacts/repeater_groups.csv`.
- `output/choice and stay rates/` — descriptive dot histograms, one dot per participant, Time 1 and Time 2 side by side, red line = median (A = left, B = right, neither = skip). `choice_share_dot_histograms` (.pdf, .png): percentage of all trials on which the participant chose A, B, neither. `stay_rate_dot_histograms` (.pdf, .png): of the trials with neither / A / B / (A or B), the percentage followed by the same response on the next trial; for "A or B", switching A -> B counts as staying. "Next trial" is within block, so a block's last trial is not counted. A stay rate is undefined for participants who never made that choice, and those participants are left out of that panel (n shown per panel). Per-participant values in `artifacts/choice_stay_rates.csv`.
- `artifacts/participant_parameters.csv` — the participant-level table.

## 5. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
