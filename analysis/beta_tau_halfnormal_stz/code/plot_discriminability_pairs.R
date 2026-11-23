#### PLOT DISCRIMINABILITY PAIRS (ONE FIGURE PER PAIR, TWO REPORTS SIDE BY SIDE) ####
# reads: artifacts/discriminability_pairs.csv; df_report, df_ladder and
#        build_report_panels() from prep_clinical_report*.R and plot_clinical_report.R
# writes: output/clinical reports/clinical_report_<high|low|sum22>_phq9_pair.pdf/.png,
#         discriminability_pairs_key.csv
#
# Each figure shows two subjects with the same time 1 PHQ-9 sum: left the most
# discriminating, right the least (select_discriminability_pairs.R). Discriminability is the
# first gauge, P(higher-utility option | not None). Both ladders share one utility axis,
# symmetric about 0, so the spread of the two ladders can be compared. The PHQ-9 sum is a
# text block (score and severity band, untagged) left of the ladder: one shared block when
# shared_bar is TRUE, otherwise one per subject. Each ladder shows the top and bottom 3
# symptoms only (n_show in plot_clinical_report.R); under it, the discriminability gauge.
# Canvas 20 x 6 in.

df_pairs <- read_csv(file.path(artifacts_dir, "discriminability_pairs.csv"), show_col_types = FALSE)

pair_pages <- list()

for (which_pair in unique(df_pairs$pair)) {
  df_pair_report <- df_report |>
    filter(pair == which_pair) |>
    arrange(match(discriminability, c("high", "low")))

  # Shared axis: the largest |utility interval end| or |threshold interval end| of the
  # two subjects, rounded up to the next 0.5. Thresholds are drawn for every subject, also
  # one who never chose None (the user's choice; labelled so), so all count here.
  ladder_limit <- df_ladder |>
    filter(prolific_id %in% df_pair_report$prolific_id) |>
    with(c(.lower, .upper)) |>
    c(df_pair_report$thr_lo, df_pair_report$thr_hi) |>
    abs() |> max() |>
    (\(m) ceiling(m * 2) / 2)()

  is_contrast   <- df_pairs$contrast[df_pairs$pair == which_pair][1]
  is_shared_bar <- df_pairs$shared_bar[df_pairs$pair == which_pair][1]
  pair_sum_label <- sprintf("PHQ-9 sum %d (%s)", as.integer(df_pair_report$phq9_sum[1]),
                            tolower(df_pair_report$band[1]))

  parts <- map(seq_len(nrow(df_pair_report)), \(k) {
    patient <- df_pair_report[k, ]
    build_report_parts(patient, ladder_limit = ladder_limit, severity_shared = is_shared_bar,
                       show_unbounded_threshold = TRUE, never_none_notes = FALSE,
                       ladder_title = if (is_contrast)
                         sprintf("%s discriminability (%.0f%%)",
                                 str_to_sentence(patient$discriminability), patient$consistency * 100)
                       else
                         sprintf("Participant %d (discriminability %.0f%%)", k, patient$consistency * 100))
  })

  column_widths <- c(1, 3, 3)
  if (is_shared_bar) {
    # Top: the one PHQ-9 text block (same sum, so it is drawn once) on the left, then the two
    # ladders, with their two identical PHQ-9 answer legends collected into one. Bottom:
    # each subject's discriminability gauge centred under their own ladder.
    top_row <- (parts[[1]]$severity | parts[[1]]$ladder | parts[[2]]$ladder) +
      plot_layout(widths = column_widths)
    # wrap_plots() keeps each centred gauge as one nested block (| would flatten them)
    bottom_row <- wrap_plots(list(plot_spacer(),
                                  center_gauge(parts[[1]]$consistency),
                                  center_gauge(parts[[2]]$consistency)),
                             widths = column_widths)
    # Legends collected at the whole figure, so the one key sits at the very bottom
    pair_body  <- (top_row / bottom_row) + plot_layout(heights = c(4, 1), guides = "collect")
  } else {
    # Two full reports side by side, each with its own PHQ-9 text block left of its ladder and
    # its discriminability gauge below; the identical PHQ-9 answer legends are collected into one
    report_block <- \(p) wrap_plots(list(wrap_plots(p$severity, p$ladder, widths = column_widths[1:2]),
                                         wrap_plots(list(plot_spacer(), center_gauge(p$consistency)),
                                                    widths = column_widths[1:2])),
                                    ncol = 1, heights = c(4, 1))
    pair_body  <- wrap_plots(report_block(parts[[1]]), report_block(parts[[2]])) +
      plot_layout(guides = "collect")
  }
  pair_title <- if (is_contrast) paste("Same PHQ-9 sum score, different discriminability:", pair_sum_label) else
    paste("Two participants with the same PHQ-9 sum score:", pair_sum_label)

  pair_pages[[which_pair]] <- pair_body +
    plot_annotation(
      title = pair_title,
      tag_levels = "A",
      theme = theme(plot.title = element_text(face = "bold", size = base_size + 3))) &
    theme(plot.tag = element_text(face = "bold", size = 14), legend.position = "bottom")

  plot_name <- paste0("clinical_report_", which_pair, "_phq9_pair")
  ggsave(file.path(output_clinical_dir, paste0(plot_name, ".pdf")), plot = pair_pages[[which_pair]],
         width = 20, height = 6, bg = "white")
  ggsave(file.path(output_clinical_dir, paste0(plot_name, ".png")), plot = pair_pages[[which_pair]],
         width = 20, height = 6, dpi = 300, bg = "white")
}

# Which participant is on which side (kept out of the figures)
write_csv(df_report |>
            filter(!is.na(pair)) |>
            select(pair, discriminability, prolific_id, phq9_sum, band,
                   consistency, cons_lo, cons_hi, n_above, n_above_lo, n_above_hi),
          file.path(output_clinical_dir, "discriminability_pairs_key.csv"))
