#### CONSISTENCY: CHOICES CONTRADICTING THE BEST SINGLE RANKING ####
# reads: artifacts/wins_by_unit.rds, artifacts/df_transitivity.rds · writes: artifacts/df_consistency.rds

wins_by_unit    <- readRDS(file.path(artifacts_dir, "wins_by_unit.rds"))
df_transitivity <- readRDS(file.path(artifacts_dir, "df_transitivity.rds"))

# Exact minimum number of contradicted choices over all 15! rankings, by dynamic programming
# over subsets: dp[S] is the fewest contradictions when the items in S fill the top |S| ranks.
n_items   <- length(phq9_item_order)
masks     <- 0:(2^n_items - 1)
in_subset <- sapply(seq_len(n_items), function(j) bitwAnd(masks, 2^(j - 1)) > 0)
full_mask <- 2^n_items - 1

df_consistency <- tibble()

for (unit_name in names(wins_by_unit)) {
  wins <- wins_by_unit[[unit_name]]

  # adding item j below the items in S contradicts every choice of j over an item in S
  added_cost <- in_subset %*% t(wins)

  best <- rep(Inf, length(masks))
  best[1] <- 0
  for (mask in masks[-length(masks)]) {
    free_items <- which(!in_subset[mask + 1, ])
    next_index <- mask + 2^(free_items - 1) + 1
    best[next_index] <- pmin(best[next_index], best[mask + 1] + added_cost[mask + 1, free_items])
  }

  df_consistency <- bind_rows(df_consistency, tibble(
    unit               = unit_name,
    min_contradictions = best[full_mask + 1]
  ))
}

saveRDS(df_consistency, file.path(artifacts_dir, "df_consistency.rds"))
