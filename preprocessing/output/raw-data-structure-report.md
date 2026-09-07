# Raw data structure report

Built by `preprocessing/code/build_raw.R`. Describes each of the four tidy CSVs written
to `data/raw/` after the collected long-format event log was restructured: column names,
classes, meanings, and categorical/factor coding, one section per output file.

## cbcu_results.csv

### Numeric columns

|column          | n_missing|    min|       mean|     max|
|:---------------|---------:|------:|----------:|-------:|
|rt              |      2205|    401|   4725.802|  168969|
|rt_from_stim_ms |      2205|    401|   4725.802|  168969|
|stim_onset_ms   |      2205| 105179| 885254.132| 2209055|
|time_elapsed    |         0| 104103| 884232.697| 2208835|

### Categorical columns

|column              | n_missing| n_levels|labels                                                                                                                                                                                                                                                                                |
|:-------------------|---------:|--------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|chosen_item_number  |      2937|       15|1, 2a, 2b, 3a, 3b, 4                                                                                                                                                                                                                                                                  |
|chosen_item_text    |      2937|       15|Being so fidgety or restless that you have been moving around a lot more than usual, Feeling bad about yourself or that you are a failure, Feeling down or depressed, Feeling hopeless, Feeling that you have let yourself or your family down, Feeling tired or having little energy |
|chosen_side         |      2205|        3|left, right, skip                                                                                                                                                                                                                                                                     |
|left_item_number    |      2205|       15|1, 2a, 2b, 3a, 3b, 4                                                                                                                                                                                                                                                                  |
|left_item_text      |      2205|       15|Being so fidgety or restless that you have been moving around a lot more than usual, Feeling bad about yourself or that you are a failure, Feeling down or depressed, Feeling hopeless, Feeling that you have let yourself or your family down, Feeling tired or having little energy |
|participant_id      |         0|       21|3f5vbx91, 3qxfazs6, 3ry0dap0, 53povv20, 6eo527ny, 7xp8qfx3                                                                                                                                                                                                                            |
|phase               |         0|        2|iti, pairwise                                                                                                                                                                                                                                                                         |
|phase_trial_num     |         0|      105|1, 10, 100, 101, 102, 103                                                                                                                                                                                                                                                             |
|prolific_pid        |         0|       11|5d50692435e3af0001f05a15, 66b588a4b3e0e55fc74390b3, 67798278a28708e32bf4b451, 6946d43d6e37a8ebea7882bd, 69d60b821c7fcd0fae5faf58, 69f0b7ddbaaead7656414805                                                                                                                            |
|prolific_session_id |      2100|        2|6a96f18711f6c59dbfa56297, session_2                                                                                                                                                                                                                                                   |
|prolific_study_id   |         0|        4|6a96e8fee3cbae0da7c30ed0, 6a96ec018af1fd9a814e0d52, 6a9bed0e3ac0cdf0edd1e9fa, 6a9bedb67096b6da58724573                                                                                                                                                                                |
|right_item_number   |      2205|       15|1, 2a, 2b, 3a, 3b, 4                                                                                                                                                                                                                                                                  |
|right_item_text     |      2205|       15|Being so fidgety or restless that you have been moving around a lot more than usual, Feeling bad about yourself or that you are a failure, Feeling down or depressed, Feeling hopeless, Feeling that you have let yourself or your family down, Feeling tired or having little energy |
|session             |       210|       20|0hzfuf6x, 36hov9oz, 4gjf86qo, 6h4275tf, 7l63l3ep, 953ytv0u                                                                                                                                                                                                                            |
|skipped             |      2205|        4|false, FALSE, true, TRUE                                                                                                                                                                                                                                                              |
|study_session       |         0|        2|session_1, session_2                                                                                                                                                                                                                                                                  |

### Data dictionary

