#### WRITE MULTI-PAGE PDF ####

grDevices::pdf(file.path(output_dir, "raw_data_qa_report.pdf"), width = 10, height = 8, bg = "white")

print(p_rt_by_trial)
print(p_rt_hist)
render_table_page(rt_outlier_table, paste0(
  "RT outlier frequency  —  cutoffs used: fast < ", rt_fast_cutoff_ms,
  " ms, slow > ", rt_slow_cutoff_ms, " ms"
))
render_table_page(skipped_table, "Skipped trials — 'Neither bothered me' responses (a legitimate answer choice, NOT missing data)")
render_table_page(missing_table, "True missing data (rt or chosen_side NA) — distinct from skipped trials above")
render_table_page(trial_count_table, paste0("Trial-count sanity check (expected = ", expected_pairwise_trials, " pairwise trials)"))
render_table_page(window_departure_table, "Window departures — n_departures = contiguous non-'ok' runs (see ASSUMED note in code)")

grDevices::dev.off()
