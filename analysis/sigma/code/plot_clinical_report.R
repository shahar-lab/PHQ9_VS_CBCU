#### PLOT CLINICAL REPORT (ONE PAGE PER PATIENT, ARTICLE VERSION) ####
# reads: objects from prep_clinical_report.R and prep_clinical_report_summaries.R
# writes: output/clinical reports/clinical_report.pdf (all pages),
#         clinical_report_patient<k>.pdf/.png, patient_key.csv
# Adapted from analysis/beta_tau_halfnormal_stz/code/plot_clinical_report.R
# Title: patient number and PHQ-9 sum. A ladder of all 15 symptoms and None ("Neither"),
# ordered by P(bothers most) (posterior mean and 90% HDCI; see prep_clinical_report.R),
# beside it the PHQ-9 sum as text (score and severity band; untagged), B the sigma gauge.
# Differences from the beta report: probabilities instead of utilities, all 16 rows shown,
# no tiers, no threshold line (None is a row of its own, shaded), sigma instead of
# P(higher option | not None).

# Sequential light-to-dark scale for the ordinal PHQ-9 answer (as in the beta report)
pal_likert <- c("Not at all" = "#FEF0D9", "Several days" = "#FDCC8A",
                "More than half the days" = "#FC8D59", "Nearly every day" = "#D7301F")
likert_labels <- c("0" = "Not at all", "1" = "Several days",
                   "2" = "More than half the days", "3" = "Nearly every day")
thr_col   <- "#6B4C82"   # None row (was the burden threshold colour)
disc_col  <- "#EF6548"   # discriminability gauge
base_size <- 12
page_width  <- 10
page_height <- 8          # 16 ladder rows (the beta report showed 6 on a 6 in page)

# P(bothers most) is a probability, so its axis is always [0, 1] (the PI's full-range rule)
p_breaks <- seq(0, 1, by = 0.25)

# sigma gauge: track from 0 to sigma_axis_max (shared by all patients), coloured bar = 95% HDCI,
# dot = posterior median, tick = sample median of all time 1 participants
build_sigma_gauge <- function(patient) {
  ggplot() +
    annotate("segment", x = 0, xend = sigma_axis_max, y = 0, yend = 0,
             colour = "grey88", linewidth = 5, lineend = "round") +
    annotate("segment", x = patient$sigma_lo, xend = patient$sigma_hi, y = 0, yend = 0,
             colour = disc_col, linewidth = 5, lineend = "round") +
    annotate("segment", x = sigma_sample_median, xend = sigma_sample_median, y = -0.45, yend = 0.45,
             colour = "grey35", linewidth = 0.6) +
    annotate("point", x = patient$sigma, y = 0, size = 3.5, colour = "grey15") +
    annotate("text", x = patient$sigma, y = 0.8, label = sprintf("%.1f", patient$sigma),
             fontface = "bold", size = 4) +
    annotate("text", x = c(0, sigma_sample_median, sigma_axis_max), y = -0.6,
             label = c("0", "sample median", sprintf("%.0f", sigma_axis_max)),
             size = 3.2, colour = "grey35", vjust = 1) +
    coord_cartesian(xlim = c(-0.04, 1.04) * sigma_axis_max, ylim = c(-1.8, 1.4), clip = "off") +
    theme_void(base_size = base_size) +
    theme(plot.title = element_text(size = base_size, hjust = 0.5, margin = margin(b = 4))) +
    labs(title = expression("Discriminability (" * sigma * ")"))
}

