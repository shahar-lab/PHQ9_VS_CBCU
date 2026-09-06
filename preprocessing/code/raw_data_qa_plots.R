#### RT/EXCLUSION CUTOFFS (exploratory — easy to change later) ####

rt_fast_cutoff_ms <- 200
rt_slow_cutoff_ms <- 10000

qa_pal <- c("#0072B2", "#E69F00", "#009E73", "#D55E00", "#CC79A7", "#56B4E9")

#### PREP: PAIRWISE TRIALS + SUBJECT-SESSION LABEL ####

pairwise <- cbcu_results |>
  dplyr::filter(phase == "pairwise") |>
  dplyr::mutate(
    # phase_trial_num arrives as character from build_raw.R (never coerced there, per its
    # data dictionary), so it needs the same clean-then-coerce treatment as the other
    # numeric columns upstream, not a bare as.numeric().
    phase_trial_num = as.numeric(ifelse(phase_trial_num %in% c("NA", ""), NA, phase_trial_num)),
    subject_session = paste(prolific_pid, study_session, sep = " / ")
  )

#### PLOT 1: RT BY TRIAL ORDER, FACETED BY SUBJECT ####

p_rt_by_trial <- ggplot2::ggplot(pairwise, ggplot2::aes(x = phase_trial_num, y = rt, colour = study_session)) +
  ggplot2::geom_line(alpha = 0.6) +
  ggplot2::geom_point(size = 0.6, alpha = 0.6) +
  ggplot2::facet_wrap(~ subject_session) +
  ggplot2::scale_colour_manual(values = qa_pal) +
  ggplot2::labs(title = "RT by trial order, per subject/session",
                x = "Trial order (phase_trial_num)", y = "RT (ms)", colour = "Session") +
  ggplot2::theme_minimal(base_size = 8)

#### PLOT 2: RT HISTOGRAM, FACETED BY SUBJECT ####

# ASSUMED[PI said "experiment a bit"]: log10 x-axis chosen over free y-scales —
# RT spans fast/slow orders of magnitude, and a log x-axis keeps facets comparable
# on one shared y-axis rather than letting per-facet y-scales distort relative counts.
p_rt_hist <- ggplot2::ggplot(pairwise, ggplot2::aes(x = rt, fill = study_session)) +
  ggplot2::geom_histogram(bins = 40, alpha = 0.8) +
  ggplot2::facet_wrap(~ subject_session) +
  ggplot2::scale_x_log10() +
  ggplot2::scale_fill_manual(values = qa_pal) +
  ggplot2::labs(title = "RT distribution, per subject/session (log10 x-axis)",
                x = "RT (ms, log10 scale)", y = "Count", fill = "Session") +
  ggplot2::theme_minimal(base_size = 8)
