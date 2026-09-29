#### MODEL: bradley_terry_beta_tau_per_indep — test-retest reliability ####
# Computes test-retest reliability from a cmdstanr fit of
# bradley_terry_beta_tau_per_indep.stan. Defines functions only (no top-level side
# effects) so it can be source()d from an analysis main.R. Requires tidyverse and
# posterior to be loaded.
#
# Two metrics:
# 1. ICC(2,1) (Schurr et al., 2024): on the posterior median of each
#    subject x session value, with a non-parametric bootstrap over subjects for
#    the 95% interval. Applied to beta, tau, key_decay, rho (natural scale) and to
#    each utility (u_matrix[1] vs u_matrix[2], ...).
# 2. Model-based ICC: eta^2 / (eta^2 + sigma^2) per posterior draw, for the four
#    scalars on the unconstrained scale where the independent model defines them
#    (log_beta, tau, logit_key_decay, rho). Reported as posterior median and 95%
#    interval.

# ICC(2,1), two-way random effects, absolute agreement, single measurement
# (Shrout & Fleiss, 1979). mat: [n subjects, k sessions], no missing values.
# The paper prints (BMS - EMS) / (BMS + (k - 1) * EMS); the full Shrout & Fleiss
# denominator used here also includes k * (JMS - EMS) / n, which penalizes a mean
# shift between sessions (e.g. a practice effect).
icc_2_1 <- function(mat){

  n <- nrow(mat)
  k <- ncol(mat)

  grand     <- mean(mat)
  row_means <- rowMeans(mat)
  col_means <- colMeans(mat)

  BMS <- k * sum((row_means - grand)^2) / (n - 1)
  JMS <- n * sum((col_means - grand)^2) / (k - 1)

  resid <- mat - outer(row_means, rep(1, k)) - outer(rep(1, n), col_means) + grand
  EMS   <- sum(resid^2) / ((n - 1) * (k - 1))

  (BMS - EMS) / (BMS + (k - 1) * EMS + k * (JMS - EMS) / n)
}

# ICC(2,1) point estimate plus bootstrap percentile interval over subjects.
icc_2_1_boot <- function(mat, n_boot){

  boot <- replicate(n_boot, {
    idx <- sample(nrow(mat), replace = TRUE)
    icc_2_1(mat[idx, , drop = FALSE])
  })

  tibble(
    estimate = icc_2_1(mat),
    lower_95 = unname(quantile(boot, 0.025, na.rm = TRUE)),
    upper_95 = unname(quantile(boot, 0.975, na.rm = TRUE))
  )
}

# Posterior medians of a Stan variable, with its bracket indices split into
# integer columns idx_1, idx_2, ... (e.g. beta[3,2] -> idx_1 = 3, idx_2 = 2;
# u_matrix[2,3,5] -> session 2, subject 3, option 5).
posterior_medians <- function(fit, variable){

  fit$summary(variable, median = median) |>
    mutate(idx = str_match(variable, "\\[(.*)\\]")[, 2]) |>
    separate_wider_delim(idx, delim = ",", names_sep = "_") |>
    mutate(across(starts_with("idx_"), as.integer))
}

compute_reliability <- function(fit, n_boot = 1000, seed = 1){

  set.seed(seed)

  #### ICC(2,1): scalars ####

  scalar_icc <- map(c("beta", "tau", "key_decay", "rho"), function(p) {
    med <- posterior_medians(fit, p)                  # idx_1 = subject, idx_2 = session
    mat <- matrix(NA_real_, nrow = max(med$idx_1), ncol = max(med$idx_2))
    mat[cbind(med$idx_1, med$idx_2)] <- med$median

    icc_2_1_boot(mat, n_boot) |>
      mutate(parameter = p, metric = "ICC(2,1)", .before = 1)
  }) |>
    list_rbind()

  #### ICC(2,1): utilities ####

  u_med <- posterior_medians(fit, "u_matrix")         # idx_1 = session, idx_2 = subject, idx_3 = option

  utility_icc <- map(sort(unique(u_med$idx_3)), function(j) {
    med <- filter(u_med, idx_3 == j)
    mat <- matrix(NA_real_, nrow = max(med$idx_2), ncol = max(med$idx_1))
    mat[cbind(med$idx_2, med$idx_1)] <- med$median

    icc_2_1_boot(mat, n_boot) |>
      mutate(parameter = paste0("u_", j), metric = "ICC(2,1)", .before = 1)
  }) |>
    list_rbind()

  #### Model-based ICC: eta^2 / (eta^2 + sigma^2) ####

  scalars_unconstrained <- c("log_beta", "tau", "logit_key_decay", "rho")

  draws <- fit$draws(
    c(paste0("eta_", scalars_unconstrained), paste0("sigma_", scalars_unconstrained)),
    format = "draws_df"
  )

  model_icc <- map(scalars_unconstrained, function(p) {
    eta   <- draws[[paste0("eta_", p)]]
    sigma <- draws[[paste0("sigma_", p)]]
    icc   <- eta^2 / (eta^2 + sigma^2)

    tibble(
      parameter = p,
      metric    = "model-based ICC",
      estimate  = median(icc),
      lower_95  = unname(quantile(icc, 0.025)),
      upper_95  = unname(quantile(icc, 0.975))
    )
  }) |>
    list_rbind()

  bind_rows(scalar_icc, utility_icc, model_icc)
}
