#### PLOT TRUE PARAMETERS (DOT HISTOGRAMS, ONE FIGURE PER RUN) ####
# reads:  artifacts/<run>/true_parameters.rds, true_population.rds
# writes: output/02_true_parameters_<run>.{pdf,png}
#
# A: sigma per session, with its lognormal population density. B: tau (None utility) per
# session, with its population density from 20,000 Monte Carlo units drawn from the same
# generating process. Overlays are rescaled to the dot stacks' height so both are visible.

pal_session <- c("Session 1" = "#4477AA", "Session 2" = "#EE6677")

# Dots per session plus a density curve per session, curve scaled to the tallest stack.
# ASSUMED[dot y axis]: ggdist 3.3.3's built data has no dot positions, so the bin width is fixed
# (1/40 of the x range), the tallest stack is compressed to ggdist's default height (scale = 0.9),
# and the count labels come from binning the values at that width (approximate for Wilkinson bins).
dot_panel <- function(df_dots, df_curve, x_range, x_label) {
  bin_width <- diff(x_range) / 40
  stack_top <- 0.9
  max_count <- df_dots |> count(group, bin = floor(value / bin_width)) |> pull(n) |> max()
  df_curve  <- df_curve |> mutate(height = density / max(density) * stack_top)

  ggplot(df_dots, aes(x = value, fill = group)) +
    geom_dots(layout = "bin", binwidth = bin_width, overflow = "compress", alpha = 0.5, colour = NA) +
    geom_line(data = df_curve, aes(x = x, y = height, colour = group), linewidth = 0.8, inherit.aes = FALSE) +
    scale_fill_manual(values = pal_session, name = NULL) +
    scale_colour_manual(values = pal_session, guide = "none") +
    scale_y_continuous(name = "Count", breaks = seq(0, stack_top, length.out = 4),
                       labels = round(seq(0, max_count, length.out = 4))) +
    coord_cartesian(xlim = x_range, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), legend.position = "top") +
    labs(x = x_label)
}

for (i in seq_along(run_names)) {
  run_dir         <- file.path(artifacts_dir, run_names[i])
  true_parameters <- readRDS(file.path(run_dir, "true_parameters.rds"))
  true_population <- readRDS(file.path(run_dir, "true_population.rds"))
  pop             <- deframe(true_population)
  K               <- n_options + 1
  icc_u           <- c(rep(pop["icc_profile_C"], n_options), pop["icc_tau"])

  df_units <- true_parameters |> mutate(group = paste("Session", session))

  # A: sigma, lognormal(mu + c * delta, s) per session
  sigma_range <- c(0, max(df_units$sigma) * 1.1)
  df_sigma_curve <- expand_grid(x = seq(0.01, sigma_range[2], length.out = 400), session = 1:2) |>
    mutate(density = dlnorm(x, pop["mu_log_sigma"] + (session - 1.5) * pop["delta_log_sigma"],
                            pop["s_log_sigma"]),
           group   = paste("Session", session))
  panel_sigma <- dot_panel(df_units |> mutate(value = sigma), df_sigma_curve, sigma_range, "True sigma")

  # B: tau, Monte Carlo density from the generating process
  n_mc   <- 20000
  mc     <- tibble(session = rep(1:2, each = n_mc / 2)) |> mutate(c = session - 1.5)
  mc_sig <- exp(rnorm(n_mc, pop["mu_log_sigma"] + mc$c * pop["delta_log_sigma"], pop["s_log_sigma"]))
  mc_u   <- compose_utilities(mc_sig, mc$c, pop[sprintf("m[%d]", 1:K)], pop[sprintf("delta_u[%d]", 1:K)],
                              icc_u, matrix(rnorm(n_mc * K), n_mc, K), matrix(rnorm(n_mc * K), n_mc, K))
  tau_max   <- max(abs(c(df_units$tau, quantile(mc_u[, K], c(0.001, 0.999)))))
  tau_range <- c(-tau_max, tau_max)
  df_tau_curve <- map(1:2, \(s) {
    d <- density(mc_u[mc$session == s, K], from = tau_range[1], to = tau_range[2])
    tibble(x = d$x, density = d$y, group = paste("Session", s))
  }) |> list_rbind()
  panel_tau <- dot_panel(df_units |> mutate(value = tau), df_tau_curve, tau_range, "True tau (None utility)")

  p_true <- (panel_sigma | panel_tau) +
    plot_annotation(tag_levels = "A",
                    title = sprintf("True parameters, run %s (ICC sigma %.1f, items %.1f, tau %.1f)", i,
                                    true_icc_sigma_runs[i], true_icc_profile_runs[i], true_icc_tau_runs[i])) &
    theme(plot.tag = element_text(face = "bold", size = 14))

  plot_name <- paste0("02_true_parameters_", run_names[i])
  ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = p_true, width = 10, height = 5, bg = "white")
  ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p_true, width = 10, height = 5, dpi = 300, bg = "white")
}
