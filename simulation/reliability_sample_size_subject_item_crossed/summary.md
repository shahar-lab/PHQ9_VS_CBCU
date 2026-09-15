# Simulation Notebook: Sample Size Determination for the Crossed Subject x Item Subject-ICC (CBCU Utilities & PHQ9 Items)

**Model:** two separate crossed hierarchical brms models, `y ~ 1 + (1 | subject) + (1 | item)`, `family = gaussian()`
**Date Created:** 2026-09-15

## 1. Hypotheses / Goal

Determine how many subjects are needed for the posterior of the subject-ICC (the
proportion of total variance attributable to between-subject differences, after
accounting for a crossed item-level variance component) to reach an acceptably narrow
width -- separately for TWO outcomes, CBCU utilities and PHQ9 items, each with its own
fixed generative variance components. This extends the single-random-effect
`sigmas_simulation_reliability_difference_sample_size` sibling by adding a second,
crossed random effect for item identity, and extends the two-task
`reliability_difference_sample_size_ICC` sibling by fitting two separate outcomes'
posteriors directly (rather than differencing them) and by crossing subjects with a
fixed item factor instead of a time factor.

## 2. Design

### Generative model (per outcome, per subject-item pair)

`y[subject, item] = grand_mean + subject_effect[subject] + item_effect[item] + residual`

* `subject_effect ~ Normal(0, sigma_subject)`, one draw per subject (not per
  subject-item pair).
* `item_effect ~ Normal(0, sigma_item)`, one draw per item (not per subject-item pair).
  Item is a FIXED set (15 items for CBCU, 9 items for PHQ9); the same `n_items` items
  are used across all subjects and across all sample sizes in the sweep -- item identity
  is not resampled per replicate, it is a fixed crossed factor.
* `residual ~ Normal(0, sigma_e)`, independent per (subject, item) row.
* Output: long format, one row per (subject, item) pair -- `n_subjects * n_items` rows
  total, columns `(subject, item, y)`.

### Fixed parameter values, per outcome (constants, not swept, not re-drawn per sample size)

**CBCU utilities:** `grand_mean = 0`, `sigma_subject = 1`, `sigma_item = 0.3`,
`sigma_e = 0.3`, `n_items = 15`.

* `n_items = 15` matches the fixed CBCU item pool size used consistently across this
  project's simulation studies (e.g. `bradley_terry_beta_tau_per_recovery`'s
  `N_options`), reflecting the actual number of CBC-U items being compared.
* `grand_mean = 0` and `sigma_subject = 1` match the standardized scale (mean 0, SD 1)
  of the true `u` parameter in the sibling `bradley_terry_beta_tau_per_recovery`
  simulation study, so the subject-level variance component here is directly comparable
  to that study's subject-utility scale.
* `sigma_item = 0.3` and `sigma_e = 0.3` are new additions for this crossed-model study
  specifically: the original `true_u` generative process in the `bradley_terry`
  sibling had no item-level variance component at all (items were independent
  standardized noise per subject, not a crossed factor with its own shared variance).
  Both are chosen as modest values relative to `sigma_subject = 1`, so this study can
  meaningfully test whether the crossed model recovers a genuine, if modest, item
  effect without swamping the subject signal.

**PHQ9 items:** `grand_mean = 1.5`, `sigma_subject = 1.17`, `sigma_item = 0.4`,
`sigma_e = 0.67`, `n_items = 9`.

* `n_items = 9` matches the PHQ-9 instrument's actual item count (`phq9_1`...`phq9_9`
  in `data/raw/phq9_results.csv` and `data/processed/phq9_results.csv`), and is also
  the divisor used in the `sqrt(9) ≈ 3` scaling below.
