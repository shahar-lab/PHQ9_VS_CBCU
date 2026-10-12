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
* **Transitivity:** a cycle is three items with A over B, B over C and C over A. Per participant-session: number of triples with all three pairs decided, number of cyclic triples, cycle rate, and Kendall's coefficient of consistence `1 - cycle_rate / max_cycle_rate` (max rate for 15 items = 140 / 455). ASSUMED: the coefficient is applied to decided triples when skips leave the tournament incomplete.
* **Consistency (model-free noise):** the minimum number of choices that contradict any single ranking of the 15 items (exact, by dynamic programming over subsets), divided by the number of decided trials. Which optimal ranking is picked does not change this share, so no tie-break is needed.
* **Reference:** every statistic is also computed for the 20 human participant-sessions. A participant who skipped (almost) every trial has too few decided triples for stable rates (e.g. one participant skipped all trials and gets NaN).

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
