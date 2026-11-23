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

**Tau ICC with measurement error** (`code/fit_icc_tau_with_ms.R`, `code/diagnose_icc.R`,
`code/plot_icc_tau.R` → `output/test-retest across sessions/icc_tau.csv`,
`icc_tau_posterior.{pdf,png}`; `output/diagnostic_icc_tau.pdf`;
`artifacts/brms_icc_tau_me.rds`, `artifacts/tau_icc_data.csv`). Hypothesis 2, eq. [3]–[4] on
tau, two-step from the per-session fits, same structure as the beta ICC in
`analysis/beta_tau_lognormal_stz_for_icc/`. Per participant and day, the posterior mean of tau
is the outcome and its posterior SD is a known standard error:
`tau | se(se_tau, sigma = TRUE) ~ 1 + (1 | id)`, gaussian, no day effect (absolute
agreement). ICC = sd(id)² / (sd(id)² + sigma²) per posterior draw; reports median, 95% CrI and
P(ICC > 0.80). Priors (tau scale): Intercept ~ Normal(0, 1), sd(id) ~ Half-Normal(0, 1),
sigma ~ Half-Normal(0, 1). 4 chains, 3000 iterations (1000 warmup), adapt_delta 0.95.
185 participants with both days. The diagnostic PDF includes posterior predictive checks of
the point estimates, among them the day 1 vs day 2 correlation, the check that showed the
beta two-step ICC was too high.
A second version without the measurement layer (`code/fit_icc_tau_without_ms.R` →
`artifacts/brms_icc_tau_plain.rds`, `artifacts/tau_icc_data_plain.csv`,
`output/diagnostic_icc_tau_plain.pdf`) fits eq. [3] as written on the posterior medians of
tau from `participant_parameters.csv`: `tau ~ 1 + (1 | id)`, same priors and sampling.
`icc_tau.csv` has one row per version and `icc_tau_posterior` shows both posteriors.
Not fit on the joint model: `beta_tau_halfnormal_stz_joint`
has one tau per participant (sessions pooled), so it has no day 1 / day 2 values.
Diagnostics for all ICC models are written by `code/diagnose_icc.R`.

**Beta ICC without measurement error** (`code/fit_icc_beta_plain.R`, `code/plot_icc_beta.R` →
`output/test-retest across sessions/icc_beta.csv`, `icc_beta_posterior.{pdf,png}`;
`output/diagnostic_icc_beta_plain.pdf`; `artifacts/brms_icc_beta_plain.rds`,
`artifacts/beta_icc_data_plain.csv`). Eq. [3] as written on the posterior medians of beta from
`participant_parameters.csv`, on the raw beta scale (this model's population distribution for
beta is a truncated normal; the medians are left-skewed, more so on log):
`beta ~ 1 + (1 | id)`, gaussian, no day effect (absolute agreement). Priors (beta scale):
Intercept ~ Normal(4, 3) (centred on the choice model's beta_location prior),
sd(id) ~ Half-Normal(0, 3), sigma ~ Half-Normal(0, 3). Same sampling as the tau ICC.

**PHQ-9 sum score ICC** (`code/fit_icc_phq9_without_ms.R`, `code/plot_icc_phq9.R` →
`output/test-retest across sessions/icc_phq9.csv`, `icc_phq9_posterior.{pdf,png}`;
`output/diagnostic_icc_phq9.pdf`; `artifacts/brms_icc_phq9.rds`, `artifacts/phq9_icc_data.csv`).
Eq. [3] as written on the raw PHQ-9 sum score (0–27) from `participant_parameters.csv`, as a
benchmark for tau and beta. The sum is observed, so there is no measurement layer:
`phq9_sum ~ 1 + (1 | id)`, gaussian, no day effect (absolute agreement). Not centred: shifting
all scores by a constant moves only b_0, not sigma_b or sigma_e, so the ICC is unchanged.
Priors (PHQ-9 scale, set from the scale, not the data): Intercept ~ Normal(13.5, 7) (scale
midpoint), sd(id) ~ Half-Normal(0, 7), sigma ~ Half-Normal(0, 7). Same sampling as the tau ICC.

**Item-level utility ICC (agreement)** (`code/fit_icc_utility_without_ms.R`,
`code/diagnose_icc_utility.R`, `code/plot_icc_utility.R` →
`output/test-retest across sessions/icc_utility.csv`, `icc_utility_posterior.{pdf,png}`;
`output/diagnostic_icc_utility.pdf`; `artifacts/brms_icc_utility.rds`,
`artifacts/utility_icc_data.csv`).
*Data.* Posterior medians of u_1…u_15 from `participant_parameters.csv`, no measurement-error
layer; 185 participants with both occasions × 2 occasions × 15 items = 5,550 rows. Within each
participant × occasion the 15 utilities are centred to mean 0 and scaled to SD 1 (checked:
all 370 cells have mean 0 and SD 1 to machine precision).
*Model.* `utility ~ 1 + (1 | item) + (1 | participant:item) + (1 | occasion:item)`, gaussian.
No participant intercept and no participant × occasion term: the centring and scaling make
their variance exactly zero. The residual is the participant × occasion × item term.
Priors (standardised scale): Intercept ~ Normal(0, 1); sd(item), sd(participant:item),
sd(occasion:item) and sigma ~ Half-Normal(0, 1). 4 chains, 3000 iterations (1000 warmup),
adapt_delta 0.95, seed 2026, cmdstanr.
*ICC (agreement).* Per posterior draw, from squared SDs:
ICC = σ²(participant:item) / (σ²(participant:item) + σ²(occasion:item) + σ²(residual)).
The item variance is in neither the numerator nor the denominator. `icc_utility.csv` gives the
median and 95% CrI of the ICC and of each variance component (item variance included for
reference).
*Diagnostics.* ESS/R-hat table, divergences, rank plots and pairs plot for b_Intercept, the three
SDs and sigma in `diagnostic_icc_utility.pdf`. Run of 2026-11-23: 0 divergent transitions,
max R-hat 1.005 over all parameters, lowest bulk ESS 626 (b_Intercept).

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
