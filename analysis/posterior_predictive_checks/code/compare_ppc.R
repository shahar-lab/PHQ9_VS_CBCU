#### COMPARE OBSERVED WITH SIMULATED STATISTICS ####
# Posterior predictive p-value (mid-p, so ties in discrete statistics do not bias it):
#   ppp = share(sim > obs) + 0.5 * share(sim == obs)
# A session is "outside" when the observed value lies outside the central 90% of the simulations
# (ppp < 0.05 or ppp > 0.95). About 10% outside is expected if the model is adequate.

summarise_stat <- function(obs, sim) {
  # obs: length n_subjects; sim: draws x subjects
  map_dfr(seq_along(obs), \(s) {
    x <- sim[, s]
    x <- x[!is.na(x)]
    if (is.na(obs[s]) || length(x) < 0.5 * nrow(sim)) {
      return(tibble(observed = obs[s], sim_median = NA_real_, sim_q05 = NA_real_, sim_q95 = NA_real_, ppp = NA_real_))
    }
    tibble(observed   = obs[s],
           sim_median = median(x),
           sim_q05    = quantile(x, 0.05, names = FALSE),
           sim_q95    = quantile(x, 0.95, names = FALSE),
           ppp        = mean(x > obs[s]) + 0.5 * mean(x == obs[s]))
  })
}

df_flags <- read_csv(flags_path, show_col_types = FALSE) |>
  select(prolific_id, time, flagged)

df_ppc <- map_dfr(names(sim_stats), \(m) {
  map_dfr(waves, \(w) {
    map_dfr(stat_names, \(st) {
      bind_cols(
        tibble(model = model_labels[[m]], time = w,
               prolific_id = obs_data[[w]]$lookup$prolific_id, statistic = st,
               n_triads_obs = as.vector(obs_stats[[w]]$n_triads),
               n_skips_obs  = round(as.vector(obs_stats[[w]]$skip_rate) * ncol(obs_data[[w]]$choice))),
        summarise_stat(as.vector(obs_stats[[w]][[st]]), sim_stats[[m]][[w]][[st]])
      )
    })
  })
}) |>
  left_join(df_flags, by = c("prolific_id", "time")) |>
  mutate(outside      = ppp < 0.05 | ppp > 0.95,
         heavy_skip   = n_skips_obs > heavy_skip_trials,
         # the transitivity check needs enough testable triads; the other statistics are always usable
         usable       = statistic != "viol_rate" | n_triads_obs >= min_triads) |>
  filter(usable, !is.na(ppp))

write_csv(df_ppc, file.path(output_dir, "ppc_session_level.csv"))

share_outside <- function(d) d |>
  summarise(n_sessions = n(), share_outside = mean(outside), .groups = "drop")

df_summary <- bind_rows(
  df_ppc |> group_by(model, statistic) |> share_outside() |> mutate(subgroup = "all sessions"),
  df_ppc |> group_by(model, statistic, subgroup = if_else(flagged, "flagged (high Pareto k)", "not flagged")) |> share_outside(),
  df_ppc |> group_by(model, statistic, subgroup = if_else(heavy_skip, "heavy skippers (>20 skips)", "light skippers")) |> share_outside()
) |>
  arrange(statistic, subgroup, model) |>
  mutate(share_outside = round(share_outside, 3))

write_csv(df_summary, file.path(output_dir, "ppc_summary_table.csv"))
print(df_summary, n = Inf)

# The two participants discussed earlier
df_examples <- df_ppc |>
  filter(prolific_id %in% c("632222532c12ab0ab7ca00bd", "5d68c8aa40524c00189e8ac2")) |>
  arrange(prolific_id, time, statistic, model)
write_csv(df_examples, file.path(output_dir, "ppc_example_participants.csv"))
