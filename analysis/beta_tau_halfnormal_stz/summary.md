# Analysis Notebook: beta_tau_halfnormal_stz

**Model:** `models/bradley_terry_beta_tau_halfnormal_stz/bradley_terry_beta_tau_halfnormal_stz.stan` (Bradley-Terry utilities + burden threshold `tau` scaled by `beta`, sum-to-zero utilities, `beta` normal truncated at 0), fit to `data/processed/cbcu.csv`.
**Date Created:** 2026-11-18

## 1. Hypotheses

Refit `beta_tau_lognormal_stz` with a non-lognormal population distribution for `beta`
(requested by the PI). Everything else (model structure, data, pipeline, plots) is
unchanged. Compare with `analysis/beta_tau_lognormal_stz/` and with
`analysis/beta_tau_lognormal_stz_v2/`.

## 2. Design notes

**Cloned from `analysis/beta_tau_lognormal_stz`.** Same pipeline and plot conventions; only
the population distribution of `beta` and its hyperpriors differ.

**Choice rule.**
`logit(A) = beta * u[A]`, `logit(B) = beta * u[B]`, `logit(None) = beta * tau`.

**Beta: "half-normal" = normal truncated at 0.**
`beta ~ normal(beta_location, beta_scale) T[0, ]`. The hyperparameters are on the beta
scale itself (not log). Written non-centered, as in `bradley_terry_beta_tau_noncentered`:
`beta = beta_location + beta_scale * beta_raw`, where `beta_raw` is a standard normal with
lower bound `-beta_location / beta_scale` (keeps `beta > 0`). Because that bound depends on
the hyperparameters, the truncation's normalizing constant is added to the target
(`-N_subjects * normal_lccdf(0 | beta_location, beta_scale)`).
Strictly, a half-normal is the special case with location 0; with location ~4 this is a
truncated normal, with only a small part of its mass cut off at 0.

**Saved quantities.** `beta`, `tau`, `u_matrix` (subject x item), and `log_lik` (per trial)
are all transformed parameters, so they are in the saved draws.

**Two fits, one per wave.** Each wave (`time1`, `time2`) is fit once, pooling all
subjects in that wave, with its own subject-index lookup
(`artifacts/subject_lookup_time1.csv`, `artifacts/subject_lookup_time2.csv`).

**Sampling.** 4 chains, 2000 warmup, 4000 sampling iterations per wave (set in `main.R`).

**Posterior summary: median.** Participant-level estimates (`u_1`...`u_15`, `beta`,
`tau`) are posterior medians.

**Plots.** Beta plots keep the log axes of `beta_tau_lognormal_stz` (defined since
`beta > 0`), so the figures can be compared across models. The beta test-retest plot
splits at time 1 median beta = 7 (`beta_threshold_time1`); check that both panels have
enough participants and adjust if not.

**Join behavior.** PHQ9 is left-joined onto the parameter table by `(prolific_id, time)`.

## 3. Priors

Defined in the `.stan` file's `model {}` block.

| Parameter | Prior |
|---|---|
| `beta_location` | Normal(4, 0.9), lower bound 0 (beta scale) |
| `beta_scale` | Half-Normal(0, 1.1) (beta scale) |
| `beta` (subject) | Normal(`beta_location`, `beta_scale`) truncated at 0, non-centered |
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
- `output/clinical reports/` — five patients with different time 1 symptom profiles, one
  pilot-style page each (`clinical_report.pdf`, one PNG per patient). Patients are picked by
  k-medoids (PAM, k = 5) on Spearman distance between time 1 utility rankings, largest
  cluster first, the most central subject whose PHQ-9 sum is not already used (all five sums
  differ). Ladder: utility median and 90% HDCI, tiers where neighbours differ with
  probability ≥ 0.90. Burden threshold = tau (None beats an item when u < tau). Consistency =
  time 1 P(higher-utility option | not None). PHQ-9 bands: 0–4, 5–9, 10–14, 15–19, 20–27.
  `profile_clusters.csv` lists the picks and their cluster sizes. A sixth page is a
  higher-severity match: among subjects with time 1 PHQ-9 sum ≥ 10, the one whose utility
  ranking has the highest Spearman correlation with any of the five. Article version:
  profile 1 is left out (`profiles_excluded` in `prep_clinical_report.R`); the remaining
  five are numbered Patient 1–5 by PHQ-9 sum (`patient_key.csv` maps them to participant
  IDs, which are kept out of the figures). Each page: A ladder, B PHQ-9 sum on its bands,
  C choice consistency, D symptoms above the burden threshold; PDF and PNG per patient.

## 5. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
