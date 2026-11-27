#### REPORT CONVERGENCE (BEFORE ANY RECOVERY FIGURE) ####
# reads:  artifacts/<run>/diagnostics.rds
# writes: artifacts/convergence_table.rds, output/06_convergence.csv
#
# Reported as it came out; no threshold is applied here.

convergence_table <- map(seq_along(run_names), \(i) {
  diagnostics <- readRDS(file.path(artifacts_dir, run_names[i], "diagnostics.rds"))
  tibble(
    run                  = run_names[i],
    divergences          = sum(diagnostics$sampler$num_divergent),
    max_treedepth_hits   = sum(diagnostics$sampler$num_max_treedepth),
    min_ebfmi            = min(diagnostics$sampler$ebfmi),
    max_rhat_population  = max(diagnostics$summary_pop$rhat, na.rm = TRUE),
    min_ess_bulk_population = min(diagnostics$summary_pop$ess_bulk, na.rm = TRUE),
    min_ess_tail_population = min(diagnostics$summary_pop$ess_tail, na.rm = TRUE),
    max_rhat_unit        = diagnostics$max_rhat_sbj,
    min_ess_bulk_unit    = diagnostics$min_ess_bulk_sbj,
    hours                = diagnostics$time_seconds / 3600
  )
}) |>
  list_rbind()

print(convergence_table, width = Inf)

saveRDS(convergence_table, file.path(artifacts_dir, "convergence_table.rds"))
write_csv(convergence_table, file.path(output_dir, "06_convergence.csv"))
