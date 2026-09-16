# Slightly exceeds the 80-line guideline; kept as one file since reading the 3 source
# artifacts, building each panel via one shared helper, and assembling/exporting the
# composite are tightly cohesive steps -- splitting would fragment closely related logic
# across files without aiding clarity.
#### LOAD SOURCE ARTIFACTS (READ-ONLY, FROM OTHER FOLDERS) ####

# These 3 files are already-saved outputs of two other simulation folders.
# This script only reads and replots them -- it does not modify or re-run
# either source folder's simulation.
sweep_results_sigmas <- readRDS(here::here(
  "simulation", "sigmas_simulation_reliability_difference_sample_size",
  "artifacts", "sweep_results.rds"
))
sweep_results_phq9 <- readRDS(here::here(
  "simulation", "reliability_sample_size_subject_item_crossed",
  "artifacts", "sweep_results_phq9.rds"
))
sweep_results_cbcu <- readRDS(here::here(
  "simulation", "reliability_sample_size_subject_item_crossed",
  "artifacts", "sweep_results_cbcu.rds"
))

pal <- c("85" = "#4477AA", "90" = "#CCBB44", "95" = "#EE6677")

# Shared plotting logic replicated exactly from both source scripts'
# plot_ci_width_by_n.R (same pivot_longer/factor construction, same geoms,
# same theme). y_lab and plot_title differ per source script's own labs().
build_hdi_width_plot <- function(sweep_results, y_lab, plot_title = NULL) {

  # ASSUMED[sample_sizes not passed into this new folder]: derived the
  # scale_x_continuous() breaks from the artifact itself rather than
  # hardcoding the source folders' `sample_sizes <- c(50, 100, 200, 500, 1000)`
  # literal, since both source main.R files define the identical vector.
  sample_sizes <- sort(unique(sweep_results$sample_size))

  plot_df <- sweep_results |>
    pivot_longer(
      cols      = c(hdi_width_85, hdi_width_90, hdi_width_95),
      names_to  = "credible_level",
      values_to = "hdi_width"
    ) |>
    mutate(
      credible_level = credible_level |>
        str_remove("hdi_width_") |>
        factor(levels = c("85", "90", "95"))
    )

  p <- ggplot(plot_df, aes(x = sample_size, y = hdi_width, colour = credible_level)) +
    geom_line(aes(group = credible_level), linewidth = 0.5, alpha = 0.6) +
    geom_point(size = 2, alpha = 0.8) +
    scale_colour_manual(values = pal) +
    scale_x_continuous(breaks = sample_sizes) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid           = element_blank(),
      axis.line.x          = element_line(colour = "grey30"),
      axis.line.y          = element_line(colour = "grey30"),
      legend.position       = c(1, 0.95),
      legend.justification  = c("right", "top"),
      legend.background     = element_blank(),
      legend.key            = element_blank()
    ) +
    labs(
      title  = plot_title,
      x      = "Sample size (N)",
      y      = y_lab,
      colour = "Credible level (%)"
    )

  p
}

#### BUILD 3 PANELS ####

p_a <- build_hdi_width_plot(sweep_results_sigmas, y_lab = "HDI width (PHQ9 ICC)")

p_b <- build_hdi_width_plot(sweep_results_phq9, y_lab = "HDI width (subject ICC)")

p_c <- build_hdi_width_plot(sweep_results_cbcu, y_lab = "HDI width (subject ICC)")

#### ASSEMBLE AND EXPORT ####

p_panel <- (p_a | p_b | p_c) +
  plot_annotation(tag_levels = 'A') &
  theme(plot.tag = element_text(face = "bold", size = 14))

plot_name <- "icc_sample_size_panel"

# Deviation from EXPORT_STANDARD.md's single-plot 10x8in default: this is a
# 3-panel side-by-side composite, so a wider canvas (20x7in) is used to keep
# each panel's axes, legend, and title legible rather than compressing three
# plots into a 10in-wide figure.
ggsave(
  file.path(output_dir, paste0(plot_name, ".pdf")),
  plot = p_panel, width = 20, height = 7, bg = "white"
)

ggsave(
  file.path(output_dir, paste0(plot_name, ".png")),
  plot = p_panel, width = 20, height = 7, dpi = 300, bg = "white"
)
