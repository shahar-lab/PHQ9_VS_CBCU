#### UTILITY UNCERTAINTY (HDI WIDTH) VS BETA AND TAU ####
# reads: artifacts/draws_sbj.rds, simulated_data.rds, true_parameters.rds
# writes: artifacts/u_hdi_width_by_subject.csv/.rds, output/12_u_hdi_width_vs_beta.pdf/png,
#         output/12_u_hdi_width_vs_tau.pdf/png
#
# Question: are a subject's utility estimates more uncertain when the subject's choices
# carry less information about the utility profile (lower beta, higher tau)?
#
# Per subject (and session):
#   1. 95% HDI of each of the 15 utilities, from the posterior draws of u_matrix[s, i]
#   2. HDI width = upper - lower, averaged over the 15 utilities -> mean_hdi_width
#   3. Posterior means of beta and tau. In this model both are transformed parameters on
#      the scale the choice rule uses (beta = exp(beta_location + beta_scale * beta_raw) is
#      computed per draw inside Stan), so the mean of their draws is already on that scale.
# The simulation has n_sessions = 1; the session column is kept so the same code can be
# applied to the two-session real data.

draws_sbj       <- readRDS(file.path(artifacts_dir, "draws_sbj.rds"))
simulated_data  <- readRDS(file.path(artifacts_dir, "simulated_data.rds"))
true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))

hdi_prob <- 0.95

# Shortest interval containing hdi_prob of the draws (the HDI of a unimodal posterior,
# estimated from samples)
hdi_bounds <- function(x, prob) {
  x       <- sort(x)
  n_in    <- ceiling(prob * length(x))
  widths  <- x[n_in:length(x)] - x[1:(length(x) - n_in + 1)]
  i_start <- which.min(widths)
  c(lower = x[i_start], upper = x[i_start + n_in - 1])
}

draws_matrix <- as_draws_matrix(draws_sbj)

# 1-2. One row per subject x utility: HDI bounds and width
u_columns <- grep("^u_matrix\\[", colnames(draws_matrix), value = TRUE)
u_hdi <- tibble(variable = u_columns) |>
  mutate(
    subject = as.integer(str_match(variable, "^u_matrix\\[(\\d+),")[, 2]),
    item    = as.integer(str_match(variable, ",(\\d+)\\]$")[, 2]),
    bounds  = map(variable, \(v) hdi_bounds(draws_matrix[, v], hdi_prob)),
    lower   = map_dbl(bounds, "lower"),
    upper   = map_dbl(bounds, "upper"),
    width   = upper - lower
  ) |>
  select(-bounds)

stopifnot(nrow(u_hdi) == n_subjects * n_options)

# 3. Posterior means of beta and tau per subject
posterior_means <- tibble(subject = 1:n_subjects) |>
  mutate(beta_mean = map_dbl(subject, \(s) mean(draws_matrix[, sprintf("beta[%d]", s)])),
         tau_mean  = map_dbl(subject, \(s) mean(draws_matrix[, sprintf("tau[%d]", s)])))

# One row per subject per session. Share of None choices and the true values are added
# for interpretation (available because the data are simulated).
u_hdi_width_by_subject <- u_hdi |>
  group_by(subject) |>
  summarise(mean_hdi_width = mean(width), n_utilities = n(), .groups = "drop") |>
  left_join(posterior_means, by = "subject") |>
  left_join(simulated_data |> group_by(subject) |> summarise(p_none = mean(choice == "None")), by = "subject") |>
  left_join(true_parameters |> select(subject, true_beta = beta, true_tau = tau), by = "subject") |>
  mutate(session = factor(n_sessions)) |>
  relocate(subject, session)

# Rank correlations: the relationships need not be linear
correlation_table <- tibble(
  x_variable    = c("beta_mean", "tau_mean"),
  spearman_rho  = c(cor(u_hdi_width_by_subject$beta_mean, u_hdi_width_by_subject$mean_hdi_width, method = "spearman"),
                    cor(u_hdi_width_by_subject$tau_mean,  u_hdi_width_by_subject$mean_hdi_width, method = "spearman")),
  pearson_r     = c(cor(u_hdi_width_by_subject$beta_mean, u_hdi_width_by_subject$mean_hdi_width),
                    cor(u_hdi_width_by_subject$tau_mean,  u_hdi_width_by_subject$mean_hdi_width))
)

print(u_hdi_width_by_subject, n = 10, width = Inf)
print(correlation_table)

#### PLOTS ####

