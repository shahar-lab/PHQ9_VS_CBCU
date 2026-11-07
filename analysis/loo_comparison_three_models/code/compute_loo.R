#### COMPUTE TRIAL-LEVEL PSIS-LOO AND COMPARE THE THREE MODELS ####

loo_list <- map(ll_by_model, \(m) loo(m$log_lik, r_eff = m$r_eff))

walk(names(loo_list), \(nm) { cat("\n", nm, "\n"); print(loo_list[[nm]]) })

saveRDS(loo_list, file.path(artifacts_dir, "loo_objects.rds"))

# loo_compare orders by elpd_loo; the first row is the best model (elpd_diff = 0), and each
# other row's elpd_diff / se_diff is relative to that best model
loo_comparison <- loo_compare(loo_list)
print(loo_comparison, simplify = FALSE)

df_loo_comparison <- as.data.frame(loo_comparison) |>
  rownames_to_column("model") |>
  select(model, elpd_diff, se_diff, elpd_loo, se_elpd_loo, p_loo, looic)

write_csv(df_loo_comparison, file.path(output_dir, "loo_comparison.csv"))
