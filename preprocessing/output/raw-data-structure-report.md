# Raw data structure report

Built by `preprocessing/code/build_raw.R`. Describes each of the four tidy CSVs written
to `data/raw/` after the collected long-format event log was restructured: column names,
classes, meanings, and categorical/factor coding, one section per output file.

## cbcu_results.csv

### Numeric columns

|column          | n_missing|    min|       mean|    max|
|:---------------|---------:|------:|----------:|------:|
|rt              |       210|    783|   3379.024|  35181|
|rt_from_stim_ms |       210|    783|   3379.024|  35181|
|stim_onset_ms   |       210| 120795| 494851.324| 881919|
|time_elapsed    |         0| 119833| 495403.271| 882345|

### Categorical columns

|column              | n_missing| n_levels|labels                                                                                                                                                                                                                                                                                |
|:-------------------|---------:|--------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|chosen_item_number  |       253|       11|1, 2a, 2b, 3a, 3b, 4                                                                                                                                                                                                                                                                  |
|chosen_item_text    |       253|       11|Feeling bad about yourself or that you are a failure, Feeling down or depressed, Feeling hopeless, Feeling that you have let yourself or your family down, Feeling tired or having little energy, Little interest or pleasure in doing things                                         |
|chosen_side         |       210|        3|left, right, skip                                                                                                                                                                                                                                                                     |
|left_item_number    |       210|       15|1, 2a, 2b, 3a, 3b, 4                                                                                                                                                                                                                                                                  |
|left_item_text      |       210|       15|Being so fidgety or restless that you have been moving around a lot more than usual, Feeling bad about yourself or that you are a failure, Feeling down or depressed, Feeling hopeless, Feeling that you have let yourself or your family down, Feeling tired or having little energy |
|participant_id      |         0|        2|d61wv60p, kqza4k6l                                                                                                                                                                                                                                                                    |
|phase               |         0|        2|iti, pairwise                                                                                                                                                                                                                                                                         |
|phase_trial_num     |         0|      105|1, 10, 100, 101, 102, 103                                                                                                                                                                                                                                                             |
|prolific_pid        |         0|        1|6a25badf2f95439c4b79d399                                                                                                                                                                                                                                                              |
|prolific_session_id |         0|        2|6a96f18711f6c59dbfa56297, session_2                                                                                                                                                                                                                                                   |
|prolific_study_id   |         0|        2|6a96e8fee3cbae0da7c30ed0, 6a96ec018af1fd9a814e0d52                                                                                                                                                                                                                                    |
|right_item_number   |       210|       15|1, 2a, 2b, 3a, 3b, 4                                                                                                                                                                                                                                                                  |
|right_item_text     |       210|       15|Being so fidgety or restless that you have been moving around a lot more than usual, Feeling bad about yourself or that you are a failure, Feeling down or depressed, Feeling hopeless, Feeling that you have let yourself or your family down, Feeling tired or having little energy |
|session             |         0|        2|36hov9oz, b6c1zcb4                                                                                                                                                                                                                                                                    |
|skipped             |       210|        2|false, true                                                                                                                                                                                                                                                                           |
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

|column       | n_missing|   min|     mean|    max|
|:------------|---------:|-----:|--------:|------:|
|rt           |         0|  4226|   8495.5|  19400|
|time_elapsed |         0| 81377| 181239.6| 295699|

### Categorical columns

