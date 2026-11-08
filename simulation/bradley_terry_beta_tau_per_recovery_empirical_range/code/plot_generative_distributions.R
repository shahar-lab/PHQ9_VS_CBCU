#### PLOT GENERATIVE BETA, TAU, KEY_DECAY, AND RHO DISTRIBUTIONS ####

df_beta      <- data.frame(x = true_beta)
df_tau       <- data.frame(x = true_tau)
df_key_decay <- data.frame(x = true_key_decay)
df_rho       <- data.frame(x = true_rho)

# X-axis: beta/tau/rho have no real finite bound, so widen the observed range
# 10% at each end, per the dot-histogram spec's fallback. key_decay's real
# theoretical range is (0, 1), so it uses that fixed range instead.
range_pad <- function(x) {
  r <- range(x)
  c(r[1] - 0.10 * diff(r), r[2] + 0.10 * diff(r))
}

beta_range      <- range_pad(df_beta$x)
tau_range       <- range_pad(df_tau$x)
key_decay_range <- c(0, 1)
rho_range       <- range_pad(df_rho$x)

beta_breaks      <- round(seq(beta_range[1], beta_range[2], length.out = 4), 2)
tau_breaks       <- round(seq(tau_range[1], tau_range[2], length.out = 4), 2)
key_decay_breaks <- round(seq(key_decay_range[1], key_decay_range[2], length.out = 4), 2)
rho_breaks       <- round(seq(rho_range[1], rho_range[2], length.out = 4), 2)

# Overlays the theoretical density (this folder's own true generative
# hyperparameters) on a dot histogram, rescaled to the dots layer's own
# rendered panel range -- geom_dots()'s built data carries no usable y-count,
# but layer_scales() reliably reports the panel's true [0, 1] render range,
# which is what the density curve must be rescaled into.
plot_dots_with_density <- function(df, x_range, x_breaks, density_fun, x_label) {
  p_dots <- ggplot(df, aes(x = x)) +
    geom_dots(layout = "bin", binwidth = NA, fill = "gray50", colour = "gray30")

  panel_y_range <- layer_scales(p_dots)$y$range$range
  panel_y_max   <- panel_y_range[2]

  # Evaluated strictly inside x_range (never at its exact endpoints), since a
  # bounded-support density (e.g. key_decay's logit-normal, undefined at 0/1)
  # can be +-Inf right at the boundary; a small inset keeps every density
  # value finite regardless of which density_fun is passed in.
  eps <- diff(x_range) * 1e-6
  density_df <- data.frame(x = seq(x_range[1] + eps, x_range[2] - eps, length.out = 512)) |>
    mutate(density = density_fun(x))
  density_df$y_scaled <- density_df$density * panel_y_max / max(density_df$density, na.rm = TRUE)

  p_dots +
    geom_line(data = density_df, aes(x = x, y = y_scaled), colour = "#EE6677", linewidth = 0.8) +
    scale_x_continuous(breaks = x_breaks) +
    coord_cartesian(xlim = x_range, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank()) +
    labs(x = x_label)
}

p_beta_dist <- plot_dots_with_density(
  df_beta, beta_range, beta_breaks,
  function(x) dlnorm(x, meanlog = mu_log_beta, sdlog = sigma_log_beta),
  "True beta"
)

p_tau_dist <- plot_dots_with_density(
  df_tau, tau_range, tau_breaks,
  function(x) dnorm(x, mean = mu_tau, sd = sigma_tau),
  "True tau"
)

# key_decay = plogis(logit_key_decay), logit_key_decay ~ normal(mu_logit_key_decay,
# sigma_key_decay) -- its theoretical density on the raw (0, 1) scale is the
# logit-normal density, obtained via the standard change-of-variables Jacobian
# for the logistic transform: d/dx qlogis(x) = 1 / (x * (1 - x)).
p_key_decay_dist <- plot_dots_with_density(
  df_key_decay, key_decay_range, key_decay_breaks,
  function(x) dnorm(qlogis(x), mean = mu_logit_key_decay, sd = sigma_key_decay) / (x * (1 - x)),
  "True key_decay"
)

p_rho_dist <- plot_dots_with_density(
  df_rho, rho_range, rho_breaks,
  function(x) dnorm(x, mean = mu_rho, sd = sigma_rho),
  "True rho"
)

#### ASSEMBLE ####

p_generative <- (p_beta_dist | p_tau_dist | p_key_decay_dist | p_rho_dist) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))