|column              |class     |meaning                                                                                                                                                                                                                                     |
|:-------------------|:---------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|participant_id      |character |jsPsych-generated per-session code (not stable across sessions; do not use as participant key)                                                                                                                                              |
|session             |character |jsPsych session code                                                                                                                                                                                                                        |
|prolific_pid        |factor    |Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.                                                                                              |
|prolific_study_id   |character |Prolific study ID                                                                                                                                                                                                                           |
|prolific_session_id |character |Prolific session ID (renamed from session_id in second_wave)                                                                                                                                                                                |
|rt                  |numeric   |jsPsych's built-in trial RT, ms (identical to rt_from_stim_ms in this task; both are timed from stimulus onset, kept as separate columns because jsPsych records rt automatically while rt_from_stim_ms is computed by the task's own code) |
|study_session       |factor    |session_1 = first_wave, session_2 = second_wave. Levels: session_1 (reference), session_2.                                                                                                                                                  |
|phase               |character |"pairwise" for the actual comparison-response row, "iti" for that trial's inter-trial-interval row. iti rows have no response (chosen_side, rt, etc. are NA by design, not missing data).                                                   |
|left_item_number    |character |left-side item identifier                                                                                                                                                                                                                   |
|left_item_text      |character |left-side item text                                                                                                                                                                                                                         |
|right_item_number   |character |right-side item identifier                                                                                                                                                                                                                  |
|right_item_text     |character |right-side item text                                                                                                                                                                                                                        |
|chosen_side         |character |left/right side chosen                                                                                                                                                                                                                      |
|chosen_item_number  |character |identifier of chosen item                                                                                                                                                                                                                   |
|chosen_item_text    |character |text of chosen item                                                                                                                                                                                                                         |
|rt_from_stim_ms     |numeric   |RT from stimulus onset, ms (see rt above)                                                                                                                                                                                                   |
|stim_onset_ms       |numeric   |stimulus onset time, ms                                                                                                                                                                                                                     |
|phase_trial_num     |character |trial number within the pairwise phase                                                                                                                                                                                                      |
|skipped             |character |whether the trial was skipped: "true" or "false" for pairwise response rows; blank/NA for the paired iti rows, where the field does not apply                                                                                               |

## cbcu_quizz.csv

### Numeric columns

|column       | n_missing|   min|      mean|     max|
|:------------|---------:|-----:|---------:|-------:|
|rt           |         0|  2799|  16055.67|   94772|
|time_elapsed |         0| 70229| 429766.74| 1143417|

### Categorical columns

|column                | n_missing| n_levels|labels                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|:---------------------|---------:|--------:|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|correct               |         0|        3|false, true, TRUE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|participant_id        |         0|       21|3f5vbx91, 3qxfazs6, 3ry0dap0, 53povv20, 6eo527ny, 7xp8qfx3                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|prolific_pid          |         0|       11|5d50692435e3af0001f05a15, 66b588a4b3e0e55fc74390b3, 67798278a28708e32bf4b451, 6946d43d6e37a8ebea7882bd, 69d60b821c7fcd0fae5faf58, 69f0b7ddbaaead7656414805                                                                                                                                                                                                                                                                                                                                          |
|prolific_session_id   |        61|        2|6a96f18711f6c59dbfa56297, session_2                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|prolific_study_id     |         0|        4|6a96e8fee3cbae0da7c30ed0, 6a96ec018af1fd9a814e0d52, 6a9bed0e3ac0cdf0edd1e9fa, 6a9bedb67096b6da58724573                                                                                                                                                                                                                                                                                                                                                                                              |
|quiz_attempt_num      |         0|        2|1, 2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|quiz_question_num     |         0|        6|1, 2, 3, 4, 5, 6                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|selected_option_index |         0|        4|0, 1, 2, 3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|selected_option_text  |         0|        9|Click on the problem that bothered you more in the last two weeks., If you have not experienced either problem in your entire life., No, but you are expected to answer as fast as possible without thinking too much., No, there is no time limit, so you should take your time to carefully reflect on each screen., Only when you are absolutely sure neither problem affected you at all in the last two weeks., Three breaks, giving you a chance to pause between the four parts of the task. |
|session               |         6|       20|0hzfuf6x, 36hov9oz, 4gjf86qo, 6h4275tf, 7l63l3ep, 953ytv0u                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|study_session         |         0|        2|session_1, session_2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |

### Data dictionary

