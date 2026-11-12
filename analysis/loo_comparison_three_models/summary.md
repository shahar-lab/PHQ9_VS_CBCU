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

* Three pairwise models (run before 2026-11-11, outputs at the top level of `output/`): beta_tau_per best; beta_tau_rho -52.5 (SE 15.3); beta_tau -164.8 (SE 20.0).
  `output/participant_pareto_k_flags.csv` belongs to this run and is still read by `analysis/posterior_predictive_checks/main.R`.

---

## 5. Non-centered models: beta_tau vs beta_tau_rho (added 2026-11-11)

`main.R` now runs this comparison. The three-model outputs above are left in place. This run writes to
`output/noncentered_beta_tau_vs_beta_tau_rho/` and `artifacts/noncentered_beta_tau_vs_beta_tau_rho/`.

**Models compared:**
1. `models/bradley_terry_beta_tau_noncentered` (job `analysis/beta_tau_noncentered`): no perseveration.
2. `models/bradley_terry_beta_tau_rho_noncentered` (job `analysis/beta_tau_rho_noncentered`): one-trial perseveration `rho`.

**Question.** Does the one-trial perseveration bonus improve out-of-sample (leave-one-trial-out) prediction of the A / B / None choices?

**Design.** The design is the same as sections 2-3: the fits are reused (`fit_time1.rds`, `fit_time2.rds` from each job), `log_lik` is computed in each model's `transformed parameters`,
the observation unit is the trial, and the two waves are stacked. Added in this run:
* `code/compare_by_participant.R`: the pointwise elpd is summed per wave and per participant-session (difference = beta_tau_rho minus beta_tau,
  SE = sd of trial differences x sqrt(n)), and plotted against the session's `rho`.
* A sensitivity check: the comparison is repeated without the sessions where more than 10% of trials have Pareto k > 0.7 (`k_threshold`, `flag_share` in `main.R`).

**Outputs** (`output/noncentered_beta_tau_vs_beta_tau_rho/`):
* `loo_comparison.csv`: `elpd_diff`, `se_diff`, `elpd_loo`, `p_loo`, `looic` for the two models.
* `pareto_k_diagnostics.pdf`: Pareto-k plot per model.
* `elpd_diff_by_wave.csv`: the difference for time1, time2 and both.
* `elpd_diff_by_pareto_k_flag.csv`: the difference in flagged vs non-flagged sessions.
* `elpd_diff_per_participant_session.csv` / `.pdf` / `.png`: per participant-session difference, Pareto-k shares, `beta`, `tau`, `rho`, flag.

**Findings** (run 2026-11-11, 185 participants x 2 waves = 38,850 trials)
* **beta_tau_rho is better**: elpd_diff = **+110.6 (SE 16.2)**, about 6.8 SE. elpd_loo is -8792.6 for beta_tau_rho and -8903.2 for beta_tau; p_loo is 3228 vs 3149.
  The gain appears in both waves: time1 +68.8 (SE 12.9), time2 +41.9 (SE 9.8).
* **It is not driven by unreliable LOO estimates.** Pareto k > 0.7 occurs on 8.7% of trials (beta_tau) and 9.8% (beta_tau_rho). In the 234 sessions with reliable LOO (at most 10% of trials
  with k > 0.7) the gain is +100.7 (SE 15.0). The 136 flagged sessions add only +9.9 (SE 6.1).
* **The gain comes from a small minority of sessions.** beta_tau_rho is higher in 186 of 370 participant-sessions, i.e. about half. The top 20 sessions (5%) supply 97% of the total gain.
  The difference exceeds 2 SE in favour of beta_tau_rho in 22 sessions, and in favour of beta_tau in 16.
* **The gain tracks the size of rho in either direction.** Sessions with rho > 0.5 (30 sessions) gain +99.9 in total. Sessions with rho at or below 0 (32) gain +19.7. The
  three sessions with rho around -0.5 to -0.8 are alternators: they tend to switch responses. Sessions with small positive rho (0 to 0.25, 137 sessions) lose -46.5 in total:
  there, rho adds a parameter without predicting anything. Spearman correlation of the gain with rho: 0.61.
* **This agrees with the posterior predictive accuracy** (`analysis/posterior_predictive_checks`, section 7). Accuracy hardly changes on average (+0.27 percentage points), and the participants
  who gain are the same few with strong positive or negative rho. elpd rewards better-calibrated probabilities as well as more correct predictions, so it detects the
  improvement more clearly than accuracy does.
