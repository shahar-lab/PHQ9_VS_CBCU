# ICC Sample-Size Panel

## What this is

A 3-panel composite figure comparing ICC / subject-ICC sample-size sweep
results across two prior, already-completed simulation studies:

- `simulation/sigmas_simulation_reliability_difference_sample_size/`
- `simulation/reliability_sample_size_subject_item_crossed/`

This folder produces no new simulation. It exists solely to place plots
from those two studies side by side in a single figure for direct visual
comparison.

## Read-only with respect to source folders

This folder is **read-only** with respect to the two source folders above.
It does not modify, re-run, or otherwise touch either source folder's code,
`main.R`, `artifacts/`, or `output/`. It only reads their already-saved
`sweep_results*.rds` artifacts and replots the data using the exact same
plotting code (same `pivot_longer`/`credible_level` factor construction,
same `#4477AA`/`#CCBB44`/`#EE6677` palette, same `geom_line`/`geom_point`,
same `theme_minimal(base_size = 13)` + custom theme tweaks, same axis
labels) that already produces each panel's standalone plot in its own
source folder.

## Source artifacts read

- `simulation/sigmas_simulation_reliability_difference_sample_size/artifacts/sweep_results.rds` -> Panel A
- `simulation/reliability_sample_size_subject_item_crossed/artifacts/sweep_results_phq9.rds` -> Panel B
- `simulation/reliability_sample_size_subject_item_crossed/artifacts/sweep_results_cbcu.rds` -> Panel C

## Panel order and content

- **Panel A** -- PHQ9 ICC HDI width by sample size, from the sigmas study
  (`sigmas_simulation_reliability_difference_sample_size`). Y-axis: "HDI
  width (PHQ9 ICC)". No panel title (matches source script, which sets no
  `title` in `labs()`).
- **Panel B** -- PHQ9 items subject-ICC HDI width by sample size, from the
  crossed study (`reliability_sample_size_subject_item_crossed`). Y-axis:
  "HDI width (subject ICC)". No panel title (removed at the user's request,
  so all 3 panels are title-free).
- **Panel C** -- CBCU utilities subject-ICC HDI width by sample size, from
  the same crossed study. Y-axis: "HDI width (subject ICC)". No panel title.

Panels are assembled in one row with patchwork's `|` operator only
(`p_a | p_b | p_c`), tagged A/B/C per `PANEL_TAGGING_STANDARD.md` (bold,
14pt, top-left of each panel).

## Export size rationale

`EXPORT_STANDARD.md`'s default single-plot export size (10x8in) is deviated
from deliberately: this is a 3-panel side-by-side composite, so a wider
canvas (20in wide x 7in tall) is used instead, to keep each panel's axes,
legend, and title legible rather than compressing three plots into a
10in-wide figure. PNG is still exported at 300dpi with a white background,
and both PDF and PNG are produced, per the standard's other requirements.

## Output

- `output/icc_sample_size_panel.pdf`
- `output/icc_sample_size_panel.png`
