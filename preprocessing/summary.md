# Preprocessing Notebook

**Date:** 2026-09-13
**Data source:** `data/collected/` (first_wave and second_wave Pavlovia CSVs, plus the Prolific demographics export)

## Pipeline

1. Read and bind collected CSVs; tag session as `time1` / `time2`.
2. Describe collected data as it arrived (`output/reports-collected/02_summary-collected-data.html`).
3. Split the long log into tidy raw tables (CBCU, quiz, PHQ9, feedback, demographics) and write a data-type-validation HTML per table. Raw tables keep every observation.
4. CBCU `time_elapsed` is overwritten in raw: per session (`prolific_id` × `time`), time zero is the onset of the first pairwise trial (`jsPsych time_elapsed − rt`). Each row is that trial’s own onset minus time zero, stored as `hms`. Trial 1 is `00:00:00`. Block is assigned on the native jsPsych clock before this overwrite.
5. Plot every raw CBCU RT against trial number as an interactive HTML with a session dropdown (`time1` / `time2` / both), sliders, a participant dropdown, and a trial-count table that shows counts and percent of trials.
6. Review participant/trial exclusions without changing `data/raw/`: screen participants first, then flag window-departure trials among survivors; pass review objects through `artifacts/`; write `output/reports-processed/exclusion.md`.
7. QA report on CBCU pairwise raw data.
8. Processed CBCU: participant exclusions, then trial exclusions; PHQ9 processed adds `phq9_sum`.
9. Manuscript “Data treatment” paragraph.

## Reports

- `output/reports-collected/` — reports about collected data
- `output/reports-raw/` — reports about raw data
- `output/reports-processed/` — reports about processed data and exclusions

## Exclusion criteria

- Processed-data review — participant completeness: require exactly 105 CBCU pairwise trials and all 9 PHQ responses at both `time1` and `time2`. `data/raw/` is not changed.
- Processed-data review — participant window time: after completeness screening, exclude a participant when active-task departures exceed 30 seconds in either session; scheduled `phase2_break` departures do not count.
- Processed-data review — trial window departure: among surviving participants, flag a CBCU trial when the participant left during its preceding same-numbered pairwise ITI or its pairwise response row.
- Existing processed-data participant criteria remain unchanged: missing a session; more than 2 window exits in either session; more than 40% of trials would be excluded in either session; quiz comprehension — 3 or more of 6 questions needed a retry in either session.
- Existing processed-data trial criteria remain unchanged: missing `rt` or `choice`; RT under 200 ms or over 10000 ms.

## Findings / Summary

- (Leave this section blank until the pipeline has been run and reviewed.)
