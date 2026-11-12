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

---

## 7. Accuracy of the non-centered models (added 2026-11-11)

**Entry point:** `main_accuracy_noncentered.R` (independent of `main.R`; code files `code/noncentered_*.R`; outputs in `output/accuracy_noncentered/`).

**Models compared:**
1. `models/bradley_terry_beta_tau_noncentered` (job `analysis/beta_tau_noncentered`): no perseveration.
2. `models/bradley_terry_beta_tau_rho_noncentered` (job `analysis/beta_tau_rho_noncentered`): one-trial perseveration `rho`.

Both fits are reused, not refit. Note that in these models the None weight is `beta * tau` (not `tau` as in the older pairwise models), and `rho` is
a bonus for the previous trial's response only (no decay).

### Question
For each participant, on what share of trials does the model predict the response the participant actually gave? How is that share distributed
across participants for each model, and how differently do the two models predict?

### Steps
1. **Inputs** (`noncentered_prep_inputs.R`). Observed trials per wave, ordered as in the fits (`arrange(prolific_id, block, trial)`). Stops if the two jobs'
   subject lookups differ.
2. **Draws** (`noncentered_extract_draws.R`). 1000 posterior draws per fit (same seeded indices for both models): `beta`, `tau`, `u_matrix`, and `rho`
   (set to 0 for beta_tau). Cached in `artifacts/noncentered_draws.rds`, because the fits are 1.5-2.7 GB each.
3. **Prediction** (`noncentered_predict_accuracy.R`). For every draw, participant-session and trial, the probabilities of A, B and None are computed
   exactly as in the Stan model. The `rho` bonus goes to the **observed** previous response (one-step-ahead prediction). This is how the model is fit,
   and it is the fair test of whether the model predicts the next response. (The full-sequence simulation in `main.R` lets rho follow its own simulated history,
   which removes most of what rho can predict.)
   * **Posterior predictive accuracy (main measure).** Per draw, one response is drawn on every trial from the model's probabilities. Accuracy is the share
     of trials where the drawn response equals the observed one. Across the 1000 draws this gives the posterior predictive distribution of the participant's
     accuracy, summarised by its mean and central 90% interval.
   * **Best-guess accuracy.** The single most probable response per trial (posterior-mean probabilities), compared with the observed response.
   * Both sessions are pooled per participant (up to 210 trials); per-session means are also reported.
4. **Histograms per model** (`noncentered_plot_accuracy.R`). One value per participant (the mean of their accuracy distribution), with the median
   participant and chance (1/3) marked.
5. **Comparison** (`noncentered_compare_accuracy.R`). Per participant: the accuracy difference (beta_tau_rho minus beta_tau) with a 90% interval over draws,
   the best-guess difference, the **agreement** between the two models' best guesses (how differently they predict, whoever is right), and the difference
   plotted against the participant's `rho`.

### Outputs (`output/accuracy_noncentered/`)
* `accuracy_per_participant.csv`: per model and participant: posterior predictive accuracy (mean, 5%, 95%, per session) and best-guess accuracy (all trials, A/B trials, skip trials).
* `accuracy_summary_by_model.csv`: per model: group mean accuracy with its posterior predictive 90% interval, median, range, best-guess accuracy.
* `accuracy_histogram_beta_tau.pdf/.png`, `accuracy_histogram_beta_tau_rho.pdf/.png`: the histogram per model (page 2 of the PDF: best-guess accuracy).
* `accuracy_group_mean_distribution.pdf`: posterior predictive distribution of the group mean accuracy, both models.
* `accuracy_model_comparison_per_participant.csv`, `accuracy_model_comparison_summary.csv`: the comparison numbers.
* `accuracy_model_comparison.pdf/.png`: (A) both histograms on a shared axis, (B) participant-by-participant scatter, (C) histogram of the difference,
  (D) difference against `rho`; page 2: agreement between the models' best guesses, best-guess scatter.

### Limitations
* The data are used twice (the same trials fit the model and are predicted), so the accuracies are optimistic. They describe how well each model accounts for the data,
  not how well it would predict new trials.
* Posterior predictive accuracy includes the randomness of drawing a response, so it is lower than best-guess accuracy whenever the model is uncertain.
  A model that put probability 0.6 on the right response every trial would score about 60% on the first measure and 100% on the second.

### Findings (run 2026-11-11, 185 participants, 1000 draws per fit)
* **Both models predict most responses.** Posterior predictive accuracy averages 89.8% (90% interval 89.5-90.0%) for beta_tau and 90.0% (89.8-90.3%) for
  beta_tau_rho. The median participant is at 91.2% under both models. Best-guess accuracy is higher: 94.4% vs 94.7% on average, median 95.7% for both.
* **The histograms are nearly identical.** Most participants are between 85% and 100%. A tail of 16-17 participants falls below 80%, with the lowest at 48% (beta_tau) and 52% (beta_tau_rho).
  No participant is near chance (33%).
* **The two models predict almost the same responses.** Their best guesses agree on 98.4% of trials on average (lowest participant: 75%). Per-participant
  accuracies correlate at r = 0.997 between the models.
* **rho adds a small but consistent gain.** beta_tau_rho is higher for 152 of 185 participants, but the gain is small: mean +0.27 percentage points (pp), median +0.13 pp.
  The group-level 90% interval of the gain (-0.07 to +0.63 pp) includes 0. No single participant's 90% interval excludes 0, because each interval also carries the
  randomness of drawing a response. On best-guess accuracy, rho is better for 69 participants, equal for 80 and worse for 36.
* **The gain concentrates in the poorly fit participants.** Gains of 2-6 pp occur only among participants whose beta_tau accuracy is below about 80%. The gain is only weakly
  related to the participant's posterior mean rho (r = 0.17). Some of the largest gains come from participants with rho near 0 or even negative, so rho may be absorbing
  other misfit there, not only key repetition.