# One patient's panels as a list: ladder, severity (PHQ-9 sum and band as text), sigma gauge.
# patient: one row of df_report. ladder_title: optional title over the ladder.
# severity_shared: TRUE when one PHQ-9 text block stands for two patients with the same sum.
# Also used by plot_discriminability_pairs.R.
build_report_parts <- function(patient, ladder_title = NULL, severity_shared = FALSE) {
  df_l <- df_ladder |>
    filter(prolific_id == patient$prolific_id) |>
    arrange(position) |>
    mutate(y = max(position) + 1 - position,   # most bothersome at the top
           likert_label = factor(likert_labels[as.character(phq9_answer)], levels = likert_labels))
  y_none  <- df_l$y[df_l$item == none_item]
  strip_x <- -0.06

  p_ladder <- ggplot(df_l) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = y_none - 0.5, ymax = y_none + 0.5,
             fill = thr_col, alpha = 0.12) +
    geom_segment(aes(x = .lower, xend = .upper, y = y, yend = y,
                     colour = item == none_item), linewidth = 0.9) +
    geom_point(aes(x = p, y = y, colour = item == none_item), size = 2.6) +
    scale_colour_manual(values = c("FALSE" = "grey15", "TRUE" = thr_col), guide = "none") +
    # PHQ-9 answer of the symptom's PHQ-9 item; None has none. show.legend = TRUE keeps a key
    # for answers this patient never gave
    geom_tile(data = filter(df_l, item != none_item),
              aes(x = !!strip_x, y = y, fill = likert_label), width = 0.045,
              height = 0.8, show.legend = TRUE) +
    scale_fill_manual(values = pal_likert, drop = FALSE, na.value = "white", name = "PHQ-9 answer",
                      guide = guide_legend(nrow = 1, title.position = "left", label.position = "bottom",
                                           override.aes = list(colour = NA))) +
    scale_y_continuous(breaks = df_l$y, labels = df_l$item_short, expand = expansion(add = 0.6)) +
    # Axis always to 1 (left end leaves room for the PHQ-9 strip, which spans strip_x +/- 0.0225)
    scale_x_continuous(breaks = p_breaks, limits = c(strip_x - 0.03, 1),
                       expand = expansion(mult = c(0.01, 0.02))) +
    theme_classic(base_size = base_size) +
    theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(),
          axis.title.y = element_blank(), legend.position = "bottom",
          legend.key.width = unit(3.6, "cm"), legend.key.height = unit(0.45, "cm"),
          legend.key.spacing.x = unit(0, "pt"),
          legend.title = element_text(size = base_size - 2, vjust = 1),
          legend.text = element_text(size = base_size - 2)) +
    labs(x = "P(bothers most) (posterior mean and 90% HDI)", title = ladder_title)

  # PHQ-9 sum as text: label, number, severity band. ignore_tag: no panel letter.
  p_severity <- (ggplot() +
    annotate("text", x = 0.5, y = c(0.64, 0.52, 0.40),
             label = c("PHQ-9 score", as.integer(patient$phq9_sum), patient$band),
             size = c(4.6, 11, 4.6), fontface = c("plain", "bold", "plain"),
             colour = c("grey30", "grey10", "grey10")) +
    {if (severity_shared)
      annotate("text", x = 0.5, y = 0.33, label = "(both participants)", size = 3.6,
               fontface = "italic", colour = "grey40")} +
    coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), clip = "off") +
    theme_void(base_size = base_size)) |>
    wrap_elements(full = _, ignore_tag = TRUE)

  list(ladder = p_ladder, severity = p_severity, consistency = build_sigma_gauge(patient))
}

# A gauge centred in its column (half its width)
center_gauge <- \(p) wrap_plots(list(plot_spacer(), p, plot_spacer()), widths = c(1, 2, 1))

# One patient's panels laid out as one report page: ladder with the PHQ-9 text to its right,
# the sigma gauge under the ladder
build_report_panels <- function(patient, ...) {
  parts <- build_report_parts(patient, ...)
  wrap_plots(list(wrap_plots(parts$ladder, parts$severity, widths = c(3, 1)),
                  wrap_plots(list(center_gauge(parts$consistency), plot_spacer()), widths = c(3, 1))),
             ncol = 1, heights = c(6, 1), guides = "collect")   # legend under the whole page
}

pages <- list()

for (pid in df_report$prolific_id[!is.na(df_report$patient)]) {
  patient <- filter(df_report, prolific_id == pid, !is.na(patient))

  pages[[pid]] <- build_report_panels(patient) +
    plot_annotation(
      title = sprintf("Patient %d", patient$patient),
      subtitle = sprintf("PHQ-9 sum score %d (%s)", as.integer(patient$phq9_sum), tolower(patient$band)),
      tag_levels = "A",
      theme = theme(plot.title = element_text(face = "bold", size = base_size + 3),
                    plot.subtitle = element_text(size = base_size, colour = "grey30"))) &
    theme(plot.tag = element_text(face = "bold", size = 14), legend.position = "bottom")
}

pdf(file.path(output_clinical_dir, "clinical_report.pdf"), width = page_width, height = page_height)
for (pid in names(pages)) print(pages[[pid]])
dev.off()

for (pid in names(pages)) {
  # A subject who is also in a discriminability pair has a second row with patient = NA
  plot_name <- paste0("clinical_report_patient",
                      df_report$patient[df_report$prolific_id == pid & !is.na(df_report$patient)])
  ggsave(file.path(output_clinical_dir, paste0(plot_name, ".pdf")), plot = pages[[pid]],
         width = page_width, height = page_height, bg = "white")
  ggsave(file.path(output_clinical_dir, paste0(plot_name, ".png")), plot = pages[[pid]],
         width = page_width, height = page_height, dpi = 300, bg = "white")
}

# Which participant each patient number is (kept out of the figures)
write_csv(df_report |>
            filter(!is.na(patient)) |>
            select(patient, prolific_id, profile, matches_profile, phq9_sum, band,
                   sigma, sigma_lo, sigma_hi, p_none),
          file.path(output_clinical_dir, "patient_key.csv"))
