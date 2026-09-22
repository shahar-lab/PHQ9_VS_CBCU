# Simulation Notebook: Bradley-Terry Beta Tau -- Parameter Recovery

**Model:** `models/bradley_terry_beta_tau/bradley_terry_beta_tau.stan`
**Date Created:** 2026-07-25

## 1. Hypotheses
Full parameter-recovery check for the Bradley-Terry Beta Tau model: can the hierarchical
Stan model recover per-subject utilities (u), choice sensitivity (beta), and the no-choice
burden threshold (tau) from simulated 3-way (A / B / None) choice data?

## 2. Design
* N_subjects = 100, N_options = 15, N_trials per subject = 105 (10500 trials total).
* Ground-truth group-level hyperparameters (fixed, not randomly drawn):
  `mu_log_beta = 0.5`, `sigma_log_beta = 1`, `mu_tau = 0`, `sigma_tau = 1`.

* Per-subject true utilities: `rnorm(N_options)` standardized per subject to mean 0 / sd 1.
* Per-subject true beta: `rlnorm(N_subjects, meanlog = mu_log_beta, sdlog = sigma_log_beta)`.
* Per-subject true tau: `rnorm(N_subjects, mean = mu_tau, sd = sigma_tau)`.
* No `set.seed()` used anywhere (explicit user instruction) -- each run draws fresh truth.
* Data simulated via `sim.block()` per subject, choice factor (A/B/None) recoded to
  integer 1/2/3 for Stan's `categorical_logit`.
* Fit via cmdstanr: 4 chains, parallel_chains = 4, iter_warmup = 3000, iter_sampling = 2000.
* `code/generate_truth.R` and `code/simulate_data.R` were merged into a single `code/simulated_data.R`
  (parameters defined first, then simulation) -- no behavioral change, same values as before.
* `code/plot_generative_distributions.R` (new): a sanity-check figure, `output/generative_distributions.pdf/.png`,
  showing the generated `true_beta` and `true_tau` values as dot histograms with their theoretical density
  overlaid (lognormal(mu_log_beta, sigma_log_beta) for beta; normal(mu_tau, sigma_tau) for tau) -- confirms
  the simulated draws actually follow the distributions they are meant to come from. Two panels (A: beta,
  B: tau), x-axis widened 10% past the observed range on each panel since neither distribution has a
  real finite bound.
* `code/plot_tau_vs_pct_none.R` (new): a scatter, `output/tau_vs_pct_none.pdf/.png`, of each subject's true
  tau against their percentage of "None" choices in the generative data, with Pearson r annotated --
  no `coord_equal()`/diagonal reference line, since tau and percent-None are on different scales.
* `code/plot_group_recovery.R` (updated): each of the 4 group-level hyperparameter panels now shows a
  THIRD dashed reference line, "Sample statistic (subjects)" (blue), alongside the existing "True value"
  (red) and "Posterior median" (grey) lines -- computed directly from the individual subjects' true draws:
  `mean(log(true_beta))` for the `mu_log_beta` panel, `sd(log(true_beta))` for `sigma_log_beta` (log scale,
  since these two hyperparameters parameterize `log(beta)`, not raw `beta`), `mean(true_tau)` for `mu_tau`,
  `sd(true_tau)` for `sigma_tau`. Lets the reader compare three things per panel: the population's true
  generating hyperparameter, what the Stan model recovered from the choice data (posterior median), and
  the empirical value computed directly from the sampled subjects (which will differ from the true
  hyperparameter by finite-sample noise even before any fitting happens).

## 3. Findings / Summary (latest run, post code-merge)

**Stale -- configuration changed, not yet re-run.** The simulation parameters were updated to
N_subjects = 100, N_trials per subject = 105, iter_warmup = 3000, iter_sampling = 2000. The
findings below reflect the prior N_subjects = 20 / N_trials = 200 / iter_warmup = 1000 /
iter_sampling = 3000 configuration and no longer describe the current setup. This section
should be treated as stale until the simulation is re-run under the new settings and the
results here are replaced with fresh numbers.
