# Analysis Notebook: RT, Transitivity and Consistency of Claude's Session

**Model / formula:** none (descriptive; no fitted model, no thresholds, no flags)
**Date Created:** 2026-10-11

## 1. Hypotheses
* How does Claude's RT change with presentation order (trial 1-105), compared with human participants?
* Are Claude's pairwise choices transitive (if A is chosen over B and B over C, then A over C)?
* How consistent are Claude's choices, i.e. how well does one single item ranking explain them? Very high consistency, compared with humans, can serve as a possible AI indication.
* The Bradley-Terry model is not fitted: with one session of 105 pairs over 15 items, beta and the utilities are poorly identified without the group level.

## 2. Variables
* **Data (exception, approved by the researcher):** Claude's raw session CSVs `PHQ9_pairwise_*.csv` are read directly from this folder, bypassing preprocessing. Each file is one Claude run (run 1 = 2026-10-09, run 2 = 2026-10-12, ordered by file name); a new CSV added to the folder becomes the next run when `main.R` is rerun. The human reference is `data/processed/cbcu.csv` (10 participants x 2 sessions x 105 trials, already cleaned by preprocessing).
* **Cleaning of each Claude file:** only the 105 choice rows are kept (`trial_type == "html-button-response"`, `phase == "pairwise"`). Dropped: 105 ITI rows, instruction, quiz, break, PHQ-9, free-text, feedback, fullscreen and session-start rows. Checks that stop the script if they fail: exactly 105 rows, trial order 1-105 without duplicates, no repeated pair, no missing RT, `window_status` "ok" on every row, choice values valid, skip matches `skipped`, chosen item matches the chosen side.
* **RT:** `rt_from_stim_ms` (Claude) and `rt` (humans), in ms. No RT outliers removed; the plot axis is capped at 15,000 ms and the trials above it are counted and printed (Claude 0, humans 87).
* **Items:** the 15 PHQ-9 sub-item labels (`1`, `2a`, ..., `9b`) in both datasets.
* **Skip trials:** kept in the RT plot (hollow points), ignored for transitivity and consistency; the skip rate is reported.
* **Columns of the table `output/05_transitivity_consistency.csv`** (one row per participant-session; skip trials are ignored for transitivity and consistency):
  * `unit`: one participant in one session. `Claude_run1`, `Claude_run2` are Claude's two sessions; `H01_time1` is human participant 1 in session 1.
  * `agent`: "Claude" or "Human".
  * `n_decided`: trials, out of 105, where an item was actually chosen (left or right, not skip).
  * `skip_rate`: share of the 105 trials answered with "neither bothered me" (skip).
  * `n_decided_triples`: a triple is a group of three items (A, B, C). With 15 items there are 455 (15 x 14 x 13 = 2,730 ordered ways, divided by 6 because the order does not matter). A triple can only be checked if all three of its pairs (A vs B, B vs C, A vs C) were decided; this is how many could be checked.
  * `n_cyclic`: how many of those triples are circular: A chosen over B, B over C, but C over A. No single order of the three items explains these choices, so each one is a violation of transitivity.
  * `cycle_rate`: `n_cyclic / n_decided_triples`, the share of the checkable triples that are circular. 0 = perfectly consistent (transitive); higher = more contradictions. Example: H06 in session 2 skipped nothing, 62 of 455 triples were circular, so 62 / 455 = 0.136. A random chooser is around 0.25. Skipped pairs shrink the denominator, so a participant with many skips is judged on few triples (e.g. about 12 for H03) and the value is less reliable.
  * `min_contradictions`: the fewest choices that go against the best single ranking of the 15 items (found exactly, by dynamic programming over subsets). 0 means one ranking explains every choice; a higher number means noisier choices (the model-free counterpart of beta). Example: H06 in session 2 has 13. NA when the participant made no decided choice.
* **Reference:** every statistic is also computed for the 20 human participant-sessions. `cycle_rate` and `min_contradictions` are NA for H08, who skipped every trial.

## 3. Outputs
* `output/05_transitivity_consistency.csv`: one row per participant-session (Claude and humans).
* `output/07_rt_distribution.{pdf,png}`: dot histograms of RT, one panel per Claude run (A, B) and one per human participant (C-L, both sessions pooled), same x-axis (0-15,000 ms, trials above the cap hidden and counted under each panel). ASSUMED: dots are drawn as exact circles with a true count axis instead of `geom_dots()`, because the installed ggdist (3.3.3) does not return bin ids from `ggplot_build()`, so the lab's count-axis recipe cannot be applied. The bin width (ms) is chosen per panel as the largest from 1000 to 100 ms whose tallest stack fits a square panel, and is printed under each panel.
* `output/08_report.pdf`: four-page report with the cleaning details (row types kept and dropped, checks passed, RT cap counts), the RT-by-trial figure, the RT distributions, and the transitivity and consistency table with the human range next to Claude.
* `output/06_rt_by_trial.{pdf,png}`: A: Claude, RT against trial with a LOESS line and band; B: humans, one thin LOESS line per session and a pooled line. Skipped trials are hollow points. Participants are labelled H01-H10, no Prolific IDs.

## 4. Findings / Summary
* (Leave blank until the output has been reviewed.)

## 5. Limitations
* One Claude session only: no test-retest, and the numbers describe one run.
* Human reference is 10 pilot participants; some skipped most trials, which makes their transitivity and consistency rates unstable.
* No mouse, keystroke or paste data are recorded.
