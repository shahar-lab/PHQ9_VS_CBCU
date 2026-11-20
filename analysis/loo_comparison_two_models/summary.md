# Analysis Notebook: loo_comparison_two_models

**Models compared:**
1. `lognormal`: `models/bradley_terry_beta_tau_lognormal_stz_v2` (job `analysis/beta_tau_lognormal_stz_v2`).
   `beta` lognormal; `beta_location ~ normal(1.25, 0.25)`, `beta_scale ~ half-normal(0, 0.35)` (log scale).
2. `halfnormal`: `models/bradley_terry_beta_tau_halfnormal_stz` (job `analysis/beta_tau_halfnormal_stz`).
   `beta` normal truncated at 0; `beta_location ~ normal(4, 0.9)`, `beta_scale ~ half-normal(0, 1.1)` (beta scale).

Everything else (utilities, `tau`, choice rule, data) is identical, so any difference comes from the
population distribution of `beta` and its hyperpriors.

**Date Created:** 2026-11-18

## 1. Hypotheses

Which population distribution for `beta` predicts the held-out A / B / None choices better: lognormal or
normal truncated at 0 ("half-normal")?

## 2. Design notes

**Cloned from `analysis/loo_comparison_three_models`** (its section 5 run: `noncentered_beta_tau_vs_beta_tau_rho`).
`prep_log_lik.R`, `compute_loo.R` and `plot_pareto_k.R` are unchanged; `compare_by_participant.R` is adapted
(see below).

* **Fits are reused, not refit here.** Reads `fit_time1.rds` and `fit_time2.rds` from each job's `artifacts/`;
  both jobs' `main.R` must be run first. `log_lik` is computed in each model's `transformed parameters`.
* **Observation unit: trial.** PSIS-LOO (`loo` package) on pointwise `log_lik`.
* **Waves stacked.** Each model's time1 and time2 fits are stacked column-wise so all trials of both waves form one
  set of observations. The jobs' subject-lookup CSVs are checked to be identical so trial order matches across models.
* **Per-session breakdown** (`code/compare_by_participant.R`). Pointwise elpd is summed per wave and per
  participant-session; difference = **halfnormal minus lognormal** (positive = half-normal better),
  SE = sd of trial differences x sqrt(n). Instead of `rho` (the earlier comparison), the difference is plotted
  against each session's `beta`, since `beta` is what differs between the models.
* **Sensitivity check.** The comparison is repeated without the sessions where more than 10% of trials have
  Pareto k > 0.7 (`k_threshold`, `flag_share` in `main.R`).
* **Memory.** Each fit is ~3 GB on disk and is loaded one at a time; the stacked `log_lik` matrices are a few GB
  per model.

## 3. Outputs

* `output/loo_comparison.csv`: `elpd_diff`, `se_diff`, `elpd_loo`, `p_loo`, `looic` for the two models.
* `output/pareto_k_diagnostics.pdf`: Pareto-k plot per model.
* `output/elpd_diff_by_wave.csv`: the difference for time1, time2 and both.
* `output/elpd_diff_by_pareto_k_flag.csv`: the difference in flagged vs non-flagged sessions.
* `output/elpd_diff_per_participant_session.csv` / `.pdf` / `.png`: per participant-session difference,
  Pareto-k shares, `beta` and `tau` from both models, flag. Figure: (A) histogram of the per-session
  difference, (B) difference vs the session's `beta` (lognormal model), (C) `beta` in the two models,
  coloured by the difference.
* `output/beta_agreement_by_tau_bin.pdf` / `.png`: panel C split into 5 panels by tau. Each participant's tau
  (posterior median, lognormal model) is averaged over their sessions, and participants are split into 5
  equal-count bins (quintiles) of that mean; both sessions of a participant fall in the same bin. All panels
  share the same x and y range and are square (`n_tau_bins` in `code/compare_by_participant.R`).
* `output/tau_bins_per_participant.csv`: each participant's mean tau, number of sessions and tau bin.
* `artifacts/loo_objects.rds`: the two `loo` objects.

## 4. Findings / Summary

* (Leave this section blank until both models are fitted and this comparison is run).
