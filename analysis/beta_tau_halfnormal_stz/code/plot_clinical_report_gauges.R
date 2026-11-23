#### CLINICAL REPORT GAUGE (DISCRIMINABILITY FOR ONE PATIENT) ####
# Sourced inside build_report_parts() of plot_clinical_report.R (uses patient, base_size,
# disc_col); leaves p_d (discriminability: P(higher-utility option | not None), column
# "consistency" in df_report). Bar = 95% interval; dot = posterior median.
# The "symptoms above the burden threshold" gauge was removed (the user's choice); the
# count is still in clinical_report_summary.csv and discriminability_pairs_key.csv.

gauge_theme <- theme_void(base_size = base_size) +
  theme(plot.title = element_text(size = base_size, hjust = 0.5, margin = margin(b = 4)))

p_d <- ggplot() +
  annotate("segment", x = 0.5, xend = 1, y = 0, yend = 0,
           colour = "grey88", linewidth = 5, lineend = "round") +
  annotate("segment", x = patient$cons_lo, xend = patient$cons_hi, y = 0, yend = 0,
           colour = disc_col, linewidth = 5, lineend = "round") +
  annotate("point", x = patient$consistency, y = 0, size = 3.5, colour = "grey15") +
  annotate("text", x = patient$consistency, y = 0.8, label = sprintf("%.0f%%", patient$consistency * 100),
           fontface = "bold", size = 4) +
  annotate("text", x = c(0.5, 1), y = -0.6, label = c("50% (random)", "100%"),
           size = 3.2, colour = "grey35", vjust = 1) +
  coord_cartesian(xlim = c(0.46, 1.04), ylim = c(-1.8, 1.4), clip = "off") +
  gauge_theme +
  labs(title = "Discriminability")