|column                |class     |meaning                                                                                                                                        |
|:---------------------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------------|
|participant_id        |character |jsPsych-generated per-session code (not stable across sessions; do not use as participant key)                                                 |
|session               |character |jsPsych session code                                                                                                                           |
|prolific_pid          |factor    |Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference. |
|prolific_study_id     |character |Prolific study ID                                                                                                                              |
|prolific_session_id   |character |Prolific session ID (renamed from session_id in second_wave)                                                                                   |
|rt                    |numeric   |jsPsych's built-in RT for the quiz item, ms                                                                                                    |
|study_session         |factor    |session_1 = first_wave, session_2 = second_wave. Levels: session_1 (reference), session_2.                                                     |
|quiz_question_num     |character |quiz question number, 1-6                                                                                                                      |
|quiz_attempt_num      |character |attempt number for that question                                                                                                               |
|selected_option_index |character |index of selected quiz option                                                                                                                  |
|selected_option_text  |character |text of selected quiz option                                                                                                                   |
|correct               |character |whether the selection was correct                                                                                                              |

## phq9_results.csv

### Numeric columns

|column            | n_missing|   min|       mean|    max|
|:-----------------|---------:|-----:|----------:|------:|
|attn_check_score  |         0|     0|      0.000|      0|
|phq9_1_score      |         0|     0|      0.429|      1|
|phq9_2_score      |         0|     0|      0.190|      1|
|phq9_3_score      |         0|     0|      0.571|      3|
|phq9_4_score      |         0|     0|      0.905|      3|
|phq9_5_score      |         0|     0|      0.476|      3|
|phq9_6_score      |         0|     0|      0.333|      3|
|phq9_7_score      |         0|     0|      0.524|      2|
|phq9_8_score      |         0|     0|      0.143|      1|
|phq9_9_score      |         0|     0|      0.000|      0|
|rt                |         0| 12724|  89987.810| 446066|
|time_elapsed      |         0| 25338| 165376.952| 662638|
|time_to_submit_ms |         0| 12724|  89987.714| 446066|

### Categorical columns

|column              | n_missing| n_levels|labels                                                                                                                                                     |
|:-------------------|---------:|--------:|:----------------------------------------------------------------------------------------------------------------------------------------------------------|
|attn_check_label    |         0|        1|Not at all                                                                                                                                                 |
|participant_id      |         0|       21|3f5vbx91, 3qxfazs6, 3ry0dap0, 53povv20, 6eo527ny, 7xp8qfx3                                                                                                 |
|phq9_1_label        |         0|        2|Not at all, Several days                                                                                                                                   |
|phq9_2_label        |         0|        2|Not at all, Several days                                                                                                                                   |
|phq9_3_label        |         0|        4|More than half the days, Nearly every day, Not at all, Several days                                                                                        |
|phq9_4_label        |         0|        4|More than half the days, Nearly every day, Not at all, Several days                                                                                        |
|phq9_5_label        |         0|        4|More than half the days, Nearly every day, Not at all, Several days                                                                                        |
|phq9_6_label        |         0|        3|Nearly every day, Not at all, Several days                                                                                                                 |
|phq9_7_label        |         0|        3|More than half the days, Not at all, Several days                                                                                                          |
|phq9_8_label        |         0|        2|Not at all, Several days                                                                                                                                   |
|phq9_9_label        |         0|        1|Not at all                                                                                                                                                 |
|prolific_pid        |         0|       11|5d50692435e3af0001f05a15, 66b588a4b3e0e55fc74390b3, 67798278a28708e32bf4b451, 6946d43d6e37a8ebea7882bd, 69d60b821c7fcd0fae5faf58, 69f0b7ddbaaead7656414805 |
|prolific_session_id |        10|        2|6a96f18711f6c59dbfa56297, session_2                                                                                                                        |
|prolific_study_id   |         0|        4|6a96e8fee3cbae0da7c30ed0, 6a96ec018af1fd9a814e0d52, 6a9bed0e3ac0cdf0edd1e9fa, 6a9bedb67096b6da58724573                                                     |
|session             |         1|       20|0hzfuf6x, 36hov9oz, 4gjf86qo, 6h4275tf, 7l63l3ep, 953ytv0u                                                                                                 |
|study_session       |         0|        2|session_1, session_2                                                                                                                                       |

### Data dictionary

