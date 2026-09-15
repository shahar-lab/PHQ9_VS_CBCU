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

## 3. Findings / Summary

* (Leave this section blank until the model is completely fitted and evaluated).
