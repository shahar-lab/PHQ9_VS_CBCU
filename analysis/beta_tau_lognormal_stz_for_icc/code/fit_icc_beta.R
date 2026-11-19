#### ICC OF BETA ACROSS DAYS, ACCOUNTING FOR POSTERIOR UNCERTAINTY ####
# reads:  artifacts/beta_draws_by_wave.rds (written by plot_beta_test_retest_posterior.R)
# writes: artifacts/beta_icc_data.csv, artifacts/brms_icc_beta_me.rds,
#         output/diagnostic_icc_beta.pdf,
#         output/test-retest across sessions/icc_beta.csv,
#         output/test-retest across sessions/icc_beta_posterior.png
#
# Hypothesis 2, eq. [3] and [4], with a measurement layer added:
#   measurement: log_beta_hat_ij ~ Normal(log_beta_ij, se_ij^2)
#                log_beta_hat_ij = posterior mean of log(beta), participant i, day j
#                se_ij           = posterior SD of log(beta), treated as known
#   model [3]:   log_beta_ij = b_0 + b_0i + e_ij
#                b_0i ~ Normal(0, sigma_b^2)   between-subject
#                e_ij ~ Normal(0, sigma_e^2)   within-subject, net of estimation error
#   ICC [4]:     sigma_b^2 / (sigma_b^2 + sigma_e^2), computed per posterior draw
# No day effect: a shift shared by everyone on day 2 goes into sigma_e^2 (absolute agreement).
# Fit on log(beta): beta is lognormal in the choice model and its posteriors are right-skewed,
# so the mean and SD summarise log(beta) much better than beta.

library(brms)

icc_threshold <- 0.80   # Hypothesis 2: ICC > 0.80

#### 1. DATA: POSTERIOR MEAN AND SD OF LOG(BETA) PER PARTICIPANT X DAY ####

beta_draws_by_wave <- readRDS(file.path(artifacts_dir, "beta_draws_by_wave.rds"))

# Participants with both days
shared_ids <- intersect(colnames(beta_draws_by_wave$time1), colnames(beta_draws_by_wave$time2))

df_beta_icc <- imap(beta_draws_by_wave, \(draws, wave) {
  log_draws <- log(draws[, shared_ids])
  tibble(id          = shared_ids,
         day         = wave,
         log_beta    = colMeans(log_draws),
         se_log_beta = apply(log_draws, 2, sd))
}) |>
  list_rbind() |>
  mutate(id = factor(id), day = factor(day))

write_csv(df_beta_icc, file.path(artifacts_dir, "beta_icc_data.csv"))

# Size of estimation error relative to the spread of the point estimates, per day
df_noise_ratio <- df_beta_icc |>
  group_by(day) |>
  summarise(n_participants = n(),
            mean_se2       = mean(se_log_beta^2),
            var_estimates  = var(log_beta),
            noise_ratio    = mean_se2 / var_estimates)
print(df_noise_ratio)

#### 2. PRIORS AND FIT ####

# All on the log(beta) scale. brms truncates sd and sigma priors at 0 (half-Student-t).
priors_beta_icc <- c(
  set_prior("normal(1.5, 1)",     class = "Intercept"),              # b_0: beta ~ 4.5, 95% range ~0.6 to 32
  set_prior("student_t(3, 0, 1)", class = "sd", group = "id"),       # sigma_b
  set_prior("student_t(3, 0, 1)", class = "sigma")                   # sigma_e
)

# se(..., sigma = TRUE): each row's variance is sigma_e^2 + se^2, with se known
fit_beta_icc <- brm(
  log_beta | se(se_log_beta, sigma = TRUE) ~ 1 + (1 | id),
  data       = df_beta_icc,
  family     = gaussian(),
  prior      = priors_beta_icc,
  chains     = n_chains,
  cores      = n_chains,
  warmup     = 1000,
  iter       = 3000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_beta_me"),
  file_refit = "on_change"
)

#### 3. CONVERGENCE AND POSTERIOR PREDICTIVE CHECKS ####

hyper_names <- c("b_Intercept", "sd_id__Intercept", "sigma")
draws_hyper <- as_draws_array(fit_beta_icc, variable = hyper_names)

# posterior:: explicitly: brms masks rhat() and rstan (loaded by brms) masks ess_bulk()/ess_tail()
convergence_table <- summarise_draws(draws_hyper, median = median, sd = sd,
                                     rhat     = posterior::rhat,
                                     ess_bulk = posterior::ess_bulk,
                                     ess_tail = posterior::ess_tail)
