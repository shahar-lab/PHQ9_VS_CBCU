#### WRITE KEY VS NEITHER REPEATING REPORT ####
# reads: output/repeat types vs rho/*.csv · writes: output/repeat types vs rho/repeat_types_vs_rho.md

df_quartiles       <- read_csv(file.path(output_repeat_dir, "repeat_quartiles.csv"), show_col_types = FALSE)
df_regression      <- read_csv(file.path(output_repeat_dir, "repeat_regression.csv"), show_col_types = FALSE)
df_top_test        <- read_csv(file.path(output_repeat_dir, "repeat_top_quartile_test.csv"), show_col_types = FALSE)
df_average_rho     <- read_csv(file.path(output_repeat_dir, "average_rho_check.csv"), show_col_types = FALSE)
df_neither_counts  <- read_csv(file.path(output_repeat_dir, "neither_trial_counts.csv"), show_col_types = FALSE)

sample_labels <- c(all = "All participants", enough_neither = paste0("Only participants with >= ", min_neither_trials, " neither choices"))
quartile_cols <- c("Quartile", "Key n", "Key raw", "Key chance", "Key mean rho",
                   "Neither n", "Neither raw", "Neither chance", "Neither mean rho")

report <- c(
  "# Rho by key repeating vs neither repeating",
  "",
  "Raw = share of consecutive within-block trial pairs that repeat (key: A->A or B->B; neither: skip->skip).",
  "Chance = expected from the participant's own frequencies (key: pA^2 + pB^2; neither: pNeither^2).",
  "Quartiles are by excess = raw - chance, computed separately for key and neither, within session.",
  "",
  paste0("## Participants with fewer than ", min_neither_trials, " neither choices"),
  "",
  kable(df_neither_counts, col.names = c("Session", "Participants", "Too few neither choices")),
  ""
)

for (s in names(sample_labels)) {
  report <- c(report, paste0("## ", sample_labels[[s]]), "")

  for (wave in c("time1", "time2")) {
    df_table <- df_quartiles |> filter(sample == s, time == wave) |> select(-sample, -time)
    report <- c(report, paste0("### ", wave, ": quartiles of excess repeating"), "",
                kable(df_table, digits = 3, col.names = quartile_cols), "")
  }

  report <- c(report,
    "### Correlation and joint standardized regression: rho ~ key excess + neither excess", "",
    kable(df_regression |> filter(sample == s) |> select(-sample), digits = 3), "",
    "### Top key quartile vs top neither quartile (participants in both top groups left out)", "",
    kable(df_top_test |> filter(sample == s) |> select(-sample), digits = 3), "",
    "### Average rho check: intercept = rho expected at chance-level repeating", "",
    kable(df_average_rho |> filter(sample == s) |> select(-sample), digits = 3), ""
  )
}

writeLines(report, file.path(output_repeat_dir, "repeat_types_vs_rho.md"))