|column                      |class     |meaning                                                                                                                                        |
|:---------------------------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------------|
|participant_id              |character |jsPsych-generated per-session code (not stable across sessions; do not use as participant key)                                                 |
|session                     |character |jsPsych session code                                                                                                                           |
|prolific_pid                |factor    |Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference. |
|prolific_study_id           |character |Prolific study ID                                                                                                                              |
|prolific_session_id         |character |Prolific session ID (renamed from session_id in second_wave)                                                                                   |
|rt                          |numeric   |jsPsych's built-in RT for the PHQ9 form, ms                                                                                                    |
|study_session               |factor    |session_1 = first_wave, session_2 = second_wave. Levels: session_1 (reference), session_2.                                                     |
|phq9_1_score...phq9_9_score |numeric   |PHQ9 item scores, items 1-9                                                                                                                    |
|phq9_1_label...phq9_9_label |character |PHQ9 item response labels, items 1-9                                                                                                           |
|attn_check_score            |numeric   |attention check item score                                                                                                                     |
|attn_check_label            |character |attention check response label                                                                                                                 |
|time_to_submit_ms           |numeric   |time to submit the PHQ9 form, ms                                                                                                               |

## feedback.csv

### Numeric columns

|column | n_missing| min| mean| max|
|:------|---------:|---:|----:|---:|

### Categorical columns

|column                  | n_missing| n_levels|labels                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
|:-----------------------|---------:|--------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|feedback_text_response  |         0|       15|, Everything was clear and easy to follow., Interesting study, makes me think I have a good like, as i rarely have any problems , Interesting survey, as i said on the previous survey, I have a good life and very little bothers me, i do eat too much though, It went smoothly, no problems thanks!, Many of those feelings may have been very brief and short-lived, and not really significant.  If I have to choose one or the other it may suggest more of a problem than it actually is.  But thanks anyway! Have a good weekend.                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|prolific_pid            |         0|       11|5d50692435e3af0001f05a15, 66b588a4b3e0e55fc74390b3, 67798278a28708e32bf4b451, 6946d43d6e37a8ebea7882bd, 69d60b821c7fcd0fae5faf58, 69f0b7ddbaaead7656414805                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
|study_session           |         0|        2|session_1, session_2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
|task_understanding_text |         0|       21|choose what affected me most or select neither if i wasn't affected, choose which applies more, choose which effected you in the last 2 weeks, Compare which of two problems presented have bothered me the most in the past two weeks., I'll be shown pairs of common problems people face in their daily lives, and I have to choose which of the two has bothered me the most during the last two weeks; if neither one has bothered me at all, I can also choose the option that says that "Neither have bothered me" as well. There's not going to be any time limit, so I can take as long as I need to be able to reflect on the last two weeks regarding these different problems. There are 106 pairs in total, which will be separated into four parts for me to complete, so I can take breaks in between if needed too., I need to choose between 2 options, the one which has affected me the most over the last 2 weeks.  Try to choose neither option only as a last resort. |

### Data dictionary

|column                  |class     |meaning                                                                                                                                        |
|:-----------------------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------------|
|prolific_pid            |factor    |Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference. |
|study_session           |factor    |session_1 = first_wave, session_2 = second_wave. Levels: session_1 (reference), session_2.                                                     |
|task_understanding_text |character |parsed free-text task-understanding response (asked before the quiz)                                                                           |
|feedback_text_response  |character |parsed free-text end-of-study feedback (how the participant felt during the experiment)                                                        |

## demographics.csv

Excludes participants with Prolific `Status == "RETURNED"` and drops the
`Completion code` column.

### Numeric columns

|column | n_missing| min| mean| max|
|:------|---------:|---:|----:|---:|

### Categorical columns

