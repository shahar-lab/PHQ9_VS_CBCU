# Preprocessing Notebook

**Date:** 2026-09-13
**Data source:** `data/collected/` (`session 1` and `session 2` Pavlovia CSVs, plus the `demographic survey` and `MacArthur` Qualtrics exports)

## Pipeline

1. Read and bind collected CSVs from `session 1` / `session 2`; tag session as `time1` / `time2`. `session_id` NA is recoded to `session_1`; other values are kept.
2. Describe collected data as it arrived (`output/collected/02_summary-collected-data.html`).
3. Split the long log into tidy raw tables (CBCU, quiz, PHQ9, feedback) and build demographics from the Qualtrics exports (always excluded: preview rows, blank or "test" ids, ids in `test_prolific_ids`; first submission kept per id; the exports are then joined by `prolific_id` in a temporary block to remove once demographics arrive in one file). Write a data-type-validation HTML per table. Raw tables keep every observation.
4. CBCU `time_elapsed` is overwritten in raw: per session (`prolific_id` × `time`), time zero is the onset of the first pairwise trial (`jsPsych time_elapsed − rt`). Each row is that trial’s own onset minus time zero, stored as `hms`. Trial 1 is `00:00:00`. Block is assigned on the native jsPsych clock before this overwrite.
5. Processed exclusions, one criterion per sourced script; `output/processed/exclusion.md` lists each step with how many started, were excluded, and remain.
6. Write surviving CBCU and PHQ rows to `data/processed/cbcu.csv` and `data/processed/phq.csv`.
7. Manuscript excerpts: `output/processed/15_participants_excerpt.md` and `output/processed/15_data_treatment_excerpt.md`.

## Reports

- `output/collected/` — reports about collected data
- `output/raw/` — reports about raw data
- `output/processed/` — reports about processed data and exclusions

## Exclusion criteria

- Processed, participant: exclude a participant who did not have both `time1` and `time2`.
- Processed, participant: among survivors, exclude a participant who left the window twice or more, or for more than 30 seconds total, on either `time1` or `time2`, during PHQ9 or CBCU.
- Processed, trial: among remaining participants, omit CBCU trials with missing RT or choice (no response recorded). RT is kept exploratory only -- no RT cutoff is applied, and no participant is excluded based on RT or on quiz attempts. `data/raw/` is not changed. After these steps, surviving CBCU trials and PHQ rows are written to `data/processed/`.

## Findings / Summary

- (Leave this section blank until the pipeline has been run and reviewed.)
