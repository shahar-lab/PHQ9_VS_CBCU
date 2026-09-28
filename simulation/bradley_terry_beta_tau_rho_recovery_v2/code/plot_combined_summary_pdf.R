#### COMBINE ALL 4 SHEETS INTO ONE PDF ####
# Sheet 1: generative distributions (beta/tau/rho) with theoretical density overlay
# Sheet 2: mu_ hyperparameter posteriors
# Sheet 3: sigma_ hyperparameter posteriors
# Sheet 4: subject-level recovery scatters (u/beta/tau/rho)

pdf(file.path(output_dir, "combined_summary.pdf"), width = 14, height = 8)
print(p_generative)
print(p_mu_posteriors)
print(p_sigma_posteriors)
print(p_full_recovery_panel)
dev.off()
