# Skill: Data Preprocessing & Validation

**🛑 MANDATORY WORKFLOW — Two-pass system (build, then review) for pristine data preparation.**

## When to Invoke
Use this skill automatically when the user requests help with:
* Data cleaning and preprocessing
* Variable type validation and correction
* Data exploration and structure verification
* Filtering and subsetting workflows
* **Triggers:** "preprocess", "clean data", "prepare data", "filter data", "check data structure", "variable types", "data validation"

## The Two Passes

### Build pass (Code Architect)
Designs and writes the preprocessing pipeline: reads titles and column names to infer intent, identifies variable classes and type mismatches, writes targeted R code, and ensures data is analysis-ready.

### Review pass (Code Reviewer)
Verifies correctness: reviews the pipeline line by line, checks for data loss, incorrect coercions, and filtering errors, validates that variable classes match the intended analysis, and requires corrections until clean.

## Workflow Gate (CRITICAL)

You MUST follow this sequence:

1. ✅ **Understand the raw data** — read titles, examine structure, identify variable types (`workflow/EXPLORATION.md`)
2. ✅ **Preprocessing plan** — propose filtering logic, type conversions, transformations; **user approves the plan before code is written**
3. ✅ **Write the pipeline** — per `workflow/ARCHITECT-INSTRUCTIONS.md`
4. ✅ **Review** — per `workflow/REVIEW-INSTRUCTIONS.md`; on issues, revise and re-review
5. ✅ **Final validation** — reviewer confirms data is clean and analysis-ready

## Where Outputs Go (Calling Context)

This skill knows how to preprocess, not where your project keeps things. The caller supplies the paths. In Shahar Lab projects, preprocessing code lives in the top-level `preprocessing/` folder and builds `data/raw/` and `data/processed/` from `data/collected/` — see `.claude/context/shaharlab_project_rules.md` and the `shaharlab_project_folder_scaffolding` skill.

## Quick Reference

| Task | Read This |
|------|-----------|
| How do I explore raw data? | `workflow/EXPLORATION.md` |
| How do I write preprocessing code? | `workflow/ARCHITECT-INSTRUCTIONS.md` |
| How do I review preprocessing? | `workflow/REVIEW-INSTRUCTIONS.md` |

## Example Workflow: Clean Survey Data

1. User: "I have survey data with missing values and mixed variable types. Can you clean it?"
2. Build pass reads EXPLORATION.md: examine raw data, identify issues
3. Build pass proposes plan: "Variable X should be factor, variable Y has 15% missing, filter rows where Z < 0" — user approves
4. Build pass writes the pipeline per ARCHITECT-INSTRUCTIONS.md
5. Review pass checks per REVIEW-INSTRUCTIONS.md: ✓ type coercions valid? ✓ filtering logic sound? ✓ data loss acceptable?
6. Issues found → revise → re-review, until: ✅ data is clean and analysis-ready