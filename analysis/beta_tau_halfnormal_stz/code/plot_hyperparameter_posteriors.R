#### PLOT HYPERPARAMETER POSTERIORS ####
# reads: artifacts/hyperparameter_draws.rds if it is newer than the fits, otherwise
#        fit_list (from fit_model.R; read from artifacts/fit_<wave>.rds if not in memory)
# writes: output/hyperparameter_posteriors.png, artifacts/hyperparameter_draws.rds
#
# Posterior density of each population-level parameter, time 1 and time 2 overlaid.
# One panel per parameter, each with its own legend. All densities have a solid outline;
# the area under the curve is filled differently:
#   location parameters: solid (semi-transparent) fill
#   scale parameters:    diagonal "/" hatching under the curve (time 2's lines sit halfway
#                        between time 1's, so where they overlap the colours alternate)
# The thick vertical line in each panel is the posterior median of that wave.

hyperparam_labels <- list(
  beta_location = quote(beta[location]),
  beta_scale    = quote(beta[scale]),
  tau_location  = quote(tau[location]),
  tau_scale     = quote(tau[scale])
)

wave_colours <- c(time1 = "#4477AA", time2 = "#EE6677")   # Paul Tol "bright": colour-blind safe
wave_labels  <- c(time1 = "Time 1", time2 = "Time 2")
median_linewidth <- 1.4

# Hatched fill of the scale parameters
hatch_spacing   <- 0.04   # distance between hatch lines, as a fraction of the panel width
hatch_linewidth <- 0.4

hyper_draws_path <- file.path(artifacts_dir, "hyperparameter_draws.rds")
fit_paths        <- file.path(artifacts_dir, paste0("fit_", waves, ".rds"))

# Use the cached draws only if they were written after the fits, so a refit is never
# plotted with stale draws
cache_is_fresh <- file.exists(hyper_draws_path) &&
  all(file.mtime(hyper_draws_path) > file.mtime(fit_paths[file.exists(fit_paths)]))

if (cache_is_fresh) {
  df_hyper_draws <- readRDS(hyper_draws_path)
} else {
  if (!exists("fit_list")) {
    fit_list <- map(set_names(waves), \(wave) readRDS(file.path(artifacts_dir, paste0("fit_", wave, ".rds"))))
  }
  # Long format: one row per wave x draw x parameter
  df_hyper_draws <- imap(fit_list, \(fit, wave) {
    fit$draws(variables = names(hyperparam_labels), format = "draws_df") |>
      as_tibble() |>
      select(all_of(names(hyperparam_labels))) |>
      mutate(time = wave)
  }) |>
    list_rbind() |>
    pivot_longer(-time, names_to = "parameter", values_to = "value")
  saveRDS(df_hyper_draws, hyper_draws_path)
}

# X axis = the range the parameter can take (PI's request), not just where the posterior
# sits: a parameter bounded below starts at its bound (lower=0 in the .stan file) and runs
# 20% of the draws' range past the largest draw; an unbounded one (tau_location) is
# symmetric about 0, the average utility.
param_lower_bound <- c(beta_location = 0, beta_scale = 0, tau_location = NA, tau_scale = 0)

hyperparameter_axis_limits <- function(values, lower_bound) {
  if (is.na(lower_bound)) {
    max_abs <- max(abs(values))
    c(-max_abs, max_abs)
  } else {
    c(lower_bound, max(values) + 0.20 * diff(range(values)))
  }
}

df_hyper_medians <- df_hyper_draws |>
  group_by(parameter, time) |>
  summarise(median = median(value), .groups = "drop")
print(df_hyper_medians)

