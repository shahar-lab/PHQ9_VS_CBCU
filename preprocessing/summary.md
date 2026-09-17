# Preprocessing Notebook

**Date:** 2026-09-13
**Data source:** `data/collected/` (first_wave and second_wave Pavlovia CSVs, plus the Prolific demographics export)

## Pipeline

1. Read and bind collected CSVs; tag session as `time1` / `time2`.
2. Describe collected data as it arrived (`output/collected/02_summary-collected-data.html`).
3. Split the long log into tidy raw tables (CBCU, quiz, PHQ9, feedback, demographics) and write a data-type-validation HTML per table. Raw tables keep every observation.
4. CBCU `time_elapsed` is overwritten in raw: per session (`prolific_id` × `time`), time zero is the onset of the first pairwise trial (`jsPsych time_elapsed − rt`). Each row is that trial’s own onset minus time zero, stored as `hms`. Trial 1 is `00:00:00`. Block is assigned on the native jsPsych clock before this overwrite.
5. Plot every raw CBCU RT against trial number as an interactive HTML with a session dropdown (`time1` / `time2` / both), sliders, a participant dropdown, and a trial-count table that shows counts and percent of trials.
6. Processed exclusions, one criterion per sourced script; `output/processed/exclusion.md` lists each step with how many started, were excluded, and remain.
7. Write surviving CBCU and PHQ rows to `data/processed/cbcu.csv` and `data/processed/phq.csv`.
8. Manuscript excerpts: `output/processed/15_participants_excerpt.md` and `output/processed/15_data_treatment_excerpt.md`.

## Reports

- `output/collected/` — reports about collected data
- `output/raw/` — reports about raw data
- `output/processed/` — reports about processed data and exclusions

## Exclusion criteria

- Processed, participant: exclude a participant who did not have both `time1` and `time2`.
- Processed, participant: among survivors, exclude a participant who left the window twice or more, or for more than 30 seconds total, on either `time1` or `time2`, during PHQ9 or CBCU.
- Processed, trial: among remaining participants, omit CBCU trials with missing RT or choice, RT under 0.5 seconds, or RT over 15 seconds.
- Processed, participant: exclude a participant if that trial omission was more than 15% of their trials in either `time1` or `time2`. `data/raw/` is not changed. After these steps, surviving CBCU trials and PHQ rows are written to `data/processed/`.

## Findings / Summary

- (Leave this section blank until the pipeline has been run and reviewed.)
