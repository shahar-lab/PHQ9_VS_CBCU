#### PLOT CLINICAL REPORT (ONE PAGE PER PATIENT, ARTICLE VERSION) ####
# reads: objects from prep_clinical_report.R and prep_clinical_report_summaries.R
# writes: output/clinical reports/clinical_report.pdf (all pages),
#         clinical_report_patient<k>.pdf/.png, patient_key.csv
# Adapted from PHQ9_pairwise_pilot/analysis/beta_tau_pairwise/code/plot_clinical_report.R
# Title: patient number and PHQ-9 sum. A ladder (top and bottom 3 symptoms), beside it the
# PHQ-9 sum as text (score and severity band; untagged), B discriminability.

# Sequential (heatmap-like) light-to-dark scale for the ordinal PHQ-9 answer (ColorBrewer
# OrRd, 4 classes; the user's choice: a gradient, not distinct hues). The legend's keys touch,
# so it reads as one colour bar.
pal_likert <- c("Not at all" = "#FEF0D9", "Several days" = "#FDCC8A",
                "More than half the days" = "#FC8D59", "Nearly every day" = "#D7301F")
likert_labels <- c("0" = "Not at all", "1" = "Several days",
                   "2" = "More than half the days", "3" = "Nearly every day")
pal_band <- c("Minimal" = "#DDDDDD", "Mild" = "#DDCC77", "Moderate" = "#EE8866",
              "Moderately severe" = "#CC6677", "Severe" = "#882255")
thr_col  <- "#6B4C82"
disc_col <- "#EF6548"   # discriminability gauge: OrRd, in harmony with pal_likert (user's choice)
n_show   <- 3           # ladder shows the top and bottom n_show symptoms only (user's choice)
phq9_max <- 27
base_size <- 12

# One patient's four panels as a list: ladder, severity (PHQ-9 sum and band as text),
# consistency and burden (gauges). patient: one row of df_report. ladder_limit: if given, the ladder's utility
# axis runs from -ladder_limit to ladder_limit (symmetric about 0, the patient's average
# symptom), so patients shown side by side share one scale; otherwise it fits this
# patient's ladder. ladder_title: optional title over the ladder. severity_shared: TRUE when
# one PHQ-9 text block stands for two patients with the same sum (labelled so).
# show_unbounded_threshold: TRUE also draws the threshold of a patient who never chose None
# (bounded from above by the data only, its lower side set by the prior).
# never_none_notes: FALSE drops the "never chose None" wording from the threshold label and
# the burden gauge (the user's choice for the pair figures).
# Also used by plot_discriminability_pairs.R.
build_report_parts <- function(patient, ladder_limit = NULL, ladder_title = NULL,
                               severity_shared = FALSE, show_unbounded_threshold = FALSE,
                               never_none_notes = TRUE) {
  # Only the top and bottom n_show symptoms (by posterior-median rank) are drawn; one empty
  # row between them stands for the hidden middle. Tiers keep their full-ladder numbers.
  df_l_all <- df_ladder |>
    filter(prolific_id == patient$prolific_id) |>
    arrange(position)
  n_total  <- nrow(df_l_all)
  gap_y    <- n_show + 1
  df_l <- df_l_all |>
    filter(position <= n_show | position > n_total - n_show) |>
    mutate(y = if_else(position <= n_show, 2 * n_show + 2 - position, n_total + 1 - position),
           likert_label = factor(likert_labels[as.character(phq9_answer)], levels = likert_labels))

  # Alternate light grey shading marks the tiers (items within a tier are tied)
  df_tier_bands <- df_l |>
    group_by(tier) |>
    summarise(ymin = min(y) - 0.5, ymax = max(y) + 0.5, .groups = "drop") |>
    mutate(shade = if_else(tier %% 2 == 1, "grey93", "white"), label = paste("Tier", tier))

  x_lo    <- if (is.null(ladder_limit)) min(df_l$.lower, patient$thr_lo) else -ladder_limit
  x_hi    <- if (is.null(ladder_limit)) max(df_l$.upper, patient$thr_hi) else  ladder_limit
  x_breaks <- if (is.null(ladder_limit)) waiver() else
    keep(pretty(c(x_lo, x_hi)), \(b) abs(b) <= ladder_limit)
  strip_x <- x_lo - 0.08 * (x_hi - x_lo)
  tier_x  <- x_hi + 0.04 * (x_hi - x_lo)
  # Without a None choice tau is bounded from one side only, so by default no line is drawn
  thr_on    <- !patient$never_skipped || show_unbounded_threshold
  thr_label <- if (patient$never_skipped && never_none_notes) "burden threshold (never chose None)" else
    "burden threshold"

  p_ladder <- ggplot(df_l) +
    geom_rect(data = df_tier_bands, aes(xmin = -Inf, xmax = Inf, ymin = ymin, ymax = ymax),
              fill = df_tier_bands$shade) +
    {if (thr_on) list(
      annotate("rect", xmin = patient$thr_lo, xmax = patient$thr_hi, ymin = -Inf, ymax = Inf,
               fill = thr_col, alpha = 0.10),
      annotate("segment", x = patient$thr, xend = patient$thr, y = -Inf, yend = Inf,
               colour = thr_col, linetype = "dashed", linewidth = 0.6),
      annotate("label", x = patient$thr, y = max(df_l$y) + 0.9, label = thr_label,
               colour = thr_col, fill = "white", border.colour = NA, size = 3.2))} +
    geom_segment(aes(x = .lower, xend = .upper, y = y, yend = y), colour = "grey55", linewidth = 0.9) +
    geom_point(aes(x = u, y = y), colour = "grey15", size = 2.6) +
    # show.legend = TRUE keeps a key for answers this patient never gave
    geom_tile(aes(x = !!strip_x, y = y, fill = likert_label), width = 0.045 * (x_hi - x_lo),
              height = 0.8, show.legend = TRUE) +
    geom_text(data = df_tier_bands, aes(x = !!tier_x, y = (ymin + ymax) / 2, label = label),
              hjust = 0, size = 3.2, colour = "grey40") +
    # White box so the threshold line does not run through the text
    annotate("label", x = (x_lo + x_hi) / 2, y = gap_y, size = 3.4, fontface = "italic", colour = "grey40",
             fill = "white", border.colour = NA,
             label = sprintf("%d middle-ranked symptoms not shown", n_total - 2 * n_show)) +
    scale_fill_manual(values = pal_likert, drop = FALSE, na.value = "white", name = "PHQ-9 answer",
                      guide = guide_legend(nrow = 1, title.position = "left", label.position = "bottom",
                                           override.aes = list(colour = NA))) +
    scale_y_continuous(breaks = df_l$y, labels = df_l$item_short,
                       expand = expansion(add = c(0.3, 1.2))) +
    scale_x_continuous(breaks = x_breaks, expand = expansion(mult = c(0.04, 0.14))) +
    theme_classic(base_size = base_size) +
    theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(),
          axis.title.y = element_blank(), legend.position = "bottom",
          legend.key.width = unit(3.6, "cm"), legend.key.height = unit(0.45, "cm"),
          legend.key.spacing.x = unit(0, "pt"),
          legend.title = element_text(size = base_size - 2, vjust = 1),
          legend.text = element_text(size = base_size - 2)) +
    labs(x = "Utility (posterior median and 90% HDI)", title = ladder_title)

  # PHQ-9 sum as text, not a bar (the user's choice): label, number, severity band.
  # ignore_tag: a text block, so it takes no panel letter.
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

  source(file.path(code_dir, "plot_clinical_report_gauges.R"), local = TRUE)   # p_d

  list(ladder = p_ladder, severity = p_severity, consistency = p_d)
}

