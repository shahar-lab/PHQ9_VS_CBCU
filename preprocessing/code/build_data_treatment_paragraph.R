#### COMPUTE TRIAL-OMISSION STATISTICS ####

n_trials_pre_exclusion <- nrow(after_participant_exclusions)
n_trials_omitted       <- nrow(after_participant_exclusions) - nrow(after_slow_rt)
pct_trials_omitted     <- round(100 * n_trials_omitted / n_trials_pre_exclusion, 2)

#### COMPUTE PARTICIPANT-EXCLUSION STATISTICS ####

n_excluded_participants <- dplyr::n_distinct(excluded_participants$prolific_pid)
pct_excluded_participants <- round(100 * n_excluded_participants / length(all_pids), 1)
n_included_participants <- length(included_participants)

# ASSUMED[no wording given for demographics]: fixed placeholder text, ready to be replaced
# once demographics data is joined into this pipeline. Describes the RETAINED/included
# sample, not the excluded group.
demographics_placeholder <- "age mean, ___; range, ___ to ___; ___ males, ___ females"

#### COMPUTE FINAL TRIAL-COUNT STATISTICS ####

trials_per_participant <- per_participant_after_exclusion$n_trials

mean_trials <- round(mean(trials_per_participant), 1)
sd_trials   <- round(sd(trials_per_participant), 1)
min_trials  <- min(trials_per_participant)
max_trials  <- max(trials_per_participant)

#### ASSEMBLE PARAGRAPH TEXT ####

sentence_rt <- paste0(
  "Trials with implausibly quick RTs (<", rt_fast_cutoff_ms, " ms) or exceptionally slow RTs (>",
  rt_slow_cutoff_ms, " ms) or with no recorded response were omitted (", pct_trials_omitted,
  "% of trials among included participants)."
)

sentence_participants <- paste0(
  "Participants missing a session, with more than 2 window-exit events in a session, more ",
  "than 40% of a session's trials excluded, or 3 or more quiz questions requiring a retry in ",
  "a session, in total ", n_excluded_participants, " participants (", pct_excluded_participants,
  "% of subjects), were excluded altogether."
)

sentence_sample <- paste0(
  "The final sample consisted of ", n_included_participants, " participants (",
  demographics_placeholder, ")."
)

sentence_trial_count <- paste0(
  "This resulted in an average of ", mean_trials, " trials per participant (SD = ", sd_trials,
  "), with the number of trials ranging from ", min_trials, " to ", max_trials, " across subjects."
)

paragraph_text <- paste(sentence_rt, sentence_participants, sentence_sample, sentence_trial_count)

#### RENDER PDF ####

grDevices::pdf(file.path(output_dir, "data_treatment_paragraph.pdf"), width = 10, height = 8, bg = "white")

grid::grid.newpage()
grid::grid.text("Data treatment", x = 0.05, y = 0.9, just = "left",
                 gp = grid::gpar(fontsize = 16, fontface = "bold"))

# Conservative fixed wrap width chosen to guarantee the text fits within the page margins:
# at fontsize 12, average character width is at most ~0.117in (worst case for a proportional
# font), so 75 chars <= 75 * 0.117in ~= 8.8in of text width, safely under the 9in usable width
# (10in page, 0.5in left margin at x = 0.05, matching 0.5in right margin reserved below).
wrapped_lines <- strwrap(paragraph_text, width = 75)
grid::grid.text(paste(wrapped_lines, collapse = "\n"), x = 0.05, y = 0.85, just = c("left", "top"),
                 gp = grid::gpar(fontsize = 12))

grDevices::dev.off()
