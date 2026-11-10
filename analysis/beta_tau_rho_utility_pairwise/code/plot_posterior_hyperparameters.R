#### PLOT GROUP-LEVEL POSTERIORS (TIME 1 VS TIME 2) ####

hyper_labels <- c(sigma_beta  = "sigma_beta (group scale of beta)",
                  mu_tau      = "mu_tau (group mean of tau)",
                  mu_rho      = "mu_rho (group mean of rho)")

pal <- c("time1" = "#4477AA", "time2" = "#EE6677")

df_hyper <- map_dfr(waves, \(wave) {
  fit <- readRDS(file.path(artifacts_dir, paste0("bt_rho_fit_", wave, ".rds")))
  as_draws_df(fit$draws(variables = names(hyper_labels))) |>
    as_tibble() |>
    select(all_of(names(hyper_labels))) |>
    mutate(time = wave)
}) |>
  pivot_longer(all_of(names(hyper_labels)), names_to = "parameter", values_to = "theta")

plot_hyper_posterior <- function(param_name) {
  df <- filter(df_hyper, parameter == param_name)

  stats <- df |>
    group_by(time) |>
    summarise(med = median(theta), .groups = "drop") |>
    mutate(label = sprintf("%s: [median = %.2f]", time, med))

  r    <- range(df$theta)
  xlim <- c(r[1] - 0.20 * diff(r), r[2] + 0.20 * diff(r))

  ggplot(df, aes(x = theta, y = 0, fill = time, colour = time)) +
    stat_slab(alpha = 0.50) +
    stat_pointinterval(.width = 0.90, point_size = 3) +
    geom_vline(data = stats, aes(xintercept = med, colour = time),
               linetype = "dashed", linewidth = 0.4, show.legend = FALSE) +
    geom_text(data = stats, aes(x = med, y = Inf, label = label, colour = time),
              hjust = -0.05, vjust = seq(1.4, by = 1.4, length.out = nrow(stats)),
              size = 3.2, show.legend = FALSE) +
    scale_fill_manual(values = pal, guide = guide_legend(override.aes = list(alpha = 0.7))) +
    scale_colour_manual(values = pal, guide = "none") +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid             = element_blank(),
      axis.title.y           = element_blank(),
      axis.text.y            = element_blank(),
      axis.ticks.y           = element_blank(),
      axis.line.y            = element_blank(),
      axis.line.x            = element_line(colour = "grey30"),
      legend.position        = "inside",
      legend.position.inside = c(1, 0.95),
      legend.justification   = c("right", "top"),
      legend.background      = element_blank(),
      legend.key             = element_blank()
    ) +
    labs(x = hyper_labels[[param_name]], fill = NULL) +
    coord_cartesian(xlim = xlim, ylim = c(0, 1.3), clip = "off")
}

p_hyper <- wrap_plots(map(names(hyper_labels), plot_hyper_posterior), ncol = 1) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

plot_name <- "posterior_hyperparameters"

ggsave(file.path(output_posterior_dir, paste0(plot_name, ".pdf")), plot = p_hyper, width = 10, height = 12, bg = "white")
ggsave(file.path(output_posterior_dir, paste0(plot_name, ".png")), plot = p_hyper, width = 10, height = 12, dpi = 300, bg = "white")
