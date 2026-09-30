#### PLOT FULL RECOVERY PANEL ####
# reads: artifacts/p_u.rds, p_beta.rds, p_tau.rds, p_alpha_per.rds, p_rho.rds
# writes: output/12_full_recovery_panel.{pdf,png}, artifacts/p_full_recovery_panel.rds

p_u         <- readRDS(file.path(artifacts_dir, "p_u.rds"))
p_beta      <- readRDS(file.path(artifacts_dir, "p_beta.rds"))
p_tau       <- readRDS(file.path(artifacts_dir, "p_tau.rds"))
p_alpha_per <- readRDS(file.path(artifacts_dir, "p_alpha_per.rds"))
p_rho       <- readRDS(file.path(artifacts_dir, "p_rho.rds"))

p_full_recovery_panel <- (p_u | p_beta | p_tau) / (p_alpha_per | p_rho) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "12_full_recovery_panel.pdf"), plot = p_full_recovery_panel, width = 16, height = 12, bg = "white")
ggsave(file.path(output_dir, "12_full_recovery_panel.png"), plot = p_full_recovery_panel, width = 16, height = 12, dpi = 300, bg = "white")
saveRDS(p_full_recovery_panel, file.path(artifacts_dir, "p_full_recovery_panel.rds"))
