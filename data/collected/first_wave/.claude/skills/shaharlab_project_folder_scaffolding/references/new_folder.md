# Blueprint: New Folder (all types)

Naming rules apply to every new folder:

* **Naming:** Prompt the user for a name if they didn't provide one. Use `snake_case` (e.g., `model_y_by_x_and_z`).
* **Warning:** No special characters, spaces, or formula notation (`~`, `+`, `|`) in folder names — these break path construction and shell commands.

## Analysis / Simulation folder (identical canonical set)

1. **Location:** `analysis/[NAME]/` for empirical analyses; `simulation/[NAME]/` for simulation studies (e.g. `param_recovery`, `model_sim`).
2. Create the canonical set: `code/`, `artifacts/`, `output/`, `main.R`, `summary.md` (project_rules §3).
3. Inject `assets/template_main.R` as `main.R` and `assets/template_summary.md` as `summary.md`, then parameterize: replace `<parent>` with `analysis` or `simulation`, `<folder_name>` with the actual name, and set headers to the user's model name / formula.

## Model folder

1. **Location:** `models/[MODEL_NAME]/` — one folder per model.
2. Create `[MODEL_NAME].R` (generating code) from `assets/template_model.R` and `[MODEL_NAME].stan` (Stan fitting code) from `assets/template_model.stan`. File names must match the folder name.
3. No `code/`, `artifacts/`, or `output/` here — fitting and evaluation live in `analysis/` or `simulation/` (project_rules §2.III).

## Preprocessing

1. **Location:** top-level `preprocessing/` (there is only one).
2. Create `code/` (unnumbered R scripts) and `main.R` (orchestrator, adapted from `assets/template_main.R`: paths point to `preprocessing/code` and the `data/` stages; it builds `data/raw/` and `data/processed/` from `data/collected/`).