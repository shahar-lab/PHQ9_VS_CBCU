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
|Starting point (all participants)                                      |          |          11|            |
|Missing a session                                                      |         1|          10|         9.1|
|Too many window exits (n_departures > 2 in either session)             |         1|          10|         9.1|
|Too many trials would be excluded (>40% in either session)             |         0|          11|         0.0|
|Quiz comprehension (>=3 of 6 questions needed a retry, either session) |         0|          11|         0.0|

## Excluded participants

|prolific_pid             |reasons         |
|:------------------------|:---------------|
|6946d43d6e37a8ebea7882bd |window_exits    |
|6a0b57dda1f2bbc0f2c1398b |missing_session |

## Trial exclusions (counts in observations)

|criterion                                     | n_omitted| n_remaining| pct_omitted|
|:---------------------------------------------|---------:|-----------:|-----------:|
|Starting point (after participant exclusions) |          |        1890|            |
|No response recorded                          |         0|        1890|         0.0|
|RT under 200ms or over 10000ms                |       130|        1760|         6.9|

**Final: 1,760 observations across 9 participants.**

## Per participant after exclusion

Percentages are of that session's original pairwise trial count, and
`pct_excluded_missing` + `pct_excluded_fast` + `pct_excluded_slow` = `pct_excluded_total`.

|prolific_pid             |study_session | n_trials| pct_excluded_total| pct_excluded_missing| pct_excluded_fast| pct_excluded_slow|
|:------------------------|:-------------|--------:|------------------:|--------------------:|-----------------:|-----------------:|
|5d50692435e3af0001f05a15 |session_1     |       99|                5.7|                    0|                 0|               5.7|
|5d50692435e3af0001f05a15 |session_2     |      104|                1.0|                    0|                 0|               1.0|
|66b588a4b3e0e55fc74390b3 |session_1     |       92|               12.4|                    0|                 0|              12.4|
|66b588a4b3e0e55fc74390b3 |session_2     |      104|                1.0|                    0|                 0|               1.0|
|67798278a28708e32bf4b451 |session_1     |      105|                0.0|                    0|                 0|               0.0|
|67798278a28708e32bf4b451 |session_2     |      105|                0.0|                    0|                 0|               0.0|
|69d60b821c7fcd0fae5faf58 |session_1     |       99|                5.7|                    0|                 0|               5.7|
|69d60b821c7fcd0fae5faf58 |session_2     |      102|                2.9|                    0|                 0|               2.9|
|69f0b7ddbaaead7656414805 |session_1     |      104|                1.0|                    0|                 0|               1.0|
|69f0b7ddbaaead7656414805 |session_2     |      104|                1.0|                    0|                 0|               1.0|
|6a0c5f6a4974d3dfbeb467ae |session_1     |       94|               10.5|                    0|                 0|              10.5|
|6a0c5f6a4974d3dfbeb467ae |session_2     |       75|               28.6|                    0|                 0|              28.6|
|6a241cc77b290774b3626f62 |session_1     |      102|                2.9|                    0|                 0|               2.9|
|6a241cc77b290774b3626f62 |session_2     |      102|                2.9|                    0|                 0|               2.9|
|6a25badf2f95439c4b79d399 |session_1     |      100|                4.8|                    0|                 0|               4.8|
|6a25badf2f95439c4b79d399 |session_2     |      101|                3.8|                    0|                 0|               3.8|
|6a26623dba3ca97e10bd6e4a |session_1     |       83|               21.0|                    0|                 0|              21.0|
|6a26623dba3ca97e10bd6e4a |session_2     |       85|               19.0|                    0|                 0|              19.0|