# A gauge centred in its column (half its width)
center_gauge <- \(p) wrap_plots(list(plot_spacer(), p, plot_spacer()), widths = c(1, 2, 1))

# One patient's panels laid out as one report page (no page title): ladder with the PHQ-9
# text to its right, the discriminability gauge under the ladder
build_report_panels <- function(patient, ...) {
  parts <- build_report_parts(patient, ...)
  wrap_plots(list(wrap_plots(parts$ladder, parts$severity, widths = c(3, 1)),
                  wrap_plots(list(center_gauge(parts$consistency), plot_spacer()), widths = c(3, 1))),
             ncol = 1, heights = c(4, 1), guides = "collect")   # legend under the whole page
}

pages <- list()

for (pid in df_report$prolific_id[!is.na(df_report$patient)]) {
  patient <- filter(df_report, prolific_id == pid, !is.na(patient))

  # The page title's style goes in plot_annotation(theme = ...) so it does not reach the
  # gauge titles; only the tag style is applied to every panel with &
  pages[[pid]] <- build_report_panels(patient) +
    plot_annotation(
      title = sprintf("Patient %d", patient$patient),
      subtitle = sprintf("PHQ-9 sum score %d (%s)", as.integer(patient$phq9_sum), tolower(patient$band)),
      tag_levels = "A",
      theme = theme(plot.title = element_text(face = "bold", size = base_size + 3),
                    plot.subtitle = element_text(size = base_size, colour = "grey30"))) &
    theme(plot.tag = element_text(face = "bold", size = 14), legend.position = "bottom")
}

pdf(file.path(output_clinical_dir, "clinical_report.pdf"), width = 10, height = 6)
for (pid in names(pages)) print(pages[[pid]])
dev.off()

for (pid in names(pages)) {
  # A subject who is also in a discriminability pair has a second row with patient = NA
  plot_name <- paste0("clinical_report_patient",
                      df_report$patient[df_report$prolific_id == pid & !is.na(df_report$patient)])
  ggsave(file.path(output_clinical_dir, paste0(plot_name, ".pdf")), plot = pages[[pid]],
         width = 10, height = 6, bg = "white")
  ggsave(file.path(output_clinical_dir, paste0(plot_name, ".png")), plot = pages[[pid]],
         width = 10, height = 6, dpi = 300, bg = "white")
}

# Which participant each patient number is (kept out of the figures)
write_csv(df_report |>
            filter(!is.na(patient)) |>
            select(patient, prolific_id, profile, matches_profile, phq9_sum, band),
          file.path(output_clinical_dir, "patient_key.csv"))
