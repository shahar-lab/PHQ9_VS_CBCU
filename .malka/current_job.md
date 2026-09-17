Job Card
JOB
Build processed-data exclusions from line 67 of preprocessing/main.R, one sourced script per researcher criterion, and keep a running exclusion.md
FOLDER
preprocessing/ (repair)
ROUTED READS
- 01-preprocessing/references/02_convert-raw-to-processed.md
- 01-preprocessing/references/how-to-summarise-exclusions.md
- 01-preprocessing/references/conversion-and-filter-traps.md
- 01-preprocessing/references/handling-leaving-window.md
CHECKS
- Participant-level exclusion criteria and cutoffs
- Trial-level exclusion criteria and cutoffs
- Calculated columns and formulae
SPECIFICATION
- Work from `#### PROCESSED DATA ####` (line 67) forward
- One numbered source script per criterion; write the criterion as a comment above that `source()` in main.R
- Researcher will supply criteria one at a time; do not invent cutoffs
- Participant criteria first, then trial criteria on remaining participants, unless the researcher orders otherwise
- Each script loads the previous step's survivors from artifacts, applies only that criterion, and saves survivors plus omitted IDs/rows
- Rewrite `preprocessing/output/processed/exclusion.md` after every step as a simple numbered list: criterion, started with N participants, excluded X, Y left
- Do not change `data/raw/`
- Write `data/processed/` after the researcher says the last criterion is in
- Replace the current processed exclusion block (08–12 review and old `build_processed_*` filters) as the new scripts are added, so two pipelines do not run at once
- Pause after each script and wait for the next criterion
- Criterion 1 (participant): exclude if the participant did not have both time1 and time2 (present at both times in the union of raw CBCU and PHQ9)
- Criterion 2 (participant): among survivors of criterion 1, exclude if, on either time1 or time2, during PHQ9 or CBCU, the participant left the window twice or more (`n_window_exits > window_exit_max` with `window_exit_max <- 1`) OR was away more than 30 seconds total (`time_away_ms > max_window_left_ms` with `max_window_left_ms <- 30000`)
- PHQ9 rows: `phase == "phq9_grid"`; CBCU rows: pairwise trials and their ITIs; exits counted per task then summed within a session
- Scripts: `preprocessing/code/10_exclude_participants_missing_session.R`, `preprocessing/code/11_exclude_participants_window.R`, `preprocessing/code/12_exclude_trials_rt.R`, `preprocessing/code/13_exclude_participants_trial_rate.R`; report: `preprocessing/output/processed/exclusion.md`
- Criterion 3 (trial): among survivors of criterion 2, omit CBCU trials with missing RT or choice, RT under `rt_min_ms <- 500` (0.5 s), or RT over `rt_max_ms <- 15000` (15 s)
- Criterion 4 (participant): among survivors of criterion 2, exclude if criterion 3 omitted more than `max_trial_exclusion_pct <- 15` percent of trials in either time1 or time2; remaining good trials of those participants are also dropped
