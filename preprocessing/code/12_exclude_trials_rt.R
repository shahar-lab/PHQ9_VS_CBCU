# reads: artifacts/11_after_window_exits.rds, data/raw/cbcu_results.csv
# writes: artifacts/12_after_rt_bounds.rds, output/processed/exclusion.md

#### EXCLUDE TRIALS: NA, FAST RT, OR SLOW RT ####

if (!exists("rt_min_ms")) rt_min_ms <- 500
if (!exists("rt_max_ms")) rt_max_ms <- 15000

step11 <- readRDS(file.path(artifacts_dir, "11_after_window_exits.rds"))
cbcu_results <- read_csv(file.path(raw_dir, "cbcu_results.csv"), show_col_types = FALSE)

after_window_exits_pids <- step11$after_window_exits_pids
exclusion_report_lines  <- step11$exclusion_report_lines

after_window_cbcu <- cbcu_results |>
  mutate(
    prolific_id = as.character(prolific_id),
    time        = as.character(time)
  ) |>
  filter(prolific_id %in% after_window_exits_pids)

# ASSUMED[NA means a missing RT or choice]: a trial with no recorded response
# is not usable, so it is omitted with the RT bounds.
after_rt_bounds <- after_window_cbcu |>
  filter(
    !is.na(rt),
    !is.na(choice),
    rt >= rt_min_ms,
    rt <= rt_max_ms
  )

n_started  <- nrow(after_window_cbcu)
n_excluded <- n_started - nrow(after_rt_bounds)
n_left     <- nrow(after_rt_bounds)

rt_criterion_text <- paste0(
  "Trials with NA, RT quicker than ",
  rt_min_ms / 1000,
  " seconds, or RT slower than ",
  rt_max_ms / 1000,
  " seconds"
)

exclusion_report_lines <- c(
  exclusion_report_lines,
  paste0(
    "3. ", rt_criterion_text, ". Started with ", n_started,
    " trials, excluded ", n_excluded, ", ", n_left, " left."
  )
)

writeLines(exclusion_report_lines, file.path(output_processed_dir, "exclusion.md"))

saveRDS(
  list(
    after_window_exits_pids = after_window_exits_pids,
    after_window_cbcu       = after_window_cbcu,
    after_rt_bounds         = after_rt_bounds,
    rt_criterion_text       = rt_criterion_text,
    exclusion_report_lines  = exclusion_report_lines
  ),
  file.path(artifacts_dir, "12_after_rt_bounds.rds")
)