* Derived by scaling down the total-score-level `sigma_0`/`sigma_e` values used in the
  sibling `sigmas_simulation_reliability_difference_sample_size` study
  (`sigma_0 = 3.5`, `sigma_e = 2`, themselves PI-adjusted from originally
  literature-derived values of 3.57/1.8 -- see that sibling's summary.md for the full
  literature chain) by approximately `sqrt(9) ≈ 3`, since summing ~9 roughly-independent
  items multiplies variance by ~9 (so SD by ~3): `sigma_subject = 3.5 / 3 ≈ 1.17`,
  `sigma_e = 2 / 3 ≈ 0.67`.
* `sigma_item = 0.4` is a new, modestly-sized addition representing that some PHQ9
  items are more commonly endorsed than others on average (item difficulty variation)
  -- not present in the total-score-only sibling study, which had no item dimension.
* `grand_mean = 1.5` keeps items on PHQ9's natural 0-3 response scale (midpoint),
  rather than centering at 0, since a bounded ordinal item is already approximated as
  Gaussian regardless of centering, and staying on the real scale keeps results
  directly interpretable in PHQ9's own units.

**Plain-language walkthrough of the PHQ9 parameter choices:**

1. `n_items = 9` is simply a fact about the instrument -- PHQ9 has 9 questions, each
   scored 0-3. Not derived from anything, just the actual structure of the scale.