plot_hdi_width <- function(x_var, x_label, x_log = FALSE) {
  rho <- correlation_table$spearman_rho[correlation_table$x_variable == x_var]
  p <- ggplot(u_hdi_width_by_subject, aes(x = .data[[x_var]], y = mean_hdi_width)) +
    geom_point(alpha = 0.8, size = 2.5, colour = "#4477AA") +
    annotate("text", x = Inf, y = Inf, label = sprintf("[Spearman rho = %.2f]", rho),
             hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = x_label, y = sprintf("Mean %d%% HDI width of the 15 utilities", round(100 * hdi_prob)))
  if (x_log) p <- p + scale_x_log10()
  p
}

# beta is lognormal, so it is shown on a log axis (the Spearman rho is unaffected)
p_hdi_vs_beta <- plot_hdi_width("beta_mean", "Posterior mean of beta (log axis)", x_log = TRUE)
p_hdi_vs_tau  <- plot_hdi_width("tau_mean", "Posterior mean of tau")

#### INTERACTION OF BETA WITH TAU ####
# The beta plot is U-shaped, and the direction of the beta effect depends on tau: with
# low tau, a low beta makes choices noisy; with high tau, a high beta turns them into
# near-certain None choices. The two scatters are shown again with the other parameter
# as colour:
#   by_tau:  x = posterior mean beta (log axis), colour = posterior mean tau
#            (blue = low, red = high, grey = 0)
#   by_beta: x = posterior mean tau, colour = posterior mean beta (log colour scale, as
#            beta is lognormal)
y_label <- sprintf("Mean %d%% HDI width of the 15 utilities", round(100 * hdi_prob))

p_hdi_vs_beta_by_tau <- ggplot(u_hdi_width_by_subject,
                               aes(x = beta_mean, y = mean_hdi_width, colour = tau_mean)) +
  geom_point(alpha = 0.85, size = 2.5) +
  scale_x_log10() +
  scale_colour_gradient2(low = "#4477AA", mid = "grey85", high = "#EE6677",
                         midpoint = 0, name = "Posterior\nmean of tau") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "Posterior mean of beta (log axis)", y = y_label)

p_hdi_vs_tau_by_beta <- ggplot(u_hdi_width_by_subject,
                               aes(x = tau_mean, y = mean_hdi_width, colour = beta_mean)) +
  geom_point(alpha = 0.85, size = 2.5) +
  scale_colour_viridis_c(trans = "log10", end = 0.9, breaks = c(1, 2, 5, 10, 20),
                         name = "Posterior\nmean of beta\n(log scale)") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "Posterior mean of tau", y = y_label)

# Regression with a beta x tau interaction (beta on the log scale, as it is lognormal)
interaction_model <- lm(mean_hdi_width ~ log(beta_mean) * tau_mean, data = u_hdi_width_by_subject)
interaction_table <- as_tibble(coef(summary(interaction_model)), rownames = "term") |>
  rename(estimate = Estimate, std_error = `Std. Error`, t_value = `t value`, p_value = `Pr(>|t|)`)

print(interaction_table)

ggsave(file.path(output_dir, "12_u_hdi_width_vs_beta.pdf"), plot = p_hdi_vs_beta, width = 8, height = 6, bg = "white")
ggsave(file.path(output_dir, "12_u_hdi_width_vs_beta.png"), plot = p_hdi_vs_beta, width = 8, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "12_u_hdi_width_vs_tau.pdf"), plot = p_hdi_vs_tau, width = 8, height = 6, bg = "white")
ggsave(file.path(output_dir, "12_u_hdi_width_vs_tau.png"), plot = p_hdi_vs_tau, width = 8, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "12_u_hdi_width_vs_beta_by_tau.pdf"), plot = p_hdi_vs_beta_by_tau, width = 9, height = 6, bg = "white")
ggsave(file.path(output_dir, "12_u_hdi_width_vs_beta_by_tau.png"), plot = p_hdi_vs_beta_by_tau, width = 9, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "12_u_hdi_width_vs_tau_by_beta.pdf"), plot = p_hdi_vs_tau_by_beta, width = 9, height = 6, bg = "white")
ggsave(file.path(output_dir, "12_u_hdi_width_vs_tau_by_beta.png"), plot = p_hdi_vs_tau_by_beta, width = 9, height = 6, dpi = 300, bg = "white")
saveRDS(interaction_table, file.path(artifacts_dir, "u_hdi_width_interaction_model.rds"))

write_csv(u_hdi_width_by_subject, file.path(artifacts_dir, "u_hdi_width_by_subject.csv"))
saveRDS(u_hdi_width_by_subject, file.path(artifacts_dir, "u_hdi_width_by_subject.rds"))
saveRDS(correlation_table, file.path(artifacts_dir, "u_hdi_width_correlations.rds"))
