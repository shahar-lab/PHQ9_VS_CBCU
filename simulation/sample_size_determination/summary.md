# Simulation Notebook: Sample Size Determination for CBCU Task Reliability

**Model:** brms bivariate correlation, `bf(y1 ~ 1) + bf(y2 ~ 1) + set_rescor(TRUE)`, `family = gaussian()`
**Date Created:** 2026-09-05

## 1. Hypotheses / Goal

Determine how many participants are needed to estimate the CBCU task's test-retest
reliability (a Pearson-type correlation between two administrations) with adequate
credible-interval precision.

## 2. Design

* True Pearson r = 0.85 (per the user's PI), representing CBCU task reliability.
* Sample sizes: N in {50, 100, 200, 500, 1000}.
* 10 iterations (replicates) per sample size -- 50 total simulate+fit reps.
* Per replicate: N bivariate-normal pairs (y1, y2) drawn via `MASS::mvrnorm`,
  mean c(0, 0), unit variances, Sigma = matrix(c(1, 0.85, 0.85, 1), 2, 2).
* Priors: `prior(lkj(1), class = "rescor")`; intercept and sigma left at brms defaults.
* Sampling: 4 chains, 2000 iter, 1000 warmup, `backend = "cmdstanr"`, `cores = 4`.
* No `seed` passed to `brm()` and no `set.seed()` anywhere -- every run draws fresh
  random samples, per the lab's convention for this simulation.
* Per replicate, from the posterior draws of the residual correlation
  (`rescor__y1__y2`): posterior median r, and HDI width at 85%, 90%, and 95%
  credible levels (via `ggdist::median_hdi`).

## 3. Findings / Summary

* (Leave this section blank until the sweep has been run and results reviewed).
