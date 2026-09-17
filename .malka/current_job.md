Plan Card

JOB
Add a two-panel raw CBCU RT cutoff-count figure
FOLDER
preprocessing/ (repair)

Job Card

JOB
Add a two-panel raw CBCU RT cutoff-count figure

FOLDER
preprocessing/ (repair)

ROUTED READS
- 02-analysis/visualization/standards/PANEL_TAGGING_STANDARD.md
- 02-analysis/visualization/standards/EXPORT_STANDARD.md

CHECKS

SPECIFICATION
- Use CBCU trials only, from the raw cbcu_results object already built by the preprocessing pipeline.
- Exclude trials with missing RT from all counts.
- Panel A uses lower RT limits from 0 through 1000 milliseconds in steps of 50 milliseconds and plots the cumulative number of trials with RT less than or equal to each limit.
- Panel B uses upper RT limits from 5 through 10 seconds in steps of 1 second and plots the cumulative number of trials with RT greater than or equal to each limit.
- The y-axis in both panels is the number of CBCU trials.
- Combine the panels into one figure with panel tags.
- Export the combined figure to preprocessing/output/raw_outputs/ as both PDF and PNG.
- Add a separate numbered script under preprocessing/code/ and source it from preprocessing/main.R after the existing raw CBCU figure scripts.
- Do not modify the raw or processed datasets.