convergence_table[-1] <- round(convergence_table[-1], 3)

n_divergent  <- nuts_params(fit_beta_icc) |> filter(Parameter == "divergent__") |> pull(Value) |> sum()
max_rhat_all <- max(rhat(fit_beta_icc), na.rm = TRUE)   # includes all 185 b_0i

print(convergence_table)
cat("Divergent transitions:", n_divergent, "| max R-hat over all parameters:", round(max_rhat_all, 3), "\n")

# Predictions include the known se, so they are comparable with the observed point estimates
yrep <- posterior_predict(fit_beta_icc, ndraws = 1000)

# Test-retest correlation of the point estimates: the quantity the ICC is about
idx_day1 <- which(df_beta_icc$day == "time1")
idx_day2 <- which(df_beta_icc$day == "time2")
idx_day2 <- idx_day2[match(df_beta_icc$id[idx_day1], df_beta_icc$id[idx_day2])]
retest_r <- function(y) cor(y[idx_day1], y[idx_day2])

ppc_density <- ppc_dens_overlay(df_beta_icc$log_beta, yrep[1:100, ]) +
  labs(title = "Posterior predictive: log(beta) point estimates")
ppc_sd_day  <- ppc_stat_grouped(df_beta_icc$log_beta, yrep, group = df_beta_icc$day, stat = "sd") +
  labs(title = "Posterior predictive: SD of log(beta) per day")
ppc_retest  <- ppc_stat(df_beta_icc$log_beta, yrep, stat = retest_r) +
  labs(title = "Posterior predictive: day 1 vs day 2 correlation", x = "Pearson r")

pdf(file.path(output_dir, "diagnostic_icc_beta.pdf"), width = 8, height = 6)
grid.arrange(tableGrob(convergence_table),
             top = sprintf("Divergent transitions: %d | max R-hat (all parameters): %.3f",
                           n_divergent, max_rhat_all))
print(mcmc_rank_overlay(draws_hyper))
print(mcmc_pairs(draws_hyper))
print(ppc_density)
print(ppc_sd_day)
print(ppc_retest)
dev.off()

#### 4. ICC PER POSTERIOR DRAW ####

draws_df_hyper <- as_draws_df(fit_beta_icc, variable = hyper_names)
sigma_b2       <- draws_df_hyper$sd_id__Intercept^2
sigma_e2       <- draws_df_hyper$sigma^2
icc_beta_draws <- sigma_b2 / (sigma_b2 + sigma_e2)

icc_beta_table <- tibble(
  parameter        = "log(beta)",
  model            = "random intercept + measurement error (se)",
  n_participants   = length(shared_ids),
  icc_median       = median(icc_beta_draws),
  icc_lower_95     = quantile(icc_beta_draws, 0.025),
  icc_upper_95     = quantile(icc_beta_draws, 0.975),
  p_icc_above_0.80 = mean(icc_beta_draws > icc_threshold),
  sigma_b_median   = median(sqrt(sigma_b2)),
  sigma_e_median   = median(sqrt(sigma_e2))
)
print(icc_beta_table)
write_csv(icc_beta_table, file.path(output_retest_dir, "icc_beta.csv"))

p_icc_beta <- ggplot(tibble(icc = icc_beta_draws), aes(x = icc)) +
  geom_histogram(bins = 60, fill = "#4477AA", colour = "white", alpha = 0.85) +
  geom_vline(xintercept = icc_threshold, linetype = "dashed", colour = "grey40") +
  geom_vline(xintercept = icc_beta_table$icc_median, colour = "#EE6677", linewidth = 0.8) +
  annotate(
    "text",
    x = -Inf, y = Inf,
    label = sprintf("[ICC median = %.2f, 95%% CrI %.2f to %.2f]\n[P(ICC > %.2f) = %.2f]",
                    icc_beta_table$icc_median, icc_beta_table$icc_lower_95,
                    icc_beta_table$icc_upper_95, icc_threshold, icc_beta_table$p_icc_above_0.80),
    hjust = -0.05, vjust = 1.3,
    size = 3.5, colour = "grey30"
  ) +
  coord_cartesian(xlim = c(0, 1)) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "ICC of log(beta), day 1 vs day 2", y = "Posterior draws")

ggsave(
  file.path(output_retest_dir, "icc_beta_posterior.png"),
  plot = p_icc_beta,
  width = 8, height = 5, dpi = 300, bg = "white"
)