2. `sigma_subject` and `sigma_e` start from the *total-score* variance components
   already used in the `sigmas_simulation_reliability_difference_sample_size` sibling
   (`sigma_0 = 3.5`, `sigma_e = 2`, on the 0-27 summed scale). This study needs those
   same two ideas ("how much do people differ from each other" and "how much random
   noise is there") but expressed at the *item* level (0-3 scale) instead, since `y`
   here is one item's score, not the sum of all 9.
3. Converting total-score spread to item-level spread: when 9 roughly-independent
   quantities are summed, their *variances* add, so the total's variance is about
   `9 x` a single item's variance. Standard deviation (SD) is the square root of
   variance, so the total's SD ends up about `sqrt(9) = 3` times a single item's SD --
   not `9` times, because SD and variance are on different scales. Rearranging that
   relationship the other way (total SD -> item-level SD) means dividing by `sqrt(9) = 3`:
   `sigma_subject = 3.5 / 3 ≈ 1.17` ("how much people differ from each other on a
   single 0-3 item"), `sigma_e = 2 / 3 ≈ 0.67` ("how much unexplained noise is in a
   single item's score").
4. `sigma_item = 0.4` is NOT derived from the total-score numbers at all -- it is a
   genuinely new quantity that did not exist in the total-score-only sibling study,
   since that study had no concept of "item." It represents that some PHQ9 questions
   are, on average, answered higher than others across everyone (e.g. "little interest
   in things" tends to score higher across the general population than "thoughts of
   self-harm"). `0.4` was chosen as a modest, reasonable-looking value -- smaller than
   `sigma_subject`, since item-to-item average differences are usually less dramatic
   than person-to-person differences -- not calculated from any external source.
5. `grand_mean = 1.5` is simply the midpoint of the 0-3 response scale.

Put together, for every simulated (subject, item) pair the model generates a score as:
`1.5 (grand_mean) + [how much this subject tends to score higher/lower than others,
spread = 1.17] + [how much this item tends to score higher/lower than others, spread
= 0.4] + [random leftover noise for this specific person-item combination, spread =
0.67]`.

**Caveat:** the `sqrt(9)` scaling in step 3 is a rough approximation, not an exact
calculation -- it assumes the 9 PHQ9 items are roughly equally variable and
independent of each other, which is a simplification (real items differ in how
discriminating they are, and are likely somewhat correlated since they all measure
depression). It is a reasonable way to obtain plausible item-level numbers in the
absence of published item-level statistics, but should be treated as a working
assumption, not a validated estimate.

### Estimation model (same formula for both outcomes, fit separately)

```r
brm(
  formula = y ~ 1 + (1 | subject) + (1 | item),
  family  = gaussian(),
  prior   = priors,
  chains  = 4, iter = 2000, warmup = 1000,
  backend = "cmdstanr", cores = 4
)
```

Fit once per sample size per outcome (CBCU and PHQ9 each get their own sweep of five
fits, using their own fixed constants and priors). Per posterior draw, subject-ICC --
the proportion of TOTAL variance attributable to between-subject differences,
accounting for the item variance component too (NOT item-ICC, NOT subject+item
combined) -- is computed as:

```r
icc_draws <- sd_subject__Intercept^2 /
  (sd_subject__Intercept^2 + sd_item__Intercept^2 + sigma^2)
```

where `sd_subject__Intercept` and `sd_item__Intercept` are the posterior draws of the
between-subject and between-item (random intercept) SDs, and `sigma` is the posterior
draws of the residual SD -- verified against brms's draw-naming convention for a
crossed two-random-intercept model with grouping factors literally named `subject` and
`item`: each group-level SD draw column is named `sd_<group>__<term>`, extending the
two single-random-effect siblings' verified `sd_subject__Intercept`/`sigma` pattern
with an additional `sd_item__Intercept` column for the crossed item factor.

### Priors -- per outcome (grand_mean/scale differs), separate `sd` priors per random-effect group

**CBCU utilities priors:**

```r
prior(normal(0, 1), class = "Intercept")
prior(cauchy(0, 1), class = "sd", group = "subject")
prior(cauchy(0, 1), class = "sd", group = "item")
```

**PHQ9 items priors:**

```r
prior(normal(1.5, 1), class = "Intercept")
prior(cauchy(0, 1), class = "sd", group = "subject")
prior(cauchy(0, 1), class = "sd", group = "item")
```

The `Intercept` prior is centered at each outcome's own `grand_mean`, weakly
informative, mirroring the two single-random-effect siblings' practice of matching the
prior's center to the data's known generative center. The `sd` priors are given
separately per group (`group = "subject"`, `group = "item"`) rather than one shared
`class = "sd"` prior, since subject and item variances are expected to differ in scale
-- especially for PHQ9 (`sigma_subject ≈ 1.17` vs `sigma_item = 0.4`) -- so
group-specific priors let each group's posterior be shaped independently rather than
sharing one prior across both scales.

### Target statistic

For each sample size, from that fit's `icc_draws` (a single outcome's subject-ICC
posterior), compute the median ICC and the HDI width (upper - lower) at 85%, 90%, and
95% credible levels via `ggdist::median_hdi`. 90% is the primary target credible level
per the user; all three are kept for consistency with both siblings' output format.

### Sweep

* Sample sizes: `N in {50, 100, 200, 500, 1000}` -- same grid as both siblings.
* **Single fit per sample size, per outcome** -- no `iteration` loop, no
  `n_iterations`, no `expand_grid(sample_size, iteration)`, matching the most recent
  `sigmas_simulation_reliability_difference_sample_size` sibling's precedent: all ten
  generative parameters (five per outcome) are now fixed, chosen constants, not
  something to marginalize sampling noise over via repeated replicates.
* The sweep runs TWICE -- once for CBCU utilities' parameters, once for PHQ9 items'
  parameters -- producing two separate results tables
  (`sweep_results_cbcu.rds`/`.csv` and `sweep_results_phq9.rds`/`.csv`), not a
  combined or differenced result. Each outcome's sweep uses a shared
  `run_outcome_sweep()` helper (parameterized by that outcome's generative constants
  and priors) to avoid duplicating the sweep loop body across the two outcomes.
* No `seed` argument to `brm()` and no `set.seed()` anywhere in the R code -- every
  run draws fresh random samples, per the lab's convention for simulation studies.

### Convergence tracking

With one brms fit per sample size per outcome (ten fits total across both sweeps),
convergence is tracked inline, matching both siblings' approach: each fit's maximum
Rhat across all parameters and its number of divergent transitions are computed right
after fitting and added as columns to that outcome's results table (`max_rhat`,
`n_divergent` in `sweep_results_cbcu` / `sweep_results_phq9`) -- a single set of
convergence columns per table, since each table holds only one outcome's fits.

## 3. Findings / Summary

* (Leave this section blank until both sweeps have been run and results reviewed).
