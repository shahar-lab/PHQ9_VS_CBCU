# Simulation Notebook: Sample Size Determination for the PHQ9 Total-Score ICC (Literature-Grounded Sigmas)

**Model:** single hierarchical brms model, `y ~ 1 + (1 | subject)`, `family = gaussian()`
**Date Created:** 2026-09-14

## 1. Hypotheses / Goal

Determine how many subjects are needed for the posterior of the PHQ9 total-score
test-retest reliability (ICC) to reach an acceptably narrow width. This is a simplified,
single-task variant of the sibling `reliability_difference_sample_size_ICC` study: rather
than sweeping arbitrary target ICCs and differencing two tasks' posteriors, this study
fixes the generative variance components to literature-reported values for PHQ9 and
estimates a single ICC posterior directly.

## 2. Design

### Generative model (per subject)

* Fixed, literature-grounded variance components (not swept, not re-drawn per iteration):
  * `sigma_e = 1.8` (within-subject / measurement SD) -- matches the directly-reported SEM
    (1.83) from a Hebrew PHQ-9 validation study (general population, ICC(2,1) = 0.81;
    medRxiv 2021.07.13.21260485).
  * `sigma_0 = 3.57` (between-subject SD) -- derived as `sqrt(4.0^2 - 1.8^2) ≈ 3.57` so that
    total variance matches the general-population total SD (~4.0) reported in Kocalevent,
    Hinz & Brähler (2013, *General Hospital Psychiatry* 35(5):551-555, German nationally
    representative sample, N = 5,018; PubMed 23664569).
  * `mean_phq9 = 3.75` (population mean) -- roughly the midpoint of the literature's
    3.5-4.0 range for general-population PHQ9 totals.
  * Implied ICC: `sigma_0^2 / (sigma_0^2 + sigma_e^2) ≈ 0.80`, consistent with the
    published ICC ≈ 0.81-0.82 in the source study above, and cross-checked against a 2025
    meta-analysis reporting pooled PHQ-9 test-retest reliability of 0.82 (PMC11977096).
* Per subject: `subject_intercept ~ Normal(mean_phq9, sigma_0)`, one draw per subject.
* Unlike the item-level ICC sibling, there is no item dimension here: `y` is the PHQ9
  **total score** (`phq9_sum`, 0-27 range) directly, not an item response. Long format,
  one row per subject per time (2 rows per subject total):
  `y_time1 = subject_intercept + Normal(0, sigma_e)`,
  `y_time2 = subject_intercept + Normal(0, sigma_e)` -- independent residual draws for
  each time point, no systematic time1-vs-time2 difference, consistent with a test-retest
  reliability assumption of no practice/order effect.

### Estimation model

```r
brm(
  formula = y ~ 1 + (1 | subject),
  family  = gaussian(),
  prior   = priors,
  chains  = 4, iter = 2000, warmup = 1000,
  backend = "cmdstanr", cores = 4
)
```

A random-intercept-only model with no fixed-effect predictor and no random slope, fit
once per sample size to the single PHQ9 long-format dataset (no separate CBCU fit, since
this study has only one task). Per posterior draw, ICC is computed as:

```r
icc_draws <- sd_subject__Intercept^2 / (sd_subject__Intercept^2 + sigma^2)
```

where `sd_subject__Intercept` is the posterior draws of the between-subject (random
intercept) SD and `sigma` is the posterior draws of the residual SD -- verified against
brms's draw-naming convention for a random-intercept-only model, matching the ICC
sibling's per-task fits (same model structure, just one task here instead of two).

### Priors (user-approved)

```r
prior(normal(4, 2), class = "Intercept")
prior(cauchy(0, 1), class = "sd")
```

* `Intercept ~ normal(4, 2)` -- unlike the sibling ICC study, the simulated data here is
  **not** centered at 0. `y` is on PHQ9's real 0-27 total-score scale, generated around
  `mean_phq9 = 3.75`, so a prior centered near that population mean (with enough spread to
  stay weakly informative) is appropriate instead of the sibling's `normal(0, 1)`, which
  assumed zero-centered synthetic data.
* `sd ~ cauchy(0, 1)` -- same weakly-informative half-Cauchy as the sibling, applied to
  `sd_subject` via the shared `class = "sd"` prior (brms truncates to positive values
  automatically). No `b` or `cor` prior needed, since this model has no fixed-effect
  predictor and only one random effect (the intercept).

### Target statistic

For each sample size, from that fit's `icc_draws` (a single task's ICC posterior, not a
difference between two tasks), compute the median ICC and the HDI width (upper - lower)
at 85%, 90%, and 95% credible levels via `ggdist::median_hdi`. As a sanity check, the
median ICC should center near the implied value of ≈ 0.80 across sample sizes, with the
HDI narrowing as N increases.

### Sweep

* Sample sizes: `N in {50, 100, 200, 500, 1000}`.
* **Single fit per sample size** -- no `n_iterations` loop, no repeated draws to average
  over. This differs from the sibling ICC study's 10-iterations-per-N design. The
  sibling swept variance components were themselves target parameters being explored, so
  iterating and averaging served to marginalize out sampling noise around an otherwise
  arbitrary choice. Here, `sigma_0`, `sigma_e`, and `mean_phq9` are fixed,
  literature-derived constants rather than something to sweep or marginalize sampling
  noise over, so a single simulate+fit per N is sufficient and intentional -- per the
  user's explicit instruction ("only one iteration"). The sweep therefore loops only over
  `sample_sizes`, with no inner iteration dimension, no `iteration` column, and no
  `expand_grid(sample_size, iteration)` structure.
* No `seed` argument to `brm()` and no `set.seed()` anywhere in the R code -- every run
  draws fresh random samples, per the lab's convention for simulation studies.

### Convergence tracking

With one brms fit per sample size (five fits total in the sweep), convergence is tracked
inline, matching the sibling study's approach: each fit's maximum Rhat across all
parameters and its number of divergent transitions are computed right after fitting and
added as columns to the results table (`max_rhat`, `n_divergent` in `sweep_results`) --
a single set of columns, since there is only one fit per sample size (not two tasks'
worth, as in the sibling).

## 3. Findings / Summary

* (Leave this section blank until the sweep has been run and results reviewed).
