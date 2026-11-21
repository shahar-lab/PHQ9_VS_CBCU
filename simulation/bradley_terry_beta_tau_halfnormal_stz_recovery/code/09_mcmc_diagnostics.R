#### MCMC DIAGNOSTICS ####
# reads: artifacts/diagnostic_summary_<session>.rds, draws_<session>.rds, true_population.rds
# writes: output/mcmc_diagnostics.pdf, artifacts/mcmc_diagnostics.rds
#
# Pages, for each session in turn (as in bradley_terry_beta_tau_lognormal_stz_recovery):
#   1. Sampler diagnostics per chain (divergences, max-treedepth hits, E-BFMI) and the
#      per-chain posterior mean of each hyperparameter: a stuck chain shows up here
#   2. Hyperparameters: R-hat, bulk and tail ESS, all chains and without flagged chains
#   3. Subject-level parameters: how many fail R-hat > 1.01 or ESS < 400, per group
#   4. Trace plots of the hyperparameters
#   5. Rank overlay plots of the hyperparameters
#   6. Pairs plot of the hyperparameters
#   7. R-hat and bulk ESS of every subject-level parameter (histograms)
#   8. Trace plots of the 6 subject-level parameters with the highest R-hat
#
# A chain is flagged when E-BFMI < 0.3 or it hit the maximum treedepth at all. The
# "without flagged chains" columns are a check of whether the other chains agree with
# each other; they are not a replacement for a refit.

library(bayesplot)
library(gridExtra)

true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))

hyperparameters <- true_population$parameter
rhat_threshold  <- 1.01   # common thresholds (Vehtari et al., 2021)
ess_threshold   <- 400
sessions        <- paste0("session", 1:n_sessions)

color_scheme_set("viridis")

summarise_convergence <- function(convergence_df) {
  convergence_df |>
    group_by(group) |>
    summarise(
      n_parameters      = n(),
      rhat_max          = max(rhat),
      n_rhat_above_1.01 = sum(rhat > rhat_threshold),
      ess_bulk_min      = min(ess_bulk),
      ess_tail_min      = min(ess_tail),
      n_ess_below_400   = sum(ess_bulk < ess_threshold | ess_tail < ess_threshold),
      .groups = "drop"
    )
}

add_group <- function(convergence_df) {
  mutate(convergence_df,
         group = if_else(str_starts(variable, "u_matrix"), "u", str_extract(variable, "^[a-z]+")))
}

# Tables are rounded for display only; the saved artifact keeps full precision
table_page <- function(df, title) {
  df <- mutate(df, across(where(is.numeric), \(x) round(x, 3)))
  grid.arrange(tableGrob(df, rows = NULL, theme = ttheme_default(base_size = 9)), top = title)
}

mcmc_diagnostics <- list()

pdf(file.path(output_dir, "mcmc_diagnostics.pdf"), width = 14, height = 8, onefile = TRUE)