|column                | n_missing| n_levels|labels                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
|:---------------------|---------:|--------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|correct               |         0|        1|true                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
|participant_id        |         0|        2|d61wv60p, kqza4k6l                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|prolific_pid          |         0|        1|6a25badf2f95439c4b79d399                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|prolific_session_id   |         0|        2|6a96f18711f6c59dbfa56297, session_2                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|prolific_study_id     |         0|        2|6a96e8fee3cbae0da7c30ed0, 6a96ec018af1fd9a814e0d52                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|quiz_attempt_num      |         0|        1|1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
|quiz_question_num     |         0|        6|1, 2, 3, 4, 5, 6                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|selected_option_index |         0|        4|0, 1, 2, 3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
|selected_option_text  |         0|        6|Click on the problem that bothered you more in the last two weeks., No, there is no time limit, so you should take your time to carefully reflect on each screen., Only when you are absolutely sure neither problem affected you at all in the last two weeks., Three breaks, giving you a chance to pause between the four parts of the task., Try your best to choose the one that bothered you slightly more., You must stay on this screen without switching to other tabs or windows. |
|session               |         0|        2|36hov9oz, b6c1zcb4                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|study_session         |         0|        2|session_1, session_2                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |

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

|column            | n_missing|   min|     mean|    max|
|:-----------------|---------:|-----:|--------:|------:|
|attn_check_score  |         0|     0|      0.0|      0|
|phq9_1_score      |         0|     1|      1.0|      1|
|phq9_2_score      |         0|     1|      1.0|      1|
|phq9_3_score      |         0|     1|      1.5|      2|
|phq9_4_score      |         0|     1|      1.5|      2|
|phq9_5_score      |         0|     0|      0.0|      0|
|phq9_6_score      |         0|     0|      0.0|      0|
|phq9_7_score      |         0|     1|      1.0|      1|
|phq9_8_score      |         0|     0|      0.0|      0|
|phq9_9_score      |         0|     0|      0.0|      0|
|rt                |         0| 35319|  43127.0|  50935|
|time_elapsed      |         0| 50763| 110486.5| 170210|
|time_to_submit_ms |         0| 35319|  43127.0|  50935|

### Categorical columns

|column              | n_missing| n_levels|labels                                             |
|:-------------------|---------:|--------:|:--------------------------------------------------|
|attn_check_label    |         0|        1|Not at all                                         |
|participant_id      |         0|        2|d61wv60p, kqza4k6l                                 |
|phq9_1_label        |         0|        1|Several days                                       |
|phq9_2_label        |         0|        1|Several days                                       |
|phq9_3_label        |         0|        2|More than half the days, Several days              |
|phq9_4_label        |         0|        2|More than half the days, Several days              |
|phq9_5_label        |         0|        1|Not at all                                         |
|phq9_6_label        |         0|        1|Not at all                                         |
|phq9_7_label        |         0|        1|Several days                                       |
|phq9_8_label        |         0|        1|Not at all                                         |
|phq9_9_label        |         0|        1|Not at all                                         |
|prolific_pid        |         0|        1|6a25badf2f95439c4b79d399                           |
|prolific_session_id |         0|        2|6a96f18711f6c59dbfa56297, session_2                |
|prolific_study_id   |         0|        2|6a96e8fee3cbae0da7c30ed0, 6a96ec018af1fd9a814e0d52 |
|session             |         0|        2|36hov9oz, b6c1zcb4                                 |
|study_session       |         0|        2|session_1, session_2                               |

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

|column                  | n_missing| n_levels|labels                                                                   |
|:-----------------------|---------:|--------:|:------------------------------------------------------------------------|
|feedback_text_response  |         0|        1|                                                                         |
|prolific_pid            |         0|        1|6a25badf2f95439c4b79d399                                                 |
|study_session           |         0|        2|session_1, session_2                                                     |
|task_understanding_text |         0|        2|choose which applies more, choose which effected you in the last 2 weeks |

### Data dictionary

|column                  |class     |meaning                                                                                                                                        |
|:-----------------------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------------|
|prolific_pid            |factor    |Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference. |
|study_session           |factor    |session_1 = first_wave, session_2 = second_wave. Levels: session_1 (reference), session_2.                                                     |
|task_understanding_text |character |parsed free-text task-understanding response (asked before the quiz)                                                                           |
|feedback_text_response  |character |parsed free-text end-of-study feedback (how the participant felt during the experiment)                                                        |