|column                        | n_missing| n_levels|labels                                                                                                                                                                       |
|:-----------------------------|---------:|--------:|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|Age                           |         0|        9|22, 23, 28, 35, 37, 41                                                                                                                                                       |
|Archived at                   |         0|       11|2026-09-01T15:55:30.265681Z, 2026-09-05T11:05:49.066070Z, 2026-09-05T11:13:05.361574Z, 2026-09-05T11:16:44.030787Z, 2026-09-05T11:17:52.788780Z, 2026-09-05T11:18:00.005326Z |
|Authenticity check: Bots      |         1|        1|N/A                                                                                                                                                                          |
|Completed at                  |         0|       11|2026-09-01T15:55:29.698000Z, 2026-09-05T11:05:48.664000Z, 2026-09-05T11:13:05.004000Z, 2026-09-05T11:16:43.692000Z, 2026-09-05T11:17:52.461000Z, 2026-09-05T11:17:59.651000Z |
|Country of birth              |         0|        3|Nigeria, United Kingdom, United States                                                                                                                                       |
|Country of residence          |         0|        4|Canada, South Africa, United Kingdom, United States                                                                                                                          |
|Custom study tncs accepted at |         0|        1|Not Applicable                                                                                                                                                               |
|Employment status             |         0|        5|Full-Time, Not in paid work (e.g. homemaker', 'retired or disabled), Other, Part-Time, Unemployed (and job seeking)                                                          |
|Ethnicity simplified          |         0|        2|Black, White                                                                                                                                                                 |
|Language                      |         0|        1|English                                                                                                                                                                      |
|Nationality                   |         0|        4|Canada, South Africa, United Kingdom, United States                                                                                                                          |
|Participant id                |         0|       11|5d50692435e3af0001f05a15, 66b588a4b3e0e55fc74390b3, 67798278a28708e32bf4b451, 6946d43d6e37a8ebea7882bd, 69d60b821c7fcd0fae5faf58, 69f0b7ddbaaead7656414805                   |
|Reviewed at                   |         0|       11|2026-09-03T06:54:55.337000Z, 2026-09-06T07:45:53.942000Z, 2026-09-06T07:45:54.301000Z, 2026-09-06T07:45:54.665000Z, 2026-09-06T07:45:55.032000Z, 2026-09-06T07:45:55.397000Z |
|Sex                           |         0|        2|Female, Male                                                                                                                                                                 |
|Started at                    |         0|       11|2026-09-01T15:38:54.209000Z, 2026-09-05T10:50:06.091000Z, 2026-09-05T10:50:07.085000Z, 2026-09-05T10:50:14.216000Z, 2026-09-05T10:50:21.884000Z, 2026-09-05T10:51:03.144000Z |
|Status                        |         0|        1|APPROVED                                                                                                                                                                     |
|Student status                |         0|        2|No, Yes                                                                                                                                                                      |
|Submission id                 |         0|       11|6a96f18711f6c59dbfa56297, 6a9bf3d2a734de9552ddc233, 6a9bf3d5dd4fb9775003ae99, 6a9bf3d8d2dbba6390a21933, 6a9bf3e0d626794f460066ee, 6a9bf3e8e54c56f38fe9922f                   |
|Time taken                    |         0|       11|1042, 1322, 1503, 1580, 1582, 1666                                                                                                                                           |
|Total approvals               |         0|       11|1318, 132, 151, 1767, 1955, 2406                                                                                                                                             |

### Data dictionary

|column                        |class     |meaning                                                                                                                             |
|:-----------------------------|:---------|:-----------------------------------------------------------------------------------------------------------------------------------|
|Submission id                 |character |Prolific submission identifier                                                                                                      |
|Participant id                |factor    |Prolific participant ID, matches prolific_pid in the other raw CSVs. Levels = Prolific IDs present in the data, no fixed reference. |
|Status                        |character |Prolific submission status. RETURNED participants have already been excluded from this file.                                        |
|Custom study tncs accepted at |character |timestamp the study terms were accepted                                                                                             |
|Started at                    |character |timestamp the Prolific submission started                                                                                           |
|Completed at                  |character |timestamp the Prolific submission completed                                                                                         |
|Reviewed at                   |character |timestamp the submission was reviewed                                                                                               |
|Archived at                   |character |timestamp the submission was archived                                                                                               |
|Time taken                    |numeric   |total time taken on Prolific, seconds                                                                                               |
|Total approvals               |numeric   |participant's total prior approvals on Prolific                                                                                     |
|Age                           |numeric   |self-reported age                                                                                                                   |
|Sex                           |character |self-reported sex                                                                                                                   |
|Ethnicity simplified          |character |self-reported ethnicity                                                                                                             |
|Country of birth              |character |self-reported country of birth                                                                                                      |
|Country of residence          |character |self-reported country of residence                                                                                                  |
|Nationality                   |character |self-reported nationality                                                                                                           |
|Language                      |character |self-reported first language                                                                                                        |
|Student status                |character |self-reported student status                                                                                                        |
|Employment status             |character |self-reported employment status                                                                                                     |
|Authenticity check: Bots      |character |Prolific bot-authenticity check result                                                                                              |
