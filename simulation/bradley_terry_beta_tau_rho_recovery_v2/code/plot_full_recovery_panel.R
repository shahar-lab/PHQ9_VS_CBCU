#### PLOT FULL RECOVERY PANEL ####

p_full_recovery_panel <- (p_u | p_beta | p_tau | p_rho) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "full_recovery_panel.pdf"), plot = p_full_recovery_panel, width = 16, height = 5, bg = "white")
ggsave(file.path(output_dir, "full_recovery_panel.png"), plot = p_full_recovery_panel, width = 16, height = 5, dpi = 300, bg = "white")