for (session in sessions) {

  diagnostic_summary <- readRDS(file.path(artifacts_dir, paste0("diagnostic_summary_", session, ".rds")))
  draws              <- as_draws_array(readRDS(file.path(artifacts_dir, paste0("draws_", session, ".rds"))))
  draws_pop          <- subset_draws(draws, hyperparameters)
  draws_sbj          <- subset_draws(draws, c("beta", "tau", "u_matrix"))

  stopifnot(nchains(draws) == length(diagnostic_summary$num_divergent))

  #### 1. SAMPLER DIAGNOSTICS PER CHAIN ####

  chain_table <- tibble(
    chain           = seq_along(diagnostic_summary$num_divergent),
    n_divergent     = diagnostic_summary$num_divergent,
    n_max_treedepth = diagnostic_summary$num_max_treedepth,
    ebfmi           = diagnostic_summary$ebfmi
  ) |>
    mutate(flagged = ebfmi < 0.3 | n_max_treedepth > 0)

  chain_means <- as_tibble(as_draws_df(draws_pop)) |>
    group_by(chain = .chain) |>
    summarise(across(all_of(hyperparameters), mean), .groups = "drop")

  chain_table <- left_join(chain_table, chain_means, by = "chain")

  flagged_chains <- chain_table$chain[chain_table$flagged]
  kept_chains    <- setdiff(chain_table$chain, flagged_chains)
  drop_flagged   <- length(flagged_chains) > 0 && length(kept_chains) >= 2

  #### 2. HYPERPARAMETER CONVERGENCE ####

  hyper_table <- summarise_draws(draws_pop, rhat, ess_bulk, ess_tail)

  if (drop_flagged) {
    hyper_table <- hyper_table |>
      left_join(
        summarise_draws(subset_draws(draws_pop, chain = kept_chains), rhat, ess_bulk, ess_tail) |>
          rename(rhat_kept = rhat, ess_bulk_kept = ess_bulk, ess_tail_kept = ess_tail),
        by = "variable"
      )
  }

  #### 3. SUBJECT-LEVEL CONVERGENCE ####

  # One row per subject-level parameter (beta[s], tau[s], u_matrix[s, i])
  subject_convergence <- summarise_draws(draws_sbj, rhat, ess_bulk, ess_tail) |> add_group()

  subject_table <- summarise_convergence(subject_convergence) |> mutate(chains = "all")

  if (drop_flagged) {
    subject_table <- bind_rows(
      subject_table,
      summarise_draws(subset_draws(draws_sbj, chain = kept_chains), rhat, ess_bulk, ess_tail) |>
        add_group() |>
        summarise_convergence() |>
        mutate(chains = paste(kept_chains, collapse = ","))
    )
  }

  cat("\n====", session, "====\n")
  print(chain_table, width = Inf)
  print(hyper_table, width = Inf)
  print(subject_table, width = Inf)

  #### PLOTS ####

  trace_plot <- mcmc_trace(draws_pop) +
    ggtitle(paste0(session, " · Hyperparameters: trace plots"))
  rank_plot  <- mcmc_rank_overlay(draws_pop) +
    ggtitle(paste0(session, " · Hyperparameters: rank overlay (lines should overlap)"))

  subject_hist <- function(x_var, threshold, x_label) {
    ggplot(subject_convergence, aes(x = .data[[x_var]])) +
      geom_histogram(bins = 50, fill = "gray60", colour = "gray30") +
      geom_vline(xintercept = threshold, linetype = "dashed", colour = "#EE6677") +
      facet_wrap(~group, scales = "free_y") +
      theme_minimal(base_size = 13) +
      theme(panel.grid.minor = element_blank()) +
      labs(x = x_label, y = "Number of parameters")
  }

  p_subject_hist <- subject_hist("rhat", rhat_threshold, "R-hat (dashed: 1.01)") /
    subject_hist("ess_bulk", ess_threshold, "Bulk ESS (dashed: 400)") +
    plot_annotation(title = paste0(session, " · Subject-level parameters: R-hat and bulk ESS"))

  worst_variables <- subject_convergence |> slice_max(rhat, n = 6) |> pull(variable)
  worst_trace <- mcmc_trace(subset_draws(draws_sbj, variable = worst_variables)) +
    ggtitle(paste0(session, " · Subject-level parameters with the highest R-hat"))

  #### PAGES ####

  table_page(chain_table, sprintf(
    "%s · Sampler diagnostics per chain (flagged: E-BFMI < 0.3 or any max-treedepth hit). Flagged chains: %s",
    session, if (length(flagged_chains) == 0) "none" else paste(flagged_chains, collapse = ", ")))
  table_page(hyper_table, paste0(session, " · Hyperparameters: R-hat and ESS (*_kept = without flagged chains)"))
  table_page(subject_table, sprintf("%s · Subject-level parameters: R-hat > %.2f and ESS < %d counts",
                                    session, rhat_threshold, ess_threshold))
  print(trace_plot)
  print(rank_plot)
  # mcmc_pairs() builds its grobs when called, which opens a page on a fresh PDF
  # device; creating it here (not before the first table) avoids a blank page 1
  grid.arrange(mcmc_pairs(draws_pop), top = paste0(session, " · Hyperparameters: pairs plot"))
  print(p_subject_hist)
  print(worst_trace)

  mcmc_diagnostics[[session]] <- list(
    chain_table = chain_table, hyper_table = hyper_table, subject_table = subject_table,
    subject_convergence = subject_convergence, flagged_chains = flagged_chains
  )
}

dev.off()

saveRDS(mcmc_diagnostics, file.path(artifacts_dir, "mcmc_diagnostics.rds"))
