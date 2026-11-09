# Analysis Notebook: posterior_predictive_checks

**Models checked:**
1. `models/bradley_terry_beta_tau`: no perseveration (job `analysis/beta_tau_pairwise`).
2. `models/bradley_terry_beta_tau_rho`: perseveration weight `rho`, no decay (`key_decay` fixed at 0; job `analysis/beta_tau_rho_pairwise`).
3. `models/bradley_terry_beta_tau_per`: `rho` plus `key_decay` (job `analysis/beta_tau_per_pairwise`).

**Date Created:** 2026-11-09

## 1. Why this analysis

The LOO comparison (`analysis/loo_comparison_three_models`) ranks the three models, but it cannot say whether any of them reproduces the
features of the data we care about, and about 11-12% of trials have Pareto k > 0.7 (almost all A/B trials in high-beta sessions with very
clean rankings). A posterior predictive check (PPC) asks a different question: **if the fitted model were the true process, would it
generate data that look like what we observed?** It has no Pareto-k problem, because nothing is left out and reweighted.

Why it fits this design: every participant sees 105 distinct pairs (15 items, each pair once), so there is no replication of any pair. Trial-level
checks are therefore weak, and the checks below compare **summary statistics per participant-session** instead.

## 2. Hypotheses

* H1. Each model reproduces the observed skip rate per participant-session (checks tau and the utilities).
* H2. Each model reproduces the observed rate of transitivity violations (checks beta: a very large beta predicts almost none, a smaller beta predicts some).
* H3. Only the perseveration models (2 and 3) reproduce the observed key repetition and run lengths (checks rho and key_decay).
* Exploratory: where the models differ in H1-H3, and whether misfit concentrates in the flagged (high-k) sessions.

## 3. Steps

Every step is written so a reader can follow the logic without the code. File names are the planned ones in `code/`.

### Step 1. Load the fits and the observed data (`prep_inputs.R`)
* Read the saved Stan fits for each model and wave: `bt_fit_*`, `bt_rho_fit_*`, `bt_per_fit_*`, for `time1` and `time2`, from the three jobs' `artifacts/` folders.
  Fits are **reused, not refit**.
* Read the observed trials (`data/processed/cbcu.csv`) and recode `choice` as in `prep_data.R`: 1 = A (left), 2 = B (right), 3 = None (skip).
* Order the trials per wave exactly as the fits were run: `arrange(prolific_id, block, trial)`. The `subject_lookup_*.csv` of each job must be identical
  across the three models (as already checked in the LOO job); stop if not.
* For each trial keep: participant, wave, trial number, the left item, the right item, and the observed choice. These are the **only fixed inputs** to the simulation:
  the simulated participant faces the same pairs in the same order.

### Step 2. Extract posterior draws (`extract_draws.R`)
* From each fit take a thinned subset of draws (about 100 draws, spread over the chains, the same draw indices for all models where possible).
* Per draw and participant keep the parameters each model uses:
  * all models: the 15 utilities (`u_matrix`, already normalized to mean 0 and SD 1 per participant inside the Stan model), `beta`, `tau`;
  * models 2 and 3: `rho`;
  * model 3: `key_decay`.
* Verify the parameter names against each `.stan` file when coding (model 2 declares `rho` directly, models 1 and 3 build it from non-centered terms).

### Step 3. Simulate new data from each draw (`simulate_ppc.R`)
For every draw, participant-session and model, replay the 105 trials in the observed order:
1. Compute the three log-weights, as in the Stan model:
   * A: `beta * u[item_left] + key_contrib[1]`
   * B: `beta * u[item_right] + key_contrib[2]`
   * None: `tau + key_contrib[3]`
   (`key_contrib` is zero for model 1.)
2. Convert the log-weights to probabilities (softmax) and **draw a choice** (A, B or None).
3. Perseveration update, using the **simulated** choice (not the observed one): decay the key values by `key_decay` (zero for model 2), then add `rho` to the slot just chosen. Reset at the start of each participant-session.
4. Store the simulated 105-trial sequence.

Two options for step 3.3 were considered: using the observed history (one-step-ahead prediction) or the simulated history (full sequence). We use the
**simulated history**, because it is the harder test and the one that checks sequence statistics such as runs. A one-step-ahead version can be added as a sensitivity check.

### Step 4. Compute summary statistics (`compute_statistics.R`)
For each observed and each simulated sequence, per participant-session:
* **Skip rate**: share of trials with None.
* **Transitivity violation rate**: among triads of items where all three pairs have an A/B answer, the share that form a cycle. Skips are treated as missing,
  as in the earlier transitivity checks. Sessions with fewer than 50 testable triads are marked as low-information and reported separately.
* **Key repetition**: share of consecutive answered trials that use the same key.
* **Longest run** of identical responses.
* **Left/right split** among answered trials.

### Step 5. Compare observed with simulated (`compare_ppc.R`)
* For each statistic and participant-session: the simulated distribution (100 values) and the observed value.
* **Posterior predictive p-value**: the share of simulated values at least as large as the observed one (two-sided version as the share outside the central 90% band).
* Summaries per model: the share of participant-sessions whose observed value lies **outside the 90% band** (about 10% is expected if the model is adequate).
* Break the results down by flagged versus non-flagged sessions (flags from `analysis/loo_comparison_three_models/output/participant_pareto_k_flags.csv`) and by number of skips.

### Step 6. Plots and tables (`plot_ppc.R`)
* Per statistic and model: observed value (x) against simulated median with 90% band (y), one point per participant-session.
* Per statistic: the distribution of posterior predictive p-values (should be roughly uniform if the model is adequate; a pile at 0 or 1 signals misfit).
* A table of the share outside the band, per statistic, model and subgroup.
* Example panels for the participants discussed earlier (`632222532c12ab0ab7ca00bd`, `5d68c8aa40524c00189e8ac2`).

### Step 7. Interpretation (to fill after running)
* Which statistics each model misses, and whether models 2 and 3 fix what model 1 misses (H3).
* Whether the transitivity check reveals a beta that is too large or too small (H2).
* Whether the misfit sits in the flagged sessions.

## 4. Limitations to keep in mind

* **The data are used twice.** A PPC on the fitted data is optimistic and can only catch gross misfit. Passing it does not prove the model is right.
* **It does not solve the beta identification problem.** For sessions with a perfectly consistent ranking, any large beta predicts "no violations", so the check cannot tell
  that beta is too large. Fixing that requires a tighter prior on beta, or repeated pairs in the design.
* **No trial-level conclusions.** Because no pair is repeated, the checks are about whole sessions.
* **Draws are thinned** (about 100), which is enough for 90% bands but not for tail probabilities.

## 5. Outputs (planned)

* `artifacts/observed_statistics.csv`, `artifacts/simulated_statistics.rds`: the statistics per participant-session (and draw).
* `output/ppc_summary_table.csv`: share outside the 90% band per statistic, model and subgroup.
* `output/ppc_*.pdf` / `.png`: the plots listed in step 6.

## 6. Findings / Summary

* (Leave this section blank until the code has been run.)
