#### COMPILE RECOVERY PDF ####
# reads: artifacts/p_*.rds · writes: output/09_combined_summary.pdf
# Page 1: true-parameter distributions · 2: location posteriors · 3: scale posteriors
# 4: individual recovery · 5: relationships between beta and tau

p_true_parameters         <- readRDS(file.path(artifacts_dir, "p_true_parameters.rds"))
p_location_posteriors     <- readRDS(file.path(artifacts_dir, "p_location_posteriors.rds"))
p_scale_posteriors        <- readRDS(file.path(artifacts_dir, "p_scale_posteriors.rds"))
p_full_recovery_panel     <- readRDS(file.path(artifacts_dir, "p_full_recovery_panel.rds"))
p_parameter_relationships <- readRDS(file.path(artifacts_dir, "p_parameter_relationships.rds"))

pdf(file.path(output_dir, "09_combined_summary.pdf"), width = 14, height = 8, onefile = TRUE)
print(p_true_parameters)
print(p_location_posteriors)
print(p_scale_posteriors)
print(p_full_recovery_panel)
print(p_parameter_relationships)
dev.off()
