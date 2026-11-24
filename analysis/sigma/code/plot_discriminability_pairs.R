#### PLOT DISCRIMINABILITY PAIRS (ONE FIGURE PER PAIR, TWO REPORTS SIDE BY SIDE) ####
# reads: df_report, df_ladder and build_report_parts() / center_gauge() from
#        prep_clinical_report*.R and plot_clinical_report.R
# writes: output/clinical reports/clinical_report_<high|low|sum22>_phq9_pair.pdf/.png,
#         discriminability_pairs_key.csv
# Adapted from analysis/beta_tau_halfnormal_stz/code/plot_discriminability_pairs.R
#
# Same pairs as the beta report (the user's choice): two subjects with the same time 1 PHQ-9
# sum, chosen there as the highest and lowest beta-model discriminability. Here each
# ladder shows P(bothers most) for all 15 symptoms and None, and the gauge shows sigma, so
# the figure shows whether the sigma model separates the pair the same way. Both ladders
# already share one axis ([0, 1]). Canvas 20 x 8 in.

df_pairs <- distinct(filter(df_report, !is.na(pair)), pair, contrast, shared_bar)

pair_pages <- list()

for (which_pair in df_pairs$pair) {
  df_pair_report <- df_report |>
    filter(pair == which_pair) |>
    arrange(match(discriminability, c("high", "low")))

  is_contrast   <- df_pairs$contrast[df_pairs$pair == which_pair]
  is_shared_bar <- df_pairs$shared_bar[df_pairs$pair == which_pair]
  pair_sum_label <- sprintf("PHQ-9 sum %d (%s)", as.integer(df_pair_report$phq9_sum[1]),
                            tolower(df_pair_report$band[1]))

  parts <- map(seq_len(nrow(df_pair_report)), \(k) {
    patient <- df_pair_report[k, ]
    build_report_parts(patient, severity_shared = is_shared_bar,
                       ladder_title = if (is_contrast)
                         sprintf("%s discriminability in the beta model (sigma = %.1f)",
                                 str_to_sentence(patient$discriminability), patient$sigma)
                       else
                         sprintf("Participant %d (sigma = %.1f)", k, patient$sigma))
  })

  column_widths <- c(1, 3, 3)
  if (is_shared_bar) {
    # One PHQ-9 text block (same sum) on the left, then the two ladders; each subject's
    # sigma gauge centred under their own ladder
    top_row <- (parts[[1]]$severity | parts[[1]]$ladder | parts[[2]]$ladder) +
      plot_layout(widths = column_widths)
    bottom_row <- wrap_plots(list(plot_spacer(),
                                  center_gauge(parts[[1]]$consistency),
                                  center_gauge(parts[[2]]$consistency)),
                             widths = column_widths)
    pair_body <- (top_row / bottom_row) + plot_layout(heights = c(6, 1), guides = "collect")
  } else {
    # Two full reports side by side, each with its own PHQ-9 text block and gauge
    report_block <- \(p) wrap_plots(list(wrap_plots(p$severity, p$ladder, widths = column_widths[1:2]),
                                         wrap_plots(list(plot_spacer(), center_gauge(p$consistency)),
                                                    widths = column_widths[1:2])),
                                    ncol = 1, heights = c(6, 1))
    pair_body <- wrap_plots(report_block(parts[[1]]), report_block(parts[[2]])) +
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
         width = 20, height = page_height, bg = "white")
  ggsave(file.path(output_clinical_dir, paste0(plot_name, ".png")), plot = pair_pages[[which_pair]],
         width = 20, height = page_height, dpi = 300, bg = "white")
}

# Which participant is on which side (kept out of the figures)
write_csv(df_report |>
            filter(!is.na(pair)) |>
            select(pair, discriminability, prolific_id, phq9_sum, band,
                   sigma, sigma_lo, sigma_hi, p_none, p_none_lo, p_none_hi,
                   n_above, n_above_lo, n_above_hi),
          file.path(output_clinical_dir, "discriminability_pairs_key.csv"))
