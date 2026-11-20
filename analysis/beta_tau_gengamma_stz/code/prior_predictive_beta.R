#### PRIOR PREDICTIVE CHECK: POPULATION OF BETA ####
# reads: nothing (simulation only: no data, no Stan)
# writes: output/prior_predictive_beta.png, artifacts/prior_predictive_beta_quantiles.csv
#
# Simulates the population distribution of beta implied by the hyperpriors in
# models/bradley_terry_beta_tau_gengamma_stz/*.stan. The numbers in prior_beta must match
# the .stan file's model block.
#   A: prior predictive of beta for a new subject (one beta per hyperparameter draw)
#   B: population densities of log(beta), one per hyperparameter draw - the shapes the
#      prior allows
#   C: skewness of log(beta) as a function of beta_Q (0 = lognormal), with the prior
#      median and 95% interval of beta_Q
#
# Generalized gamma, as in the .stan file:
#   log(beta) = mu + sigma * z,  z = (log(G) - digamma(k)) / sqrt(trigamma(k)),
#   G ~ gamma(k, 1),  k = 1 / Q^2

prior_beta <- list(
  mu_mean  = 1.4, mu_sd = 0.3,        # beta_mu    ~ normal(1.4, 0.3)
  sigma_sd = 0.4,                     # beta_sigma ~ half-normal(0, 0.4)
  Q_mean   = 1,   Q_sd  = 0.6,        # beta_Q     ~ normal(1, 0.6), bounded to [0.2, 3]
  Q_lower  = 0.2, Q_upper = 3
)
n_prior_draws      <- 20000   # hyperparameter draws (one new-subject beta per draw)
n_population_lines <- 40      # population curves in panel B

set.seed(20261119)

# Normal truncated to [lower, upper], by inverse CDF
r_truncated_normal <- function(n, mean, sd, lower, upper) {
  qnorm(runif(n, pnorm(lower, mean, sd), pnorm(upper, mean, sd)), mean, sd)
}

# Standardized log-gamma (mean 0, SD 1, left-skewed), one draw per element of k
r_standard_log_gamma <- function(k) {
  g <- rgamma(length(k), shape = k)
  g <- pmax(g, .Machine$double.xmin)   # rgamma can underflow to 0 when k is small
  (log(g) - digamma(k)) / sqrt(trigamma(k))
}

# Density of log(beta) at y, for one set of hyperparameters
d_log_beta <- function(y, mu, sigma, Q) {
  k <- 1 / Q^2
  x <- digamma(k) + sqrt(trigamma(k)) * (y - mu) / sigma   # log(G)
  exp(k * x - exp(x) - lgamma(k)) * sqrt(trigamma(k)) / sigma
}

# Skewness of log(beta): depends on Q only. 0 = lognormal, -2 = the limit as Q grows.
skewness_log_beta <- function(Q) {
  k <- 1 / Q^2
  psigamma(k, 2) / trigamma(k)^1.5
}

df_prior <- tibble(
  mu    = rnorm(n_prior_draws, prior_beta$mu_mean, prior_beta$mu_sd),
  sigma = abs(rnorm(n_prior_draws, 0, prior_beta$sigma_sd)),
  Q     = r_truncated_normal(n_prior_draws, prior_beta$Q_mean, prior_beta$Q_sd,
                             prior_beta$Q_lower, prior_beta$Q_upper)
) |>
  mutate(beta_new = exp(mu + sigma * r_standard_log_gamma(1 / Q^2)))

# Quantiles of the prior predictive of beta, plus the share of very low / high values
quantile_probs <- c(0.01, 0.025, 0.10, 0.25, 0.50, 0.75, 0.90, 0.975, 0.99)
df_prior_quantiles <- tibble(
  statistic = c(paste0("q", 100 * quantile_probs), "share_below_1", "share_above_15"),
  value     = c(quantile(df_prior$beta_new, quantile_probs, names = FALSE),
                mean(df_prior$beta_new < 1), mean(df_prior$beta_new > 15))
)
print(df_prior_quantiles, n = Inf)
write_csv(df_prior_quantiles, file.path(artifacts_dir, "prior_predictive_beta_quantiles.csv"))

# Panel A: prior predictive of beta (log axis, so the density is per log10 unit)
beta_breaks <- c(0.1, 0.3, 1, 3, 10, 30, 100)
p_prior_beta_new <- ggplot(df_prior, aes(x = beta_new)) +
  geom_histogram(aes(y = after_stat(density)), bins = 80,
                 fill = "#4477AA", colour = "white", linewidth = 0.2) +
  geom_vline(xintercept = median(df_prior$beta_new), linetype = "dashed", colour = "grey30") +
  scale_x_log10(breaks = beta_breaks, labels = as.character(beta_breaks)) +
  coord_cartesian(xlim = c(0.1, 100)) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "beta of a new subject (log axis)", y = "Density",
       title = "Prior predictive of beta", subtitle = "Dashed line: median")

# Panel B: population curves for a few hyperparameter draws
log_beta_grid <- seq(log(0.1), log(100), length.out = 400)
df_population_lines <- df_prior |>
  slice_head(n = n_population_lines) |>
  mutate(draw = row_number()) |>
  reframe(
    log_beta = log_beta_grid,
    density  = d_log_beta(log_beta_grid, mu, sigma, Q),
    .by      = c(draw, mu, sigma, Q)
  )

p_prior_population <- ggplot(df_population_lines,
                             aes(x = exp(log_beta), y = density, group = draw)) +
  geom_line(colour = "#4477AA", alpha = 0.45, linewidth = 0.6) +
  scale_x_log10(breaks = beta_breaks, labels = as.character(beta_breaks)) +
  coord_cartesian(ylim = c(0, quantile(df_population_lines$density, 0.995))) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "beta (log axis)", y = "Density of log(beta)",
       title = "Population shapes allowed by the prior",
       subtitle = sprintf("%d draws of (mu, sigma, Q)", n_population_lines))

# Panel C: what Q means for the shape
Q_prior_quantiles <- quantile(df_prior$Q, c(0.025, 0.5, 0.975), names = FALSE)
df_skewness <- tibble(Q = seq(prior_beta$Q_lower, prior_beta$Q_upper, length.out = 200)) |>
  mutate(skewness = skewness_log_beta(Q))

p_prior_skewness <- ggplot(df_skewness, aes(x = Q, y = skewness)) +
  annotate("rect", xmin = Q_prior_quantiles[1], xmax = Q_prior_quantiles[3],
           ymin = -Inf, ymax = Inf, fill = "grey85") +
  geom_vline(xintercept = Q_prior_quantiles[2], linetype = "dashed", colour = "grey30") +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_line(colour = "#4477AA", linewidth = 1) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "beta_Q", y = "Skewness of log(beta)",
       title = "Shape parameter Q",
       subtitle = "0 = lognormal. Grey: prior 95% of Q, dashed: prior median")

p_prior_predictive_beta <- (p_prior_beta_new | p_prior_population | p_prior_skewness) +
  plot_annotation(tag_levels = "A")

ggsave(file.path(output_dir, "prior_predictive_beta.png"), plot = p_prior_predictive_beta,
       width = 18, height = 6, dpi = 300, bg = "white")
