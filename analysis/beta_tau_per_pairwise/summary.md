# Analysis Notebook: beta_tau_per_pairwise

**Model:** `models/bradley_terry_beta_tau_per/bradley_terry_beta_tau_per.stan` (Bradley-Terry utilities + burden threshold `tau` + per-outcome perseveration `key_decay`/`rho`), fit to `data/processed/cbcu_results.csv`.
**Date Created:** 2026-09-15

## 1. Hypotheses

Produce one participant-level parameter table (Bradley-Terry item utilities, burden
threshold, choice sensitivity, perseveration) per wave, joined with PHQ9 scores, for
downstream PHQ9-vs-CBCU association analyses.

## 2. Design notes

**Two fits, one per wave, not per-subject fits.** `bradley_terry_beta_tau_per.stan`
is hierarchical: it estimates population-level hyperparameters
(`mu_log_beta`/`sigma_log_beta`, `mu_tau`/`sigma_tau`, `mu_logit_key_decay`/
`sigma_key_decay`, `mu_rho`/`sigma_rho`) that require pooling across multiple
subjects within a fit. Splitting into per-subject fits would leave those
hyperparameters unidentified without modifying the Stan model itself, which is out
of scope here. Each wave (`time1`, `time2`) is therefore fit once, pooling all
subjects present in that wave. The two waves use independent subject-index
mappings (`artifacts/subject_lookup_time1.csv`, `artifacts/subject_lookup_time2.csv`);
a subject's index in one wave's fit need not match their index in the other.

**Posterior summary: median, not mean.** Per the task specification, all
participant-level parameter estimates (`u_1`...`u_15`, `tau`, `beta`, `key_decay`,
`rho`) are posterior medians (`fit$summary(variable, median = median)`), not the
default posterior mean.

**Perseveration reported as two columns.** `key_decay` and `rho` are kept separate
(not combined into one perseveration index), matching the Stan model's two
distinct parameters.

**Small pilot sample size.** At the time this analysis was built, `cbcu_results.csv`
contained 9 unique `prolific_id` values, each appearing in both `time1` and
`time2`. This is exploratory/pilot-scale: hierarchical estimates at N=9 will carry
substantial uncertainty, and results should be treated as preliminary and expected
to sharpen as more data is collected. Re-running `main.R` after new data is added
will refit both waves against the then-current subject count.

**Join behavior.** `join_phq9_and_write.R` left-joins PHQ9 data onto the
Bradley-Terry table by `(prolific_id, time)`.
`# ASSUMED[no join-type given]`: the CBCU-based table defines the primary row
population; a `prolific_id` present in `phq9_results.csv` but absent from the CBCU
table is not added as a new row (not a full join).

## 3. Priors

Defined in `models/bradley_terry_beta_tau_per/bradley_terry_beta_tau_per.stan`, `model {}`
block (not in `code/fit_model.R`, which only calls `model$sample()` on the already-compiled
Stan model).

| Parameter | Prior | Justification (from the .stan file) |
|---|---|---|
| `mu_log_beta` | Normal(0, 2) | Group-level mean on the log-beta scale; not otherwise commented in the model file. |
| `sigma_log_beta` | Exponential(2) | Group-level SD on the log-beta scale; not otherwise commented in the model file. |
| `beta` (subject) | Lognormal(`mu_log_beta`, `sigma_log_beta`) | Lognormal keeps subject-level choice sensitivity strictly positive. |
| `mu_tau` | Normal(0, 2) | Group-level mean for the burden-threshold parameter; not otherwise commented. |
| `sigma_tau` | Exponential(2) | Group-level SD for `tau`; not otherwise commented. |
| `tau` (subject) | Normal(`mu_tau`, `sigma_tau`) | `tau` is left unconstrained (no lower/upper bound in `parameters {}`). |
| `mu_logit_key_decay` | Normal(0, 1.5) | `# ASSUMED[no scale given]` in the .stan file: logistic-transformed decay with a normal hyperprior on the logit scale, matching how `tau` is handled unconstrained — no scale for `key_decay` was specified elsewhere, so this was the model author's choice. |
| `sigma_key_decay` | Exponential(2) | Group-level SD on the logit scale for `key_decay`; not otherwise commented. |
| `logit_key_decay` (subject) | Normal(`mu_logit_key_decay`, `sigma_key_decay`) | Transformed via `inv_logit()` in `transformed parameters {}` so subject-level `key_decay` is constrained to (0, 1). |
| `mu_rho` | Normal(0, 2) | Group-level mean for the perseveration weight `rho`; not otherwise commented. |
| `sigma_rho` | Exponential(2) | Group-level SD for `rho`; not otherwise commented. |
| `rho` (subject) | Normal(`mu_rho`, `sigma_rho`) | `rho` is left unconstrained, like `tau`. |
| `u_raw` (utilities) | Normal(0, 1) | Commented in the .stan file as a "weak prior... to provide initial geometry before transformation" — `u_raw` is later standardized per subject to mean 0 / SD 1 in `transformed parameters {}` to produce `u_matrix`, so this prior only shapes the initial (unconstrained) geometry, not the final utility scale. |

## 4. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
