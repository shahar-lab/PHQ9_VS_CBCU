#### COMPILE RECOVERY PDF ####
# reads: artifacts/p_*.rds (saved by 06-09) · writes: output/recovery_summary.pdf
# Page 1: hyperparameter recovery (posterior vs population value and sampled value, per session)
# Pages 2-4: true vs estimated (sigma, tau, u), one page each, both sessions side by side
# Page 5: test-retest scatters (session 1 vs 2) of sigma, tau, u and choice prediction
#         (A/B choices only, and all choices with None)
# Pages 6-10: each test-retest scatter on its own page

p_hyperparameter_recovery <- readRDS(file.path(artifacts_dir, "p_hyperparameter_recovery.rds"))

read_plot <- \(name) readRDS(file.path(artifacts_dir, paste0("p_", name, ".rds")))

true_plot_names <- c("sigma_true_vs_estimated", "tau_true_vs_estimated", "utility_true_vs_estimated")
true_plots      <- map(true_plot_names, read_plot)

retest_plot_names <- c(
  "sigma_test_retest_scatter", "tau_test_retest_scatter", "utility_test_retest_scatter",
  "choice_prediction_test_retest_scatter", "choice_prediction_all_test_retest_scatter"
)
retest_plots <- map(retest_plot_names, read_plot)

p_retest_panel <- wrap_plots(retest_plots, ncol = 3) +
  plot_annotation(
    title = "Test-retest: posterior medians in session 1 vs session 2 (same true parameters in both)",
    tag_levels = "A"
  )

pdf(file.path(output_dir, "recovery_summary.pdf"), width = 14, height = 10, onefile = TRUE)
print(p_hyperparameter_recovery +
        ggtitle("Hyperparameter recovery: posterior per session, population value and sampled value"))
walk2(true_plots, c("sigma", "tau (None utility)", "utility (u)"),
      \(p, label) print(p + ggtitle(paste("True vs estimated:", label))))
print(p_retest_panel)
walk(retest_plots, print)
dev.off()
