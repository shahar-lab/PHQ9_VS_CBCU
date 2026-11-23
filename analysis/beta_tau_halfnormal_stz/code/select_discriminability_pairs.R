#### SELECT PAIRS OF SUBJECTS WITH THE SAME PHQ-9 SUM (TIME 1) ####
# reads: artifacts/participant_parameters.csv, artifacts/p_higher_option.csv
# writes: artifacts/discriminability_pairs.csv
#
# Discriminability = P(higher-utility option | not None), the tau-free measure from
# plot_p_higher_test_retest.R (posterior median, 95% interval).
# Two pairs, one at a high and one at a low PHQ-9 sum. For each, among the sums in its range
# with at least two subjects, the sum whose subjects differ most in discriminability
# (highest minus lowest posterior median) is taken, and the pair is its most and its least
# discriminating subject (see distinct_top below). The pair's 95% intervals not overlapping
# is reported, not required.

# The user's choice of ranges: high = moderately severe or severe (picks sum 16, 96% vs 68%;
# above 16 only sum 19 has a contrast, 95% vs 87%, judged too weak); low 3-4, minimal but
# with some symptoms (sum 0 was rejected). "sum22": the only two subjects with sum 22
# (severe), added at the user's request; their discriminability is about equal (96% vs
# 94%), so contrast = FALSE (titled as two participants, not high/low).
# distinct_top: the high pick is the most discriminating subject whose top-ranked symptom
# (highest posterior-median utility) differs from the low pick's (the PI's request for the
# high pair: both of the first picks ranked Fatigue first).
# shared_bar: TRUE draws one severity bar for the pair, FALSE one per subject (the PI asked
# for two bars in the high pair).
pair_sum_ranges <- tribble(
  ~pair,   ~min_sum, ~max_sum, ~contrast, ~distinct_top, ~shared_bar,
  "high",  15,       27,       TRUE,      TRUE,          FALSE,
  "low",   3,        4,        TRUE,      FALSE,         TRUE,
  "sum22", 22,       22,       FALSE,     FALSE,         FALSE)

df_discrim_time1 <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE) |>
  filter(time == "time1", !is.na(phq9_sum)) |>
  mutate(top_item = max.col(as.matrix(pick(u_1:u_15)), ties.method = "first")) |>
  select(prolific_id, phq9_sum, top_item) |>
  inner_join(read_csv(file.path(artifacts_dir, "p_higher_option.csv"), show_col_types = FALSE) |>
               filter(time == "time1") |>
               select(prolific_id, p_higher, p_higher_lower, p_higher_upper),
             by = "prolific_id")

df_discriminability_pairs <- pmap(pair_sum_ranges, \(pair, min_sum, max_sum, contrast,
                                                     distinct_top, shared_bar) {
  chosen_sum <- df_discrim_time1 |>
    filter(between(phq9_sum, min_sum, max_sum)) |>
    group_by(phq9_sum) |>
    filter(n() >= 2) |>
    summarise(gap = max(p_higher) - min(p_higher), .groups = "drop") |>
    slice_max(gap, n = 1, with_ties = FALSE) |>
    pull(phq9_sum)

  df_at_sum <- filter(df_discrim_time1, phq9_sum == chosen_sum)
  df_low    <- slice_min(df_at_sum, p_higher, n = 1, with_ties = FALSE)
  df_high   <- df_at_sum |>
    filter(prolific_id != df_low$prolific_id, !distinct_top | top_item != df_low$top_item) |>
    slice_max(p_higher, n = 1, with_ties = FALSE)
  bind_rows(mutate(df_high, discriminability = "high"), mutate(df_low, discriminability = "low")) |>
    mutate(pair = pair, contrast = contrast, shared_bar = shared_bar,
           n_at_sum = nrow(df_at_sum), .before = 1)
}) |>
  list_rbind() |>
  group_by(pair) |>
  mutate(intervals_overlap = max(p_higher_lower) <= min(p_higher_upper)) |>
  ungroup()

print(df_discriminability_pairs)

write_csv(df_discriminability_pairs, file.path(artifacts_dir, "discriminability_pairs.csv"))
