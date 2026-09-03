# Shahar Lab Project Folder Structure — Single Source of Truth

```text
Project_Root/
├── data/
│   ├── collected/               (untouched data, exactly "as is" — not shared publicly)
│   ├── raw/                     (collected minus empty/irrelevant columns and non-real
│   │                             observations, e.g. researcher test runs; no exclusion of
│   │                             real observations — shared publicly)
│   └── processed/               (raw after observation exclusions, as reported in the manuscript)
│
├── preprocessing/               (code that builds raw/ and processed/ from collected/)
│   ├── code/                    (unnumbered R scripts)
│   └── main.R                   (main execution orchestrator script)
│
├── models/                      (reusable computational/statistical model definitions)
│   └── [MODEL_NAME]/            (one folder per model)
│       ├── [MODEL_NAME].R       (e.g., generating code)
│       └── [MODEL_NAME].stan    (Stan model code for fitting)
│
├── analysis/                    (empirical analyses)
│   └── [ANALYSIS_NAME]/         (one folder per analysis — canonical set, see below)
│
└── simulation/                  (simulation studies that validate models,
    └── [ANALYSIS_NAME]/          e.g. param_recovery, model_sim — canonical set, see below)
```

## The Canonical Set (identical for `analysis/` and `simulation/` folders)

Every `analysis/[ANALYSIS_NAME]/` and `simulation/[ANALYSIS_NAME]/` folder contains exactly:

| Item | Purpose |
|---|---|
| `code/` | Short, targeted, **unnumbered** R scripts |
| `artifacts/` | Machine-readable derived files: fitted models, `.rds` files, data frames |
| `output/` | Human-facing outputs: plots, figures, tables |
| `main.R` | Main execution orchestrator script (top-to-bottom source of truth) |
| `summary.md` | Analysis documentation/notebook: metadata, hypotheses, findings |

## Data Stage Semantics

| Folder | Purpose |
|---|---|
| `data/collected/` | Data exactly "as is", untouched — **not shared publicly** |
| `data/raw/` | Collected data with empty/irrelevant columns and non-real observations (e.g. researcher test runs) removed; no exclusion of real observations — **shared publicly** |
| `data/processed/` | Raw data after exclusion of observations, as reported in the manuscript |

Analyses read from `data/processed/` by default; the user may direct an analysis to another stage (e.g. `data/raw/`) when pre-exclusion data is needed.