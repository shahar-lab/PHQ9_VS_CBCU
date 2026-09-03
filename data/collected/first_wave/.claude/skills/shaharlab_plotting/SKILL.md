# shaharlab_plotting Skill: Routing & Decisions

This file answers: "Which reference should I read for this plot request?"

**Reading order matters. Follow this flow.**

---

## STEP 1: Identify the Plot Type

What did the user ask for?

Refer to `references/PLOT_TYPES.md` for the decision tree, or use these keywords:

| Request | Plot Type | Read Next |
|---------|-----------|-----------|
| "Plot the posterior" / "Show credible intervals" / "Effect estimate" | posterior | `references/plot-posterior/instructions.md` |
| "Scatter plot" / "x vs y" / "parameter recovery" | scatter | `references/plot-scatter/instructions.md` |
| Multiple plots assembled together | multi-panel | `references/EXPORT_STANDARD.md` + `references/PANEL_TAGGING_STANDARD.md` |
| "Use colors" / "colorblind palette" | color rules | `references/COLOR_STANDARD.md` |

---

## STEP 2: Check the Assumptions

This skill is standalone: it knows plotting code, nothing about projects or folders. It assumes the caller provides:

- A variable `output_dir` (an existing directory) — all `ggsave()` calls target `file.path(output_dir, ...)`
- Libraries loaded: `ggplot2`, `ggdist`, `patchwork`, `tidyverse`
- Data/draws already in scope — plotting is never the data-generation step

If any assumption is unmet, stop and tell the caller what is missing. Do not create directories, load libraries, or invent paths.

---

## STEP 3: Read Plot-Type Specific Rules

### If posterior:
**Read:** `references/plot-posterior/instructions.md`
- Understand layout (wide, short, clean)
- Understand axes (x = parameter, no y-axis)
- Understand slab + interval separation
- Understand theme (no gridlines, minimal)
- Use the example in `references/plot-posterior/example.R` as your template

### If scatter:
**Read:** `references/plot-scatter/instructions.md`
- Understand equal axes requirement (coord_equal)
- Understand shared limits (both x and y from same range)
- Understand required layers (points + trend line + diagonal reference + Pearson r annotation)
- Understand theme
- Use the example in `references/plot-scatter/example.R` as your template

---

## STEP 4: Read Structural Rules (Apply to ALL Plots)

**Read (in parallel):**
- `CONFIG.md` — export defaults (width, height, dpi, format)
- `references/PANEL_TAGGING_STANDARD.md` — if your figure has 2+ panels
- `references/COLOR_STANDARD.md` — if your plot uses color

---

## STEP 5: Write Your Code

Use the plot-type example as your template. Apply color rules if needed. Prepare for dual export (PDF + PNG).

---

## STEP 6: Export & Verify

**Read:** `references/EXPORT_STANDARD.md`

- Save both .pdf and .png
- Use `file.path(output_dir, ...)` for all ggsave() calls
- Apply default width/height unless user requests otherwise
- Verify both files exist in output_dir/

---

## What This Skill Does NOT Cover

- **Folder structure & paths** — the caller defines `output_dir` (see STEP 2)
- **Library loading** — the caller loads libraries before plot code runs
- **Data preparation** — assume data is ready and in scope
- **Directory creation** — never create `output_dir` yourself; it must already exist

---

## Quick Reference

| Task | Read This |
|------|-----------|
| How do I plot a posterior? | `references/plot-posterior/instructions.md` |
| How do I plot a scatter? | `references/plot-scatter/instructions.md` |
| What colors should I use? | `references/COLOR_STANDARD.md` |
| How do I tag multi-panel figures? | `references/PANEL_TAGGING_STANDARD.md` |
| What are the export defaults? | `references/EXPORT_STANDARD.md` |
| What must be true in my parent script? | SKILL.md STEP 2 (assumptions) |
| What are the non-negotiable rules? | `CONFIG.md` |
| Which plot type should I use? | `references/PLOT_TYPES.md` |

---

## Example Workflow: Plot Multiple Posteriors

1. User: "Plot the posteriors for Group A and Group B side-by-side"
2. Agent reads SKILL.md: "posterior plot, but TWO distributions → need colors"
3. Agent checks STEP 2 assumptions: ✓ output_dir, libraries, draws in scope
4. Agent reads `references/plot-posterior/instructions.md`: "Multiple posteriors rule: use colors, alpha = 0.50, legend required"
5. Agent reads `references/COLOR_STANDARD.md`: Choose Okabe-Ito palette
6. Agent reads `references/EXPORT_STANDARD.md`: "Both PDF and PNG, width = 10, height = 8, dpi = 300"
7. Agent writes code using example.R as template + color rules
8. Agent exports: `ggsave(..., .pdf)` and `ggsave(..., .png)`
9. Agent verifies both files exist in output_dir/

Done.
