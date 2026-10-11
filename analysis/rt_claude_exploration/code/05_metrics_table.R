#### TRANSITIVITY AND CONSISTENCY TABLE ####
# reads: artifacts/df_transitivity.rds, artifacts/df_consistency.rds · writes: output/05_transitivity_consistency.csv

df_transitivity <- readRDS(file.path(artifacts_dir, "df_transitivity.rds"))
df_consistency  <- readRDS(file.path(artifacts_dir, "df_consistency.rds"))

df_metrics <- df_transitivity |>
  left_join(select(df_consistency, unit, min_contradictions, contradiction_share), by = "unit") |>
  mutate(agent = factor(agent, levels = c("Claude", "Human"))) |>
  arrange(agent, unit) |>
  mutate(
    skip_rate           = round(skip_rate, 3),
    cycle_rate          = round(cycle_rate, 3),
    kendall_zeta        = round(kendall_zeta, 3),
    contradiction_share = round(contradiction_share, 3)
  )

write_csv(df_metrics, file.path(output_dir, "05_transitivity_consistency.csv"))
saveRDS(df_metrics, file.path(artifacts_dir, "df_metrics.rds"))

print(as.data.frame(df_metrics), row.names = FALSE)

# Human range next to Claude's value, for a quick read
df_human_range <- df_metrics |>
  filter(agent == "Human") |>
  summarise(across(c(skip_rate, cycle_rate, kendall_zeta, contradiction_share),
                   list(min = ~ min(.x, na.rm = TRUE), median = ~ median(.x, na.rm = TRUE),
                        max = ~ max(.x, na.rm = TRUE))))
print(as.data.frame(df_human_range))
