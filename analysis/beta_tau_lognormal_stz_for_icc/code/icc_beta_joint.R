#### ICC OF BETA FROM THE JOINT MODEL ####
# reads:  artifacts/fit_joint.rds (if fit_joint is not in memory), artifacts/unit_lookup_joint.csv
# writes: output/test-retest across sessions/icc_beta_joint.csv,
#         output/test-retest across sessions/icc_beta_joint_posterior.png
#
# icc_beta = sigma_b^2 / (sigma_b^2 + sigma_e^2) is computed per draw inside the Stan model
# (Hypothesis 2, eq. [4], on log(beta)). Reports median, 95% CrI and P(ICC > 0.80).

icc_threshold <- 0.80

if (!exists("fit_joint")) fit_joint <- readRDS(file.path(artifacts_dir, "fit_joint.rds"))

draws_icc_joint <- fit_joint$draws(variables = c("icc_beta", "sigma_b", "sigma_e", "b_0"),
                                   format = "draws_df")

icc_beta_joint_table <- tibble(
  parameter        = "log(beta)",
  model            = "joint Bradley-Terry model, both sessions",
  n_participants   = fit_joint$metadata()$stan_variable_sizes$b_0i_raw,
  icc_median       = median(draws_icc_joint$icc_beta),
  icc_lower_95     = quantile(draws_icc_joint$icc_beta, 0.025),
  icc_upper_95     = quantile(draws_icc_joint$icc_beta, 0.975),
  p_icc_above_0.80 = mean(draws_icc_joint$icc_beta > icc_threshold),
  sigma_b_median   = median(draws_icc_joint$sigma_b),
  sigma_e_median   = median(draws_icc_joint$sigma_e),
  b_0_median       = median(draws_icc_joint$b_0)
)
print(icc_beta_joint_table)
write_csv(icc_beta_joint_table, file.path(output_retest_dir, "icc_beta_joint.csv"))

p_icc_beta_joint <- ggplot(draws_icc_joint, aes(x = icc_beta)) +
  geom_histogram(bins = 60, fill = "#4477AA", colour = "white", alpha = 0.85) +
  geom_vline(xintercept = icc_threshold, linetype = "dashed", colour = "grey40") +
  geom_vline(xintercept = icc_beta_joint_table$icc_median, colour = "#EE6677", linewidth = 0.8) +
  annotate(
    "text",
    x = -Inf, y = Inf,
    label = sprintf("[ICC median = %.2f, 95%% CrI %.2f to %.2f]\n[P(ICC > %.2f) = %.2f]",
                    icc_beta_joint_table$icc_median, icc_beta_joint_table$icc_lower_95,
                    icc_beta_joint_table$icc_upper_95, icc_threshold,
                    icc_beta_joint_table$p_icc_above_0.80),
    hjust = -0.05, vjust = 1.3,
    size = 3.5, colour = "grey30"
  ) +
  coord_cartesian(xlim = c(0, 1)) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "ICC of log(beta), day 1 vs day 2 (joint model)", y = "Posterior draws")

ggsave(
  file.path(output_retest_dir, "icc_beta_joint_posterior.png"),
  plot = p_icc_beta_joint,
  width = 8, height = 5, dpi = 300, bg = "white"
)
