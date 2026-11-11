#### COMPILE RECOVERY PDF ####
# reads: artifacts/p_*.rds · writes: output/08_combined_summary.pdf
# Page 1: true-parameter distributions · 2: mu posteriors · 3: sigma posteriors · 4: individual recovery

p_true_parameters     <- readRDS(file.path(artifacts_dir, "p_true_parameters.rds"))
p_mu_posteriors       <- readRDS(file.path(artifacts_dir, "p_mu_posteriors.rds"))
p_sigma_posteriors    <- readRDS(file.path(artifacts_dir, "p_sigma_posteriors.rds"))
p_full_recovery_panel <- readRDS(file.path(artifacts_dir, "p_full_recovery_panel.rds"))

pdf(file.path(output_dir, "08_combined_summary.pdf"), width = 14, height = 8, onefile = TRUE)
print(p_true_parameters)
print(p_mu_posteriors)
print(p_sigma_posteriors)
print(p_full_recovery_panel)
dev.off()
