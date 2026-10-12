#### WRITE REPORT PDF ####
# reads: artifacts/cleaning_summary.rds, df_rt_cap.rds, df_metrics.rds, p_rt_by_trial.rds
# writes: output/08_report.pdf

cleaning <- readRDS(file.path(artifacts_dir, "cleaning_summary.rds"))
df_cap   <- readRDS(file.path(artifacts_dir, "df_rt_cap.rds"))
df_metrics  <- readRDS(file.path(artifacts_dir, "df_metrics.rds"))
p_rt_by_trial <- readRDS(file.path(artifacts_dir, "p_rt_by_trial.rds"))
p_rt_distribution <- readRDS(file.path(artifacts_dir, "p_rt_distribution.rds"))

# The row types are the same in every run, so the table shows run 1; counts per run go in the text
df_row_types <- cleaning$row_types[[1]] |>
  transmute(trial_type, phase, rows = n, kept = if_else(kept, "KEPT", "dropped"))

run_lines <- sprintf("  Claude run %d (%s): %d raw rows, %d choice rows kept",
                     cleaning$run, cleaning$file, cleaning$n_raw, cleaning$n_kept)

df_human_range <- df_metrics |>
  filter(agent == "Human") |>
  summarise(across(c(skip_rate, cycle_rate, kendall_zeta, contradiction_share),
                   list(min    = ~ min(.x, na.rm = TRUE),
                        median = ~ median(.x, na.rm = TRUE),
                        max    = ~ max(.x, na.rm = TRUE)))) |>
  pivot_longer(everything(), names_to = c("measure", "stat"),
               names_pattern = "(.*)_(min|median|max)") |>
  pivot_wider(names_from = stat, values_from = value) |>
  mutate(across(c(min, median, max), ~ round(.x, 3)))

df_claude_row <- df_metrics |>
  filter(agent == "Claude") |>
  select(unit, skip_rate, cycle_rate, kendall_zeta, contradiction_share) |>
  pivot_longer(-unit, names_to = "measure") |>
  pivot_wider(names_from = unit, values_from = value)
df_human_range <- left_join(df_human_range, df_claude_row, by = "measure")

df_table <- df_metrics |>
  select(unit, n_decided, skip_rate, n_decided_triples, n_cyclic, cycle_rate,
         kendall_zeta, min_contradictions, contradiction_share)

text_block <- function(lines, size = 10) {
  textGrob(paste(lines, collapse = "\n"), x = 0.05, hjust = 0, just = "top",
           gp = gpar(fontsize = size))
}
small_table <- function(df, size = 8) {
  tableGrob(df, rows = NULL, theme = ttheme_minimal(base_size = size))
}
cap_text <- df_cap |>
  mutate(label = sprintf("%s: %d of %d trials above %d ms", agent, n_above_cap, n_trials, rt_axis_cap)) |>
  pull(label)

pdf(file.path(output_dir, "08_report.pdf"), width = 8.5, height = 11)

# Page 1: data and cleaning
grid.arrange(
  textGrob("Claude's sessions: RT by trial, transitivity and consistency",
           gp = gpar(fontsize = 15, fontface = "bold")),
  text_block(c(
    "Data. Claude's raw session CSVs (read directly, bypassing preprocessing) and the human",
    "pilot reference from data/processed/cbcu.csv (10 participants x 2 sessions x 105 trials).",
    "",
    run_lines,
    "Only rows with trial_type html-button-response and phase pairwise are kept; all other",
    "rows are dropped (row types of run 1 shown; run 2 has the same structure):")),
  small_table(df_row_types),
  text_block(c(
    "Checks that passed (the script stops if any fails): exactly 105 choice rows; trial order",
    "1-105 without duplicates; no repeated pair; no missing RT; window_status 'ok' on every",
    "row; choice values left/right/skip; skip matches the skipped flag; chosen item matches",
    "the chosen side. No RT outliers were removed.",
    "",
    "Human reference: 20 participant-sessions, 105 trials each (checked).",
    "RT axis cap in the figure: 15,000 ms (trials above it are hidden, not removed):",
    paste0("  ", cap_text))),
  ncol = 1, heights = c(0.06, 0.14, 0.38, 0.30, 0.12)
)

# Page 2: RT by trial
print(p_rt_by_trial)
grid.text(paste("A, B: Claude runs 1 and 2, RT (ms) against presentation order, LOESS line with band; hollow points are skipped trials.",
                "C: human sessions, one thin LOESS line per session, pooled line in rose.", sep = "\n"),
          x = 0.05, y = 0.12, hjust = 0, just = "top", gp = gpar(fontsize = 9))

# Page 3: RT distributions
print(p_rt_distribution)
grid.text(paste("A, B: Claude runs 1 and 2. C-L: each human participant (both sessions pooled). Dot histograms of RT (ms),",
                "same x-axis in every panel, cut at 15,000 ms; 'hidden' = trials above the cap (not removed).",
                sep = "\n"),
          x = 0.05, y = 0.08, hjust = 0, just = "top", gp = gpar(fontsize = 9))

# Page 4: metrics
grid.arrange(
  textGrob("Transitivity and consistency", gp = gpar(fontsize = 15, fontface = "bold")),
  text_block(c(
    "Skip trials are ignored for transitivity and consistency. A cycle is A over B, B over C and C over A.",
    "cycle_rate = cyclic triples / triples with all three pairs decided; kendall_zeta = 1 - cycle_rate / 0.308",
    "(1 = perfectly transitive). contradiction_share = fewest choices contradicting any single ranking /",
    "decided trials (0 = one ranking explains every choice). Participants with many skips have few decided",
    "triples, so their rates are unstable; H08 skipped every trial."), size = 8),
  small_table(df_table, size = 7),
  textGrob("Human range (min / median / max) next to Claude",
           gp = gpar(fontsize = 10, fontface = "bold")),
  small_table(df_human_range, size = 8),
  ncol = 1, heights = c(0.05, 0.10, 0.52, 0.04, 0.12)
)

dev.off()
