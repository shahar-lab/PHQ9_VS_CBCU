#### PLOT TRUE PARAMETER DISTRIBUTIONS ####
# reads: artifacts/true_parameters.rds · writes: output/02_true_parameters.{pdf,png}, artifacts/p_generative.rds

true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))

# Dot histogram with the theoretical density overlaid. The density is rescaled to the
# dots layer's own panel range (layer_scales), otherwise it is too small or large to see.
# The density is evaluated strictly inside x_range: alpha_per's logit-normal density is
# infinite at 0 and 1.
plot_dots_with_density <- function(values, x_range, density_fun, x_label) {
  p_dots <- ggplot(data.frame(x = values), aes(x = x)) +
    geom_dots(layout = "bin", binwidth = NA, fill = "gray50", colour = "gray30")

  panel_y_max <- layer_scales(p_dots)$y$range$range[2]

  eps        <- diff(x_range) * 1e-6
  density_df <- data.frame(x = seq(x_range[1] + eps, x_range[2] - eps, length.out = 512)) |>
    mutate(density = density_fun(x),
           y_scaled = density * panel_y_max / max(density, na.rm = TRUE))

  p_dots +
    geom_line(data = density_df, aes(x = x, y = y_scaled), colour = "#EE6677", linewidth = 0.8) +
    scale_x_continuous(breaks = pretty(x_range, n = 6)) +
    coord_cartesian(xlim = x_range, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank()) +
    labs(x = x_label)
}

# No finite bound: observed range widened 10% at each end. alpha_per lives in (0, 1).
range_pad <- function(x) range(x) + c(-1, 1) * 0.10 * diff(range(x))

p_beta_dist <- plot_dots_with_density(
  true_parameters$beta, range_pad(true_parameters$beta),
  function(x) dlnorm(x, meanlog = mu_log_beta, sdlog = sigma_log_beta), "True beta")

p_tau_dist <- plot_dots_with_density(
  true_parameters$tau, range_pad(true_parameters$tau),
  function(x) dnorm(x, mean = mu_tau, sd = sigma_tau), "True tau")

# alpha_per = plogis(logit_alpha_per): logit-normal density via the Jacobian 1 / (x * (1 - x))
p_alpha_per_dist <- plot_dots_with_density(
  true_parameters$alpha_per, c(0, 1),
  function(x) dnorm(qlogis(x), mean = mu_logit_alpha, sd = sigma_alpha) / (x * (1 - x)), "True alpha_per")

p_rho_dist <- plot_dots_with_density(
  true_parameters$rho, range_pad(true_parameters$rho),
  function(x) dnorm(x, mean = mu_rho, sd = sigma_rho), "True rho")

p_generative <- (p_beta_dist | p_tau_dist) / (p_alpha_per_dist | p_rho_dist) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "02_true_parameters.pdf"), plot = p_generative, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "02_true_parameters.png"), plot = p_generative, width = 10, height = 8, dpi = 300, bg = "white")
saveRDS(p_generative, file.path(artifacts_dir, "p_generative.rds"))
