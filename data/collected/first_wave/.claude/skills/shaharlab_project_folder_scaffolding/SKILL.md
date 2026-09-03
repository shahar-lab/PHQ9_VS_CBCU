# Skill: Shahar Lab Project Folder Scaffolding

**Mandate:** You are the infrastructure manager for the Shahar Lab. Strictly enforce our modular "one model, one folder" topology. Do not hallucinate folder structures — the single source of truth is `references/folder_structure.md` plus `.claude/context/shaharlab_project_rules.md`.

## 🎯 When to Invoke
Use this skill automatically when the user requests help with:
* Opening a new analysis, simulation, model, or preprocessing folder
* Organizing project files and directories, or auditing/repairing the folder structure
* Duplicating or cloning an existing analysis/simulation folder
* **Triggers:** "new analysis folder", "new simulation folder", "open a new folder", "create analysis directory", "project structure", "scaffold this project", "clone this analysis"

## 🗂️ Folder-Type Routing

First determine WHAT is being scaffolded, then follow the matching blueprint:

| Request | Location | Blueprint | Templates |
|---|---|---|---|
| New analysis | `analysis/[NAME]/` | `references/new_folder.md` (canonical set) | `assets/template_main.R`, `assets/template_summary.md` |
| New simulation study | `simulation/[NAME]/` | `references/new_folder.md` (canonical set — identical to analysis, different parent) | same as analysis |
| New model definition | `models/[MODEL_NAME]/` | `references/new_folder.md` (model layout) | `assets/template_model.R`, `assets/template_model.stan` |
| Preprocessing setup | `preprocessing/` | `references/new_folder.md` (preprocessing layout) | `assets/template_main.R` (adapted) |
| Duplicate/clone a folder | same parent as source | `references/smart_clone.md` | — |

## 🚦 Gated Workflow (for non-trivial requests: audits, reorganizations, clones, multi-folder builds)

Each blocking gate must clear before the next step:

1. **Inspect** — read the actual directory tree (`data/`, `preprocessing/`, `models/`, each `analysis/` and `simulation/` folder). Diff it against `references/folder_structure.md` and project_rules; flag every deviation and name the rule it breaks.
2. **Interview** — LOOP until intent is unambiguous: folder type? new/clone/repair? if clone: source folder + new name? model name / regression formula for headers? data source (default `data/processed/`)? Do NOT proceed while uncertain.
3. **Plan** — write an ordered operations plan where every operation cites the rule it satisfies (e.g. `[satisfies: §2.II no numbering]`). For clones, the plan MUST include: copy `code/` + `main.R` + `summary.md`, WIPE `artifacts/` + `output/`, RE-POINT the path variables to the new folder name.
4. **Reviewer gate — Phase A** — review the PLAN per `workflow/REVIEWER.md` (run as a subagent when possible, for independence). On fail: revise the plan and resubmit. [blocking]
5. **USER approval gate** — present the reviewed plan; the user must approve before any disk mutation. [blocking]
6. **Execute** — perform the approved plan EXACTLY, in order. Inject templates from `assets/`, replacing `<parent>` (analysis or simulation) and `<folder_name>` placeholders with the real values. Do not add folders, skip steps, or improvise. Path syntax is governed by `.claude/hooks/shaharlab-pre_path_enforcement.md` / `shaharlab-post_path_enforcement.md`.
7. **Reviewer gate — Phase B** — verify the RESULT on disk per `workflow/REVIEWER.md`. On fail: fix and re-verify. Loop until approved. [blocking]

**Trivial shortcut:** a single new canonical folder (no audit, no reorg, no clone) may skip the reviewer gates and use the Direct Scaffolding sequence below — but the user still names the folder and provides the model/formula.

## 🏗️ Direct Scaffolding (trivial one-folder creates)

1. **Consult the blueprint:** `references/new_folder.md` (or `references/smart_clone.md` for duplication).
2. **Create the topology** for the requested folder type per the routing table above.
3. **Inject boilerplates** from `assets/` (e.g. `template_main.R` → `main.R`, `template_summary.md` → `summary.md`).
4. **Parameterize & interview:**
   * Ask for the regression formula (e.g. `y ~ x + (1|subject)`) or model name; update the headers of the new `main.R` and `summary.md`.
   * Replace `<parent>` with the actual parent (`analysis` or `simulation`) and `<folder_name>` with the actual folder name so all `file.path()` constructions are correct.
   * Confirm the data source — default `data/processed/` — and set the read path accordingly.