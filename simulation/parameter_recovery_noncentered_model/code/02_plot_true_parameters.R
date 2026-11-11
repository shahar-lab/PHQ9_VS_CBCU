#### PLOT TRUE PARAMETERS ####
# reads: artifacts/true_parameters.rds · writes: output/02_true_parameters.pdf/png, artifacts/p_true_parameters.rds

true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))

# Dot histogram with the theoretical density rescaled to the dots layer's rendered
# height, so the curve and the dots are both visible. Beta, tau, and rho have no
# finite bound in practice, so the x-axis is the observed range widened by 10%.
plot_dots_with_density <- function(values, density_fun, x_label) {
  x_range <- range(values) + c(-0.10, 0.10) * diff(range(values))
  p_dots  <- ggplot(data.frame(x = values), aes(x = x)) +
    geom_dots(layout = "bin", binwidth = NA, fill = "gray50", colour = "gray30")
  panel_y_max <- layer_scales(p_dots)$y$range$range[2]

  density_df <- data.frame(x = seq(x_range[1], x_range[2], length.out = 512)) |>
    mutate(density = density_fun(x),
           y_scaled = density * panel_y_max / max(density))

  p_dots +
    geom_line(data = density_df, aes(x = x, y = y_scaled), colour = "#EE6677", linewidth = 0.8) +
    scale_x_continuous(breaks = round(seq(x_range[1], x_range[2], length.out = 4), 2)) +
    coord_cartesian(xlim = x_range, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank()) +
    labs(x = x_label)
}

# Truncated normal density: normal density divided by the mass above 0
p_beta_dist <- plot_dots_with_density(
  true_parameters$beta,
  function(x) dnorm(x, mu_beta, sigma_beta) / pnorm(0, mu_beta, sigma_beta, lower.tail = FALSE),
  "True beta"
)
p_tau_dist <- plot_dots_with_density(true_parameters$tau, function(x) dnorm(x, mu_tau, sigma_tau), "True tau")
p_rho_dist <- plot_dots_with_density(true_parameters$rho, function(x) dnorm(x, mu_rho, sigma_rho), "True rho")

p_true_parameters <- (p_beta_dist | p_tau_dist | p_rho_dist) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "02_true_parameters.pdf"), plot = p_true_parameters, width = 14, height = 5, bg = "white")
ggsave(file.path(output_dir, "02_true_parameters.png"), plot = p_true_parameters, width = 14, height = 5, dpi = 300, bg = "white")
saveRDS(p_true_parameters, file.path(artifacts_dir, "p_true_parameters.rds"))
