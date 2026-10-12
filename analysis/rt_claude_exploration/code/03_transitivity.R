#### TRANSITIVITY: CYCLIC TRIPLES ####
# reads: artifacts/df_trials.rds · writes: artifacts/wins_by_unit.rds, artifacts/df_transitivity.rds

df_trials <- readRDS(file.path(artifacts_dir, "df_trials.rds"))

n_items       <- length(phq9_item_order)
triples       <- t(combn(n_items, 3))
triple_a      <- triples[, 1]
triple_b      <- triples[, 2]
triple_c      <- triples[, 3]

units          <- unique(df_trials$unit)
wins_by_unit   <- vector("list", length(units)) |> setNames(units)
df_transitivity <- tibble()

for (unit_name in units) {
  df_unit <- df_trials |> filter(unit == unit_name)

  # wins[i, j] = 1 when item i was chosen over item j; skip trials stay 0 in both cells
  wins <- matrix(0, n_items, n_items, dimnames = list(phq9_item_order, phq9_item_order))
  df_decided <- df_unit |> filter(choice != "skip")
  for (row in seq_len(nrow(df_decided))) {
    chosen <- df_decided$chosen_item[row]
    other  <- if (df_decided$choice[row] == "left") df_decided$right_item[row] else df_decided$left_item[row]
    wins[chosen, other] <- 1
  }
  wins_by_unit[[unit_name]] <- wins

  decided <- wins + t(wins)
  all_decided <- decided[cbind(triple_a, triple_b)] == 1 &
                 decided[cbind(triple_b, triple_c)] == 1 &
                 decided[cbind(triple_a, triple_c)] == 1
  cyclic <- (wins[cbind(triple_a, triple_b)] == 1 & wins[cbind(triple_b, triple_c)] == 1 & wins[cbind(triple_c, triple_a)] == 1) |
            (wins[cbind(triple_b, triple_a)] == 1 & wins[cbind(triple_c, triple_b)] == 1 & wins[cbind(triple_a, triple_c)] == 1)

  n_decided_triples <- sum(all_decided)
  n_cyclic          <- sum(cyclic & all_decided)
  cycle_rate        <- n_cyclic / n_decided_triples

  df_transitivity <- bind_rows(df_transitivity, tibble(
    unit              = unit_name,
    agent             = df_unit$agent[1],
    n_decided         = nrow(df_decided),
    skip_rate         = mean(df_unit$choice == "skip"),
    n_decided_triples = n_decided_triples,
    n_cyclic          = n_cyclic,
    cycle_rate        = cycle_rate
  ))
}

saveRDS(wins_by_unit, file.path(artifacts_dir, "wins_by_unit.rds"))
saveRDS(df_transitivity, file.path(artifacts_dir, "df_transitivity.rds"))
