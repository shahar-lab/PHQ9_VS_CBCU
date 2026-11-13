#### PLOT TRUE PARAMETERS ####
# reads: artifacts/true_parameters.rds, true_u.rds
# writes: output/02_true_parameters.pdf/png, artifacts/p_true_parameters.rds

true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))
true_u          <- readRDS(file.path(artifacts_dir, "true_u.rds"))

# Dot histogram with the theoretical density rescaled to the dots layer's rendered
# height, so the curve and the dots are both visible. The x-axis is the observed
# range widened by 10%, cut at lower_bound (beta cannot go below 0).
plot_dots_with_density <- function(values, density_fun, x_label, lower_bound = -Inf) {
  x_range    <- range(values) + c(-0.10, 0.10) * diff(range(values))
  x_range[1] <- max(x_range[1], lower_bound)
  p_dots     <- ggplot(data.frame(x = values), aes(x = x)) +
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

p_beta_dist <- plot_dots_with_density(
  true_parameters$beta,
  function(x) dlnorm(x, meanlog = true_beta_location, sdlog = true_beta_scale),
  "True beta", lower_bound = 0
)
p_tau_dist <- plot_dots_with_density(
  true_parameters$tau,
  function(x) dnorm(x, mean = true_tau_location, sd = true_tau_scale),
  "True tau"
)
# Utilities have marginal SD 1 (see 01_generate_true_parameters.R)
p_u_dist <- plot_dots_with_density(
  as.vector(true_u),
  function(x) dnorm(x, mean = 0, sd = 1),
  "True utility (u)"
)

p_true_parameters <- (p_beta_dist | p_tau_dist | p_u_dist) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "02_true_parameters.pdf"), plot = p_true_parameters, width = 14, height = 5, bg = "white")
ggsave(file.path(output_dir, "02_true_parameters.png"), plot = p_true_parameters, width = 14, height = 5, dpi = 300, bg = "white")
saveRDS(p_true_parameters, file.path(artifacts_dir, "p_true_parameters.rds"))
