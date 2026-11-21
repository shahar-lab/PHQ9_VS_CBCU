#### COMPILE RECOVERY PDF ####
# reads: artifacts/p_*.rds (saved by 06, 07, 08) · writes: output/recovery_summary.pdf
# Page 1: hyperparameter recovery (posterior vs population value and sampled value, per session)
# Page 2: test-retest scatters (session 1 vs 2) of beta, tau, u and choice prediction
#         (A/B choices only, and all choices with None)
# Pages 3-7: each test-retest scatter on its own page

p_hyperparameter_recovery <- readRDS(file.path(artifacts_dir, "p_hyperparameter_recovery.rds"))

retest_plot_names <- c(
  "beta_test_retest_scatter", "tau_test_retest_scatter", "utility_test_retest_scatter",
  "choice_prediction_test_retest_scatter", "choice_prediction_all_test_retest_scatter"
)
retest_plots <- map(retest_plot_names, \(name) readRDS(file.path(artifacts_dir, paste0("p_", name, ".rds"))))

p_retest_panel <- wrap_plots(retest_plots, ncol = 3) +
  plot_annotation(
    title = "Test-retest: posterior medians in session 1 vs session 2 (same true parameters in both)",
    tag_levels = "A"
  )

pdf(file.path(output_dir, "recovery_summary.pdf"), width = 14, height = 10, onefile = TRUE)
print(p_hyperparameter_recovery +
        ggtitle("Hyperparameter recovery: posterior per session, population value and sampled value"))
print(p_retest_panel)
walk(retest_plots, print)
dev.off()
