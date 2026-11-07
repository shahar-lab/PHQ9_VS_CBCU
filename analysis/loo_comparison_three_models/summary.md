# Analysis Notebook: loo_comparison_three_models

**Models compared:**
1. `models/bradley_terry_beta_tau`: no perseveration (job `analysis/beta_tau_pairwise`).
2. `models/bradley_terry_beta_tau_rho`: perseveration weight `rho`, no decay (`key_decay` fixed at 0; job `analysis/beta_tau_rho_pairwise`).
3. `models/bradley_terry_beta_tau_per`: `rho` plus `key_decay` (job `analysis/beta_tau_per_pairwise`).

**Date Created:** 2026-11-06

## 1. Hypotheses

Does perseveration improve out-of-sample predictive fit of the 3-way (A / B / None) choices, and if so, does it need a decay parameter or is a one-trial (rho-only) effect enough?

## 2. Design notes

* **Fits are reused, not refit here.** The job reads the saved fits (`bt_fit_*`, `bt_rho_fit_*`, `bt_per_fit_*`, for `time1` and `time2`)
  from the three jobs' `artifacts/` folders. All three `.stan` files now have a `generated quantities` block with trial-level `log_lik`,
  so the three jobs must be (re-)run before this one.
* **Observation unit: trial.** PSIS-LOO (`loo` package) on pointwise `log_lik`.
* **Session ignored.** Each model's time1 and time2 fits are stacked column-wise so all trials of both waves form one
  set of observations (the waves are independent fits; draw *i* of time1 is placed next to draw *i* of time2).
  The jobs' subject-lookup CSVs are checked to be identical so trial order matches across models.
* **Caveat:** trial-level LOO conditions on the rest of the same participant's trials, which tends to favour models that
  capture each person's choice sequence (perseveration). A participant-level check was not requested.
* **Perseveration reset:** `key_value` resets between participants (flag `first_trial_of_subject`), not between blocks.

## 3. Outputs

* `output/loo_comparison.csv`: `elpd_diff` and `se_diff` (relative to the best model), `elpd_loo`, `p_loo`, `looic` for the three models.
* `output/pareto_k_diagnostics.pdf`: Pareto-k plot, one page per model.
* `artifacts/loo_objects.rds`: the three `loo` objects.

## 4. Findings / Summary

* (Leave this section blank until the code has been run.)
