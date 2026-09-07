# Simulation Notebook: Sample Size Determination for the CBCU-vs-Likert Reliability Difference

**Model:** two separate hierarchical brms models, `y_time1 ~ y_time2 + (y_time2 | subject)`, `family = gaussian()`
**Date Created:** 2026-09-07

## 1. Hypotheses / Goal

Determine how many subjects are needed for the posterior of the DIFFERENCE between the
CBCU task's test-retest reliability and a Likert measure's test-retest reliability to
reach an acceptably narrow width (the PI's target is roughly 0.2).

## 2. Design

### Generative model (per subject)

* `personal_likert_correlation ~ Normal(0.6, 0.2)`, clipped to `[-0.99, 0.99]`.
* `personal_cbcu_correlation ~ Normal(0.85, 0.2)`, clipped to `[-0.99, 0.99]`.
* Per subject, via `MASS::mvrnorm(mu = c(0, 0), Sigma = matrix(c(1, r, r, 1), nrow = 2))`
  (variance = 1 for both variables, so the covariance term `r` equals the correlation
  exactly and the data is already standardized, mean 0 / SD 1):
  - 9 pairs `(likert_time1, likert_time2)` at that subject's `personal_likert_correlation`.
  - 15 pairs `(cbcu_time1, cbcu_time2)` at that subject's `personal_cbcu_correlation`.

### Estimation model

Fit separately to the Likert dataset and the CBCU dataset (identical formula/priors/
sampling settings, only the input data differs):

```r
brm(
  formula = y_time1 ~ y_time2 + (y_time2 | subject),
  family  = gaussian(),
  prior   = priors,
  chains  = 4, iter = 2000, warmup = 1000,
  backend = "cmdstanr", cores = 4
)
```

Because the simulated data is standardized (mean 0, SD 1), the **fixed-effect slope for
`y_time2`** (`b_y_time2`) is directly the population-level correlation estimate -- this
is the target quantity, NOT the random-effects intercept-slope correlation.

### Priors (user-approved)

```r
prior(normal(0, 1),   class = "Intercept")
prior(normal(0, 0.5), class = "b", coef = "y_time2")
prior(cauchy(0, 1),   class = "sd")
prior(lkj(1),         class = "cor")
```

* `Intercept ~ normal(0, 1)` -- the simulated data is centered at 0 by construction, so a
  weakly-informative prior centered at 0 matches the known scale without pre-judging the
  estimate.
* `b (y_time2) ~ normal(0, 0.5)` -- this coefficient is read directly as a correlation, so
  a prior with most of its mass roughly within [-1, 1] is weakly informative for a
  correlation-like quantity without being so wide it destabilizes sampling.
* `sd ~ cauchy(0, 1)` -- a standard weakly-informative half-Cauchy for random-effect
  standard deviations (brms truncates this to positive values automatically); heavy-tailed
  enough to not overly constrain between-subject variability.
* `cor ~ lkj(1)` -- uniform over the space of correlation matrices, i.e. uninformative
  about the random-effects (intercept, slope) correlation, consistent with the prior used
  in the sibling `sample_size_determination` simulation.

### Target statistic

For each simulated replicate: `difference_draws <- cbcu_draws - likert_draws` (the two
fixed-effect posteriors, subtracted draw-for-draw). From `difference_draws`, compute the
median difference and the HDI width (upper - lower) at 85%, 90%, and 95% credible levels
via `ggdist::median_hdi`. As a sanity check, the median difference should center near
`0.85 - 0.6 = 0.25` across iterations, though individual replicates will vary.

### Sweep

* Sample sizes: `N in {50, 100, 200, 500, 1000}`.
* 10 iterations (replicates) per sample size -- 50 total replicates, each requiring 2
  brms fits (Likert + CBCU) = 100 total fits.
* No `seed` argument to `brm()` and no `set.seed()` anywhere in the R code -- every run
  draws fresh random samples, per the lab's convention for simulation studies.

### Convergence tracking

With 100 brms fits in the sweep, the lab's usual one-`diagnostic.pdf`-per-model pattern
does not scale. Instead, convergence is tracked inline: each fit's maximum Rhat across
all parameters and its number of divergent transitions are computed right after fitting
and added as columns to the results table (`likert_max_rhat`, `likert_n_divergent`,
`cbcu_max_rhat`, `cbcu_n_divergent` in `sweep_results`), rather than produced as
per-fit diagnostic files.

## 3. Findings / Summary

* (Leave this section blank until the sweep has been run and results reviewed).
