#### SUMMARISE RT (MEAN, MEDIAN, MIN, MAX) ####

rt_summary <- df |>
  summarise(
    n      = n(),
    mean   = round(mean(rt, na.rm = TRUE), 1),
    median = round(median(rt, na.rm = TRUE), 1),
    min    = round(min(rt, na.rm = TRUE), 1),
    max    = round(max(rt, na.rm = TRUE), 1)
  )

write_csv(rt_summary, file.path(artifacts_dir, "rt_summary.csv"))

rt_summary_table <- c(
  "# RT Summary (pilot session, pairwise trials)",
  "",
  knitr::kable(rt_summary, format = "pipe")
)
writeLines(rt_summary_table, file.path(output_dir, "rt_summary.md"))

print(rt_summary)
