# Raw-to-processed report

Built by `preprocessing/code/build_processed_participant_exclusions.R` and
`build_processed_trial_exclusions.R`. Participant criteria run first, then trial
criteria on the participants that remain.

**Note:** the four participant criteria below are independent checks evaluated
per-session (not a sequential cascade) — a participant tripping any one of them is
excluded entirely, and may trip more than one, so `n_omitted` counts can overlap across
rows and will not sum to the total number of participants excluded. See the excluded-
participants list below for the full per-participant reason set.

## Participant exclusions (counts in participants)

|criterion                                                              | n_omitted| n_remaining| pct_omitted|
|:----------------------------------------------------------------------|---------:|-----------:|-----------:|
|Starting point (all participants)                                      |          |           1|            |
|Missing a session                                                      |         0|           1|           0|
|Too many window exits (n_departures > 2 in either session)             |         0|           1|           0|
|Too many trials would be excluded (>40% in either session)             |         0|           1|           0|
|Quiz comprehension (>=3 of 6 questions needed a retry, either session) |         0|           1|           0|

## Excluded participants

|prolific_pid |reasons |
|:------------|:-------|

## Trial exclusions (counts in observations)

|criterion                                     | n_omitted| n_remaining| pct_omitted|
|:---------------------------------------------|---------:|-----------:|-----------:|
|Starting point (after participant exclusions) |          |         210|            |
|No response recorded                          |         0|         210|         0.0|
|RT under 200ms or over 10000ms                |         9|         201|         4.3|

**Final: 201 observations across 1 participants.**

## Per participant after exclusion

Percentages are of that session's original pairwise trial count, and
`pct_excluded_missing` + `pct_excluded_fast` + `pct_excluded_slow` = `pct_excluded_total`.

|prolific_pid             |study_session | n_trials| pct_excluded_total| pct_excluded_missing| pct_excluded_fast| pct_excluded_slow|
|:------------------------|:-------------|--------:|------------------:|--------------------:|-----------------:|-----------------:|
|6a25badf2f95439c4b79d399 |session_1     |      100|                4.8|                    0|                 0|               4.8|
|6a25badf2f95439c4b79d399 |session_2     |      101|                3.8|                    0|                 0|               3.8|
