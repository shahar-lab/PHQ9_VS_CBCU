# Raw-data exclusion review

This is a review-only report. Participant criteria are evaluated first;
trial criteria are then evaluated only among participants who survive
participant screening. No raw or processed dataset is altered.

## Criteria

1. Retain participants only when both time1 and time2 contain exactly 105 CBCU pairwise trials and all 9 PHQ responses.
2. Among those participants, exclude a participant if active-task window departures total more than 30 seconds in either session. Scheduled `phase2_break` rows do not count.
3. Among surviving participants, flag a CBCU trial when `window_status` is `left` on its preceding same-numbered pairwise ITI row or response row.

## Sequential participant removals

|criterion                                                                        | n_omitted| n_remaining| pct_omitted|
|:--------------------------------------------------------------------------------|---------:|-----------:|-----------:|
|Starting point (all raw participants)                                            |          |          11|            |
|Exactly 105 CBCU pairwise trials and all 9 PHQ responses at both time1 and time2 |         1|          10|         9.1|
|Active-task window time at or below 30 seconds in each session                   |         0|          10|         0.0|

## Excluded participant IDs and reasons

|Prolific ID              |Reason                                                             |
|:------------------------|:------------------------------------------------------------------|
|6a0b57dda1f2bbc0f2c1398b |Incomplete required data: time2 (0 CBCU trials; 0/9 PHQ responses) |

## Sequential trial removals

|criterion                                                                           | n_omitted| n_remaining| pct_omitted|
|:-----------------------------------------------------------------------------------|---------:|-----------:|-----------:|
|Starting point (after participant screening)                                        |          |        2100|            |
|Window left on the preceding same-numbered pairwise ITI or on the pairwise response |         1|        2099|           0|

## Excluded trial identifiers and reasons

|Prolific ID              |Time  | CBCU trial|Reason                           |
|:------------------------|:-----|----------:|:--------------------------------|
|6946d43d6e37a8ebea7882bd |time2 |         79|Window left on pairwise response |

**Review result: 10 participants and 2099 CBCU trials remain after applying the review criteria.**
