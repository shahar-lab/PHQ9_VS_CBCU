# Simulation Notebook: Sample Size Determination for the CBCU-vs-PHQ9 ICC Reliability Difference

**Model:** two separate hierarchical brms models, `y ~ 1 + (1 | subject)`, `family = gaussian()`
**Date Created:** 2026-09-14

## 1. Hypotheses / Goal

Determine how many subjects are needed for the posterior of the DIFFERENCE between the
CBCU task's test-retest reliability (ICC) and the PHQ9 measure's test-retest reliability
(ICC) to reach an acceptably narrow width. This is the ICC-based counterpart to the
sibling `reliability_difference_sample_size` study, which used Pearson correlation
instead of ICC as the reliability metric.

## 2. Design

### Generative model (per subject, per task)

* Population target ICC (PI-assumed): `ICC_cbcu = 0.8`, `ICC_phq9 = 0.6`.
* ICC is defined as `tau^2 / (tau^2 + sigma^2)`, where `tau` is the between-subject SD
  (random-intercept SD) and `sigma` is the within-subject (residual) SD. `sigma` is fixed
  at 1 for both tasks, and `tau` is solved from the target ICC:
  `tau = sqrt(ICC / (1 - ICC))` -- `tau_cbcu ≈ 2.00`, `tau_phq9 ≈ 1.22`.
* Per subject: `subject_intercept ~ Normal(0, tau)`, one draw per subject per task.
* Item-level observations, long format: for each subject, `time` in `{1, 2}` and `item` in
  `1:n_items` (15 items for CBCU, 9 items for PHQ9, matching the tasks' actual item
  counts), `y = subject_intercept + Normal(0, sigma)` -- an independent residual draw for
  every (subject, time, item) row. time1 and time2 are generated identically (same
  subject_intercept, same residual distribution) -- no systematic time1-vs-time2
  difference is simulated, consistent with a test-retest reliability assumption of no
  practice/order effect.

### Estimation model

Fit separately to the CBCU long-format dataset and the PHQ9 long-format dataset
(identical formula/priors/sampling settings, only the input data differs):

```r
brm(
  formula = y ~ 1 + (1 | subject),
  family  = gaussian(),
  prior   = priors,
  chains  = 4, iter = 2000, warmup = 1000,
  backend = "cmdstanr", cores = 4
)
```

This is a random-intercept-only model with no fixed-effect predictor and no random
slope -- distinct from the sibling study's `y_time1 ~ y_time2 + (y_time2 | subject)`
reliability-as-slope model. Per posterior draw, ICC is computed as:

```r
icc_draws <- sd_subject__Intercept^2 / (sd_subject__Intercept^2 + sigma^2)
```

where `sd_subject__Intercept` is the posterior draws of the between-subject (random
intercept) SD and `sigma` is the posterior draws of the residual SD -- this directly
matches the ratio-of-variances ICC definition (between-subject variance divided by
between-subject variance plus within-subject variance), not any other variance ratio or
a rescaled slope.

### Priors (user-approved)

```r
prior(normal(0, 1), class = "Intercept")
prior(cauchy(0, 1), class = "sd")
```

* `Intercept ~ normal(0, 1)` -- the simulated data is centered at 0 by construction (both
  `subject_intercept` and the residual are zero-mean), so a weakly-informative prior
  centered at 0 matches the known scale without pre-judging the estimate.
* `sd ~ cauchy(0, 1)` -- a standard weakly-informative half-Cauchy for the random-intercept
  SD (brms truncates this to positive values automatically), applied to `sd_subject` via
  the shared `class = "sd"` prior; heavy-tailed enough to not overly constrain
  between-subject variability. No `b` (fixed-slope) or `cor` (random-effects correlation)
  prior is needed, since this model has no fixed-effect predictor and only one random
  effect (the intercept), unlike the sibling study's random-slope model.

### Target statistic

For each simulated replicate: `icc_difference_draws <- cbcu_icc_draws - phq9_icc_draws`
(the two tasks' posterior ICC draws, subtracted draw-for-draw). From
`icc_difference_draws`, compute the median difference and the HDI width
(upper - lower) at 85%, 90%, and 95% credible levels via `ggdist::median_hdi`. As a
sanity check, the median difference should center near `0.8 - 0.6 = 0.2` across
iterations, though individual replicates will vary.

### Sweep

* Sample sizes: `N in {50, 100, 200, 500, 1000}`.
* 10 iterations (replicates) per sample size -- 50 total replicates, each requiring 2
  brms fits (CBCU + PHQ9) = 100 total fits.
* No `seed` argument to `brm()` and no `set.seed()` anywhere in the R code -- every run
  draws fresh random samples, per the lab's convention for simulation studies.

### Convergence tracking

With 100 brms fits in the sweep, the lab's usual one-`diagnostic.pdf`-per-model pattern
does not scale. Instead, convergence is tracked inline: each fit's maximum Rhat across
all parameters and its number of divergent transitions are computed right after fitting
and added as columns to the results table (`cbcu_max_rhat`, `cbcu_n_divergent`,
`phq9_max_rhat`, `phq9_n_divergent` in `sweep_results`), rather than produced as
per-fit diagnostic files.

## 3. Findings / Summary

* (Leave this section blank until the sweep has been run and results reviewed).
