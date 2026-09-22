#### PLOT GENERATIVE BETA AND TAU DISTRIBUTIONS ####

df_beta <- data.frame(x = true_beta)
df_tau  <- data.frame(x = true_tau)

# X-axis: neither distribution has a real finite bound, so widen the observed
# range 10% at each end, per the dot-histogram spec's fallback.
range_pad <- function(x) {
  r <- range(x)
  c(r[1] - 0.10 * diff(r), r[2] + 0.10 * diff(r))
}

beta_range <- range_pad(df_beta$x)
tau_range  <- range_pad(df_tau$x)

beta_breaks <- round(seq(beta_range[1], beta_range[2], length.out = 4), 2)
tau_breaks  <- round(seq(tau_range[1], tau_range[2], length.out = 4), 2)

# Overlays the theoretical density (this folder's own true generative
# hyperparameters) on a dot histogram, rescaled to the dots layer's own
# panel-unit height so the curve's shape reads against the stacked dots.
plot_dots_with_density <- function(df, x_range, x_breaks, density_fun, x_label) {
  p_dots <- ggplot(df, aes(x = x)) +
    geom_dots(layout = "bin", binwidth = NA, fill = "gray50", colour = "gray30")

  # Read the ACTUAL rendered y-panel range (not just the dots layer's own
  # data), since ggdist's internal y-scale for geom_dots is not simply
  # "0 to max(y) of the built data" -- layer_scales() gives the true range
  # the panel will draw, which is what the density curve must be rescaled
  # into for its shape to be visible against the stacked dots.
  panel_y_range <- layer_scales(p_dots)$y$range$range
  panel_y_max   <- panel_y_range[2]

  density_df <- data.frame(x = seq(x_range[1], x_range[2], length.out = 512)) |>
    mutate(density = density_fun(x))
  density_df$y_scaled <- density_df$density * panel_y_max / max(density_df$density)

  p_dots +
    geom_line(data = density_df, aes(x = x, y = y_scaled), colour = "#EE6677", linewidth = 0.8) +
    scale_x_continuous(breaks = x_breaks) +
    coord_cartesian(xlim = x_range, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank()) +
    labs(x = x_label)
}

p_beta <- plot_dots_with_density(
  df_beta, beta_range, beta_breaks,
  function(x) dlnorm(x, meanlog = mu_log_beta, sdlog = sigma_log_beta),
  "True beta"
)

p_tau <- plot_dots_with_density(
  df_tau, tau_range, tau_breaks,
  function(x) dnorm(x, mean = mu_tau, sd = sigma_tau),
  "True tau"
)

#### ASSEMBLE AND EXPORT ####

p_generative <- (p_beta | p_tau) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

plot_name <- "generative_distributions"

ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = p_generative, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p_generative, width = 10, height = 8, dpi = 300, bg = "white")
