#### PLOT HYPERPARAMETER POSTERIORS ####
# reads: artifacts/hyperparameter_draws.rds if it is newer than the fit, otherwise
#        fit (from fit_model.R; read from artifacts/fit.rds if not in memory)
# writes: output/hyperparameter_posteriors.png, artifacts/hyperparameter_draws.rds
#
# Posterior density of each population-level parameter of the joint fit.
# One panel per parameter, each with its own legend. All densities have a solid outline;
# the area under the curve is filled differently:
#   location parameters: solid (semi-transparent) fill
#   scale parameters:    diagonal "/" hatching under the curve
# The thick vertical line in each panel is the posterior median.

hyperparam_labels <- list(
  beta_location = quote(beta[location]),
  beta_scale    = quote(beta[scale]),
  tau_location  = quote(tau[location]),
  tau_scale     = quote(tau[scale])
)

density_colour   <- "#4477AA"   # Paul Tol "bright" blue, as in the per-session folder
median_linewidth <- 1.4

# Hatched fill of the scale parameters
hatch_spacing   <- 0.04   # distance between hatch lines, as a fraction of the panel width
hatch_linewidth <- 0.4

hyper_draws_path <- file.path(artifacts_dir, "hyperparameter_draws.rds")
fit_path         <- file.path(artifacts_dir, "fit.rds")

# Use the cached draws only if they were written after the fit, so a refit is never
# plotted with stale draws
cache_is_fresh <- file.exists(hyper_draws_path) &&
  (!file.exists(fit_path) || file.mtime(hyper_draws_path) > file.mtime(fit_path))

if (cache_is_fresh) {
  df_hyper_draws <- readRDS(hyper_draws_path)
} else {
  if (!exists("fit")) fit <- readRDS(fit_path)
  # Long format: one row per draw x parameter
  df_hyper_draws <- fit$draws(variables = names(hyperparam_labels), format = "draws_df") |>
    as_tibble() |>
    select(all_of(names(hyperparam_labels))) |>
    pivot_longer(everything(), names_to = "parameter", values_to = "value")
  saveRDS(df_hyper_draws, hyper_draws_path)
}

df_hyper_medians <- df_hyper_draws |>
  group_by(parameter) |>
  summarise(median = median(value), .groups = "drop")
print(df_hyper_medians)

# Diagonal hatch lines under the density curve. The density is computed as geom_density
# does (same bandwidth, 512 points over the range of the draws), so the hatching fills
# exactly the area inside the outline. The lines are laid out on the panel scaled to 0-1
# in both directions, so they run at about 45 degrees on screen. Each line is sampled
# finely along x and kept only where it lies under the curve; a line that leaves and
# re-enters the area becomes separate pieces ("run").
make_density_hatch <- function(values) {
  curve  <- density(values, n = 512, from = min(values), to = max(values))
  x_unit <- seq(0, 1, length.out = 1000)
  x_data <- min(curve$x) + x_unit * diff(range(curve$x))
  height_unit <- approx(curve$x, curve$y, xout = x_data)$y / max(curve$y)

  imap(seq(-1, 1, by = hatch_spacing), \(intercept, line) {
    y_unit <- intercept + x_unit
    inside <- y_unit >= 0 & y_unit <= height_unit
    tibble(x = x_data, y = y_unit * max(curve$y), line = line,
           run = cumsum(c(TRUE, diff(inside) != 0)))[inside, ]
  }) |>
    list_rbind() |>
    mutate(group = paste(line, run))
}

# Legend key for the scale panels: outline with hatching inside (lines are drawn in mm so
# they are at 45 degrees whatever the key's shape, and clipped to the key box)
draw_key_hatched_fill <- function(data, params, size) {
  starts <- seq(-30, 30, by = 2)                      # mm
  grid::grobTree(
    grid::segmentsGrob(unit(starts, "mm"), unit(0, "mm"), unit(starts + 30, "mm"), unit(30, "mm"),
                       gp = grid::gpar(col = density_colour, lwd = 0.8)),
    grid::rectGrob(gp = grid::gpar(col = density_colour, fill = NA, lwd = 1.5)),
    vp = grid::viewport(clip = "on")
  )
}

plot_hyperparameter <- function(param) {
  draws    <- filter(df_hyper_draws, parameter == param)
  medians  <- filter(df_hyper_medians, parameter == param)
  is_scale <- str_ends(param, "_scale")

  # The density is one legend entry (colour/fill), the median another (linetype)
  fill_layers <- if (is_scale) {
    list(
      geom_path(data = make_density_hatch(draws$value), aes(x = x, y = y, group = group),
                colour = density_colour, linewidth = hatch_linewidth),
      geom_density(aes(colour = "Posterior density"), linewidth = 0.8,
                   key_glyph = draw_key_hatched_fill)
    )
  } else {
    list(
      geom_density(aes(colour = "Posterior density", fill = "Posterior density"),
                   alpha = 0.35, linewidth = 0.8),
      scale_fill_manual(values = c("Posterior density" = density_colour), name = NULL)
    )
  }

  ggplot(draws, aes(x = value)) +
    fill_layers +
    geom_vline(data = medians, aes(xintercept = median, linetype = "Posterior median"),
               colour = density_colour, linewidth = median_linewidth, key_glyph = "path") +
    scale_colour_manual(values = c("Posterior density" = density_colour), name = NULL) +
    scale_linetype_manual(values = c("Posterior median" = "solid"), name = NULL) +
    guides(colour = guide_legend(order = 1), fill = guide_legend(order = 1),
           linetype = guide_legend(order = 2)) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(),
          axis.text.y      = element_blank(),   # density height has no meaning of its own
          axis.title.y     = element_text(size = 16, angle = 0, vjust = 0.5),
          legend.key.width = unit(1.6, "cm")) +
    labs(x = "Posterior value", y = hyperparam_labels[[param]])
}

p_hyperparameters <- map(names(hyperparam_labels), plot_hyperparameter) |>
  wrap_plots(ncol = 2) +
  plot_annotation(tag_levels = "A")

ggsave(file.path(output_dir, "hyperparameter_posteriors.png"), plot = p_hyperparameters,
       width = 14, height = 9, dpi = 300, bg = "white")
