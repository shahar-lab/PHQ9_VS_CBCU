#### PLOT PARETO-K DIAGNOSTICS (ONE PAGE PER MODEL) ####

pdf(file.path(output_dir, "pareto_k_diagnostics.pdf"), width = 10, height = 6)
iwalk(loo_list, \(loo_obj, model_name) {
  plot(loo_obj, label_points = FALSE, main = paste("PSIS-LOO Pareto k:", model_name))
})
dev.off()
