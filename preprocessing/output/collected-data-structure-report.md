# Collected data structure report

Built by `preprocessing/code/describe_collected.R`. Describes the data exactly as it
arrived in `data/collected/`, before any restructuring into `data/raw/`.

## Rows

|metric                                                                | value|
|:---------------------------------------------------------------------|-----:|
|Rows collected                                                        |  5106|
|Rows that are trial/response data                                     |  4602|
|Rows that are housekeeping (instructions, breaks, fullscreen prompts) |   504|
|Participants                                                          |    11|
|Sessions (session_1)                                                  |    11|
|Sessions (session_2)                                                  |    10|

## Per participant (sorted to surface incomplete cases first)

|prolific_pid             |study_session | n_pairwise_trials| n_quiz_questions|phq9_completed |feedback_completed |
|:------------------------|:-------------|-----------------:|----------------:|:--------------|:------------------|
|5d50692435e3af0001f05a15 |session_1     |               105|                6|TRUE           |TRUE               |
|5d50692435e3af0001f05a15 |session_2     |               105|                6|TRUE           |TRUE               |
|66b588a4b3e0e55fc74390b3 |session_1     |               105|                6|TRUE           |TRUE               |
|66b588a4b3e0e55fc74390b3 |session_2     |               105|                6|TRUE           |TRUE               |
|67798278a28708e32bf4b451 |session_1     |               105|                6|TRUE           |TRUE               |
|6946d43d6e37a8ebea7882bd |session_1     |               105|                6|TRUE           |TRUE               |
|69d60b821c7fcd0fae5faf58 |session_1     |               105|                6|TRUE           |TRUE               |
|69d60b821c7fcd0fae5faf58 |session_2     |               105|                6|TRUE           |TRUE               |
|69f0b7ddbaaead7656414805 |session_1     |               105|                6|TRUE           |TRUE               |
|69f0b7ddbaaead7656414805 |session_2     |               105|                6|TRUE           |TRUE               |
|6a0b57dda1f2bbc0f2c1398b |session_1     |               105|                6|TRUE           |TRUE               |
|6a0c5f6a4974d3dfbeb467ae |session_1     |               105|                6|TRUE           |TRUE               |
|6a0c5f6a4974d3dfbeb467ae |session_2     |               105|                6|TRUE           |TRUE               |
|6a241cc77b290774b3626f62 |session_2     |               105|                6|TRUE           |TRUE               |
|6a25badf2f95439c4b79d399 |session_1     |               105|                6|TRUE           |TRUE               |
|6a25badf2f95439c4b79d399 |session_2     |               105|                6|TRUE           |TRUE               |
|6a26623dba3ca97e10bd6e4a |session_1     |               105|                6|TRUE           |TRUE               |
|6a26623dba3ca97e10bd6e4a |session_2     |               105|                6|TRUE           |TRUE               |
|67798278a28708e32bf4b451 |session_2     |               105|                7|TRUE           |TRUE               |
|6946d43d6e37a8ebea7882bd |session_2     |               105|                7|TRUE           |TRUE               |
|6a241cc77b290774b3626f62 |session_1     |               105|                7|TRUE           |TRUE               |

## Prolific demographics export

|metric                         | value|
|:------------------------------|-----:|
|Submissions in Prolific export |    14|
|Status: APPROVED               |    11|
|Status: RETURNED               |     3|