# Diagonal hatch lines under each wave's density curve. The density is computed as
# geom_density does (same bandwidth, 512 points over the range of the draws), so the
# hatching fills exactly the area inside the outline. The lines are laid out on the panel
# scaled to 0-1 in both directions, so they run at about 45 degrees on screen. Each line
# is sampled finely along x and kept only where it lies under the curve; a line that
# leaves and re-enters the area becomes separate pieces ("run").
make_density_hatch <- function(draws, x_limits) {
  curves <- split(draws$value, draws$time) |>
    map(\(v) density(v, n = 512, from = min(v), to = max(v))[c("x", "y")])

  x_min <- x_limits[1]   # laid out on the panel's x range, so 45 degrees holds on screen
  x_max <- x_limits[2]
  y_max <- max(unlist(map(curves, "y")))

  x_unit     <- seq(0, 1, length.out = 1000)
  x_data     <- x_min + x_unit * (x_max - x_min)
  intercepts <- seq(-1, 2, by = hatch_spacing)

  imap(curves, \(curve, wave) {
    shift       <- if (wave == "time2") hatch_spacing / 2 else 0   # interleave the waves
    height_unit <- approx(curve$x, curve$y, xout = x_data)$y / y_max   # NA outside the curve

    imap(intercepts + shift, \(intercept, line) {
      y_unit <- intercept + x_unit
      inside <- !is.na(height_unit) & y_unit >= 0 & y_unit <= height_unit
      tibble(x = x_data, y = y_unit * y_max, line = line,
             run = cumsum(c(TRUE, diff(inside) != 0)))[inside, ]
    }) |>
      list_rbind() |>
      mutate(time = wave)
  }) |>
    list_rbind() |>
    mutate(group = paste(time, line, run))
}

# Legend key for the scale panels: outline with hatching inside (lines are drawn in mm so
# they are at 45 degrees whatever the key's shape, and clipped to the key box)
draw_key_hatched_fill <- function(data, params, size) {
  colour <- data$colour %||% "grey20"
  starts <- seq(-30, 30, by = 2)                      # mm
  grid::grobTree(
    grid::segmentsGrob(unit(starts, "mm"), unit(0, "mm"), unit(starts + 30, "mm"), unit(30, "mm"),
                       gp = grid::gpar(col = colour, lwd = 0.8)),
    grid::rectGrob(gp = grid::gpar(col = colour, fill = NA, lwd = 1.5)),
    vp = grid::viewport(clip = "on")
  )
}

plot_hyperparameter <- function(param) {
  draws    <- filter(df_hyper_draws, parameter == param)
  medians  <- filter(df_hyper_medians, parameter == param)
  is_scale <- str_ends(param, "_scale")
  x_limits <- hyperparameter_axis_limits(draws$value, param_lower_bound[[param]])

  fill_layers <- if (is_scale) {
    list(
      geom_path(data = make_density_hatch(draws, x_limits), aes(x = x, y = y, colour = time, group = group),
                linewidth = hatch_linewidth, show.legend = FALSE),
      geom_density(aes(colour = time), linewidth = 0.8, key_glyph = draw_key_hatched_fill)
    )
  } else {
    list(
      geom_density(aes(colour = time, fill = time), alpha = 0.35, linewidth = 0.8),
      scale_fill_manual(values = wave_colours, labels = wave_labels, name = NULL)
    )
  }

  ggplot(draws, aes(x = value)) +
    fill_layers +
    geom_vline(data = medians,
               aes(xintercept = median, colour = time, linetype = "Posterior median"),
               linewidth = median_linewidth, key_glyph = "path",
               show.legend = c(colour = FALSE, linetype = TRUE)) +
    scale_colour_manual(values = wave_colours, labels = wave_labels, name = NULL) +
    scale_linetype_manual(values = c("Posterior median" = "solid"), name = NULL) +
    guides(colour = guide_legend(order = 1), fill = guide_legend(order = 1),
           linetype = guide_legend(order = 2, override.aes = list(colour = "grey20"))) +
    coord_cartesian(xlim = x_limits) +
    theme_minimal(base_size = 13) +
    theme(aspect.ratio     = 0.5,               # panel height = half its width
          panel.grid.minor = element_blank(),
          axis.text.y      = element_blank(),   # density height has no meaning of its own
          axis.title.y     = element_text(size = 16, angle = 0, vjust = 0.5),
          legend.key.width = unit(1.6, "cm")) +
    labs(x = "Posterior value", y = hyperparam_labels[[param]])
}

p_hyperparameters <- map(names(hyperparam_labels), plot_hyperparameter) |>
  wrap_plots(ncol = 2) +
  plot_annotation(tag_levels = "A")

ggsave(file.path(output_dir, "hyperparameter_posteriors.png"), plot = p_hyperparameters,
       width = 14, height = 5.9, dpi = 300, bg = "white")
