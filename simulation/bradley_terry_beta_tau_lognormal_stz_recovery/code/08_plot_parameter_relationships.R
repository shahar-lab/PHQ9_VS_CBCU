#### PLOT RELATIONSHIPS BETWEEN PARAMETERS (beta and tau) ####
# reads: artifacts/recovered_parameters.rds, draws_sbj.rds
# writes: output/08_parameter_relationships.pdf/png, artifacts/p_parameter_relationships.rds,
#         artifacts/beta_tau_posterior_correlation.rds
#
# A. True beta vs true tau: drawn independently, so any correlation is sampling noise
# B. Recovered beta vs recovered tau: a correlation absent from A was created by the fit
# C. Recovery error of beta vs error of tau: do the two errors trade off?
# D. Per-subject posterior correlation between beta and tau, across draws
# beta is lognormal, so it is shown on a log axis (A, B) and its error on the log scale (C).

recovered_parameters <- readRDS(file.path(artifacts_dir, "recovered_parameters.rds"))
draws_sbj            <- readRDS(file.path(artifacts_dir, "draws_sbj.rds"))

# One row per subject: true and recovered beta and tau
subject_df <- recovered_parameters |>
  filter(parameter %in% c("beta", "tau")) |>
  select(subject, parameter, true_value, recovered_value) |>
  pivot_wider(names_from = parameter, values_from = c(true_value, recovered_value)) |>
  mutate(error_log_beta = log(recovered_value_beta) - log(true_value_beta),
         error_tau      = recovered_value_tau - true_value_tau)

# Scatter with a linear fit and the Pearson r. x_log = TRUE puts x on a log axis
# (the r is then computed on log(x), to match what is shown).
plot_relationship <- function(x, y, x_label, y_label, x_log = FALSE) {
  pearson_r <- cor(if (x_log) log(x) else x, y)
  p <- ggplot(data.frame(x = x, y = y), aes(x = x, y = y)) +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2.5) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    annotate("text", x = Inf, y = Inf, label = sprintf("[Pearson r = %.2f]", pearson_r),
             hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = x_label, y = y_label)
  if (x_log) p <- p + scale_x_log10(labels = function(b) round(b, 1))
  p
}

p_true_relationship <- plot_relationship(
  subject_df$true_value_beta, subject_df$true_value_tau,
  "True beta (log axis)", "True tau", x_log = TRUE)

p_recovered_relationship <- plot_relationship(
  subject_df$recovered_value_beta, subject_df$recovered_value_tau,
  "Recovered beta (log axis)", "Recovered tau", x_log = TRUE)

p_error_relationship <- plot_relationship(
  subject_df$error_log_beta, subject_df$error_tau,
  "Error in log(beta) (recovered - true)", "Error in tau (recovered - true)") +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey60") +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60")

# Posterior correlation between beta[s] and tau[s] across the draws of each subject
draws_matrix <- as_draws_matrix(draws_sbj)
beta_tau_posterior_correlation <- tibble(
  subject = subject_df$subject,
  posterior_r = map_dbl(subject, \(s) cor(draws_matrix[, sprintf("beta[%d]", s)],
                                          draws_matrix[, sprintf("tau[%d]", s)]))
)

p_posterior_correlation <- ggplot(beta_tau_posterior_correlation, aes(x = posterior_r)) +
  geom_dots(layout = "bin", binwidth = NA, fill = "gray50", colour = "gray30") +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60") +
  annotate("text", x = Inf, y = Inf,
           label = sprintf("[median r = %.2f]", median(beta_tau_posterior_correlation$posterior_r)),
           hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
  coord_cartesian(xlim = c(-1, 1), clip = "off") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank()) +
  labs(x = "Posterior correlation of beta and tau (per subject)")

p_parameter_relationships <- (p_true_relationship | p_recovered_relationship) /
  (p_error_relationship | p_posterior_correlation) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

print(summary(beta_tau_posterior_correlation$posterior_r))

ggsave(file.path(output_dir, "08_parameter_relationships.pdf"), plot = p_parameter_relationships, width = 14, height = 12, bg = "white")
ggsave(file.path(output_dir, "08_parameter_relationships.png"), plot = p_parameter_relationships, width = 14, height = 12, dpi = 300, bg = "white")
saveRDS(p_parameter_relationships, file.path(artifacts_dir, "p_parameter_relationships.rds"))
saveRDS(beta_tau_posterior_correlation, file.path(artifacts_dir, "beta_tau_posterior_correlation.rds"))
