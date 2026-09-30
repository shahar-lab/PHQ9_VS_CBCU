#### COMPILE ALL SHEETS INTO ONE PDF ####
# Sheet 1: true beta/tau/alpha_per/rho distributions with theoretical density overlay
# Sheet 2: mu_ hyperparameter posteriors
# Sheet 3: sigma_ hyperparameter posteriors
# Sheet 4: subject-level recovery scatters (u/beta/tau/alpha_per/rho)
# reads: artifacts/p_generative.rds, p_mu_posteriors.rds, p_sigma_posteriors.rds, p_full_recovery_panel.rds
# writes: output/16_combined_summary.pdf

p_generative          <- readRDS(file.path(artifacts_dir, "p_generative.rds"))
p_mu_posteriors       <- readRDS(file.path(artifacts_dir, "p_mu_posteriors.rds"))
p_sigma_posteriors    <- readRDS(file.path(artifacts_dir, "p_sigma_posteriors.rds"))
p_full_recovery_panel <- readRDS(file.path(artifacts_dir, "p_full_recovery_panel.rds"))

pdf(file.path(output_dir, "16_combined_summary.pdf"), width = 14, height = 8, onefile = TRUE)
print(p_generative)
print(p_mu_posteriors)
print(p_sigma_posteriors)
print(p_full_recovery_panel)
dev.off()
