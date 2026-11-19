#### FIT THE JOINT (BOTH SESSIONS) MODEL ####
# needs:  stan_data_joint (prep_data_joint.R), model_path_joint, n_*_joint (main.R)
# writes: artifacts/fit_joint.rds, artifacts/diagnostic_summary_joint.rds,
#         output/diagnostic_joint.pdf

model_joint <- cmdstan_model(model_path_joint)

fit_joint <- model_joint$sample(
  data            = stan_data_joint,
  chains          = n_chains,
  parallel_chains = n_chains,
  iter_warmup     = n_warmup_joint,
  iter_sampling   = n_sampling_joint,
  seed            = 2026,
  refresh         = 100
)

fit_joint$save_object(file.path(artifacts_dir, "fit_joint.rds"))

diagnostics_joint <- fit_joint$diagnostic_summary()
saveRDS(diagnostics_joint, file.path(artifacts_dir, "diagnostic_summary_joint.rds"))
print(diagnostics_joint)

hyperparams_joint <- c("b_0", "sigma_b", "sigma_e", "icc_beta",
                       "tau_location[1]", "tau_location[2]", "tau_scale[1]", "tau_scale[2]")

draws_hyper_joint <- fit_joint$draws(variables = hyperparams_joint)
summary_table_joint <- summarise_draws(draws_hyper_joint, median = median,
                                       rhat     = posterior::rhat,
                                       ess_bulk = posterior::ess_bulk,
                                       ess_tail = posterior::ess_tail)
summary_table_joint[-1] <- round(summary_table_joint[-1], 3)
print(summary_table_joint)

# Worst R-hat / ESS over every unit-level beta and tau, not only the hyperparameters
unit_convergence <- fit_joint$summary(c("beta", "tau"), rhat = posterior::rhat, ess_bulk = posterior::ess_bulk)
cat("Unit-level beta and tau: max R-hat", round(max(unit_convergence$rhat), 3),
    "| min bulk ESS", round(min(unit_convergence$ess_bulk)), "\n")

pdf(file.path(output_dir, "diagnostic_joint.pdf"), width = 8, height = 6)
grid.arrange(tableGrob(summary_table_joint),
             top = sprintf("Divergent: %s | max treedepth hits: %s | unit-level max R-hat %.3f, min bulk ESS %d",
                           paste(diagnostics_joint$num_divergent, collapse = "/"),
                           paste(diagnostics_joint$num_max_treedepth, collapse = "/"),
                           max(unit_convergence$rhat), round(min(unit_convergence$ess_bulk))))
print(mcmc_rank_overlay(fit_joint$draws(variables = c("b_0", "sigma_b", "sigma_e", "icc_beta"))))
print(mcmc_pairs(fit_joint$draws(variables = c("b_0", "sigma_b", "sigma_e"))))
dev.off()
