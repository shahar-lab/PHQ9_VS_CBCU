# Lab rules for this project

<!-- Lab rules version: 3.0.0 -->
**Lab rules: 3.0.0** · Shahar-Lab, Tel Aviv University · refresh with the `project-setup` skill.

This file is the project's constitution. It is in context on every request, so it holds the
rules that apply to all work here and nothing that applies to only one kind of job. The craft —
how to write a preprocessing step, a brms fit, a figure — lives in the
`shaharlab-behavioral-data-analysis` plugin's skills, which load when they are needed.

Everything above **This project** is Shahar-Lab's and arrives with the plugin. **This project** is
yours.

---

## 1. Terms

| Term | Meaning |
|---|---|
| researcher | the person prompting you |
| main-folder | one of the five directories at the project root |
| job | one unit of work |
| job-folder | the directory that one job writes into |
| collected-data | the data exactly as the testing machine produced it |
| raw-data | a tidied version: real columns only, correct classes, proper `NA` |
| processed-data | raw-data after exclusions and calculated columns — what analyses read |
| reserved value | one of the decisions in section 4, which the researcher makes |

## 2. The five main folders

A project has these five top-level folders and no others.

```text
project_root/
├── data/
│   ├── collected/
│   ├── raw/
│   └── processed/
├── preprocessing/
├── models/
├── analysis/
└── simulation/
```

Read and write permissions are the point of this section. Keeping them is what keeps a
project's provenance intact.

| Folder | Who may read it | Who may write to it |
|---|---|---|
| `data/collected/` | `preprocessing/` only | nobody — it stays exactly as it arrived |
| `data/raw/` | `preprocessing/` only | `preprocessing/` only |
| `data/processed/` | anyone | `preprocessing/` only |
| `preprocessing/` | anyone, for its `output/` reports | the preprocessing job |
| `models/` | `analysis/`, `simulation/` | the researcher, or an approved job |
| `analysis/` | anyone, for its `output/` | its own job-folder |
| `simulation/` | anyone, for its `output/` | its own job-folder |

- `analysis/` reads real data from `data/processed/`.
- `simulation/` generates its own data and reads nothing from `data/`.
- `models/` holds model definitions only — the fitting and the evaluation live in the job-folder
  that calls them.

## 3. The job-folder

Every job writes into exactly one job-folder, shaped like this:

```text
[job-folder]/
├── code/        short numbered R scripts, one step each
├── artifacts/   machine-readable intermediates (.rds, .csv) — the researcher never opens these
├── output/      human-facing results: figures, tables, reports, manuscript excerpts
├── main.R       the orchestrator: setup, paths, then one source() per step
└── summary.md   the notebook: what was decided, and later what was found
```

- A `code/` script carries a two-digit prefix giving its position in `main.R`. Every file it
  writes to `output/` takes that same prefix. Inserting a step renumbers what follows, in the
  same edit.
- `preprocessing/` is the only job-folder with subfolders in `output/`:
  `reports-collected/`, `reports-raw/`, `reports-processed/`.
- `models/` job-folders are the one exception to this shape — they hold only the two model files.

### How many job-folders is the work?

| The job-folder produces | How many |
|---|---|
| a fitted model object (`brm()`, `stan()`, any saved fit) | **one job-folder per fit** |
| plots, tables, descriptives, data checks | **one job-folder for the coherent set** |

One formula fitted to three subsets is three fits, so three job-folders. A folder of five plot
scripts is one job-folder. A job that counts more than one fit for itself stops and says so.

This count is an `analysis/` rule. A `simulation/` study holds as many fits as its design needs —
a recovery study with a hundred fits is one study in one job-folder.

## 4. The reserved set — the researcher's to decide

These are claims about the science. The researcher sets each one, and each one reaches a
manuscript. Code is written with these values only once the researcher has stated them.

- **formula** and random-effects structure
- **family**
- **priors** — family and parameters
- **sampling** — chains, iterations, warmup
- **exclusion criteria and cutoffs**
- **plot type**, and the researcher-chosen values on that figure
- **threshold** — any number deciding what counts as a case, a group, or an effect
- **recovery criterion** — the correlation, bias or precision a recovery study is judged by

A job whose specification is silent on one of these stops and asks for it, in the researcher's
terms. **This rule holds in every session, with or without the `malka` skill.**

Everything else — how a script is split, what an object is called, panel order — is the agent's
to decide, marked in the file with an `ASSUMED[...]` comment where the specification left it open.

## 5. How a job runs here

Two questions decide how a request is handled. Does it change a value in section 4? Does
it create a new job-folder?

| Level | The request… | What to do |
|---|---|---|
| **Direct** | changes no reserved value and creates no job-folder | Do it. Load the craft skills you need. |
| **Confirm** | changes a reserved value inside a job-folder that exists | State the change and what it makes stale, in one or two sentences. Wait for yes. Then edit the code and `summary.md` together. |
| **Build** | creates a job-folder, or sets up a project | Load the `malka` skill and follow it. |

**Direct** covers answering a question, explaining code or output, reading a result, fixing an
error the researcher brought back from R, renaming or splitting a script, a cosmetic change to a
figure, and any change **outside section 4** that the researcher has already specified exactly.
This is most of the work in a project that is set up. A value in section 4 is never Direct, however
exactly it was specified: "use a 250 ms cutoff" is a cutoff, so it is Confirm.

A request to write where the section 2 table allows no writing — `data/collected/` above all — is
refused at any level, naming the rule. Sections 1–4 bound every level; the levels decide only how
much checking the work needs.

**Confirm** covers a new cutoff, a changed formula, a different prior, a new covariate, a new
figure of an existing fit. The approval is one sentence and one yes, in the conversation.

**Build** covers a new preprocessing pipeline, a new regression, a new recovery study, a new
project, a cloned job-folder, and any request where the researcher asks for the interview.

When the `malka` skill is not available, say that the Shahar-Lab plugin is not installed on this
machine and stop before writing a new job-folder. Sections 1–4 still govern every session.

### Changing a job-folder that already exists

1. Read its `summary.md` first. It states the formula, cutoffs and settings the code implements.
2. When a reserved value changes, update `summary.md` in the same change, with one dated line
   saying what changed and why.
3. Name what the change makes stale. A new cutoff in `preprocessing/` rewrites `data/processed/`,
   so every `analysis/` folder reading it needs rerunning. Name those folders.

## 6. Writing R here

Code in this project is read by students who need to verify it. That is what these rules are for.

- **One step per script, 50–80 lines.** A longer step is two steps with two names. This is the
  single most important rule in this file: a script nobody reads is a result nobody checked.
- Each script reads its inputs from `artifacts_dir` at the top and saves its product at the
  bottom, so it runs on its own in a fresh session. Open it with one line naming both ends:
  `# reads: artifacts/df_trials.rds · writes: artifacts/df_stay.rds`
- `rm(list = ls())`, every `library()` call, and every path variable live in `main.R` only.
  Sourced scripts inherit them and define none of their own.
- Headers: `#### MAIN HEADER ####` and `# smaller subtitle`. `main.R` uses `#### SETUP ####`
  then `#### EXECUTE PIPELINE ####`.
- `project_root <- here::here()`. Build every path with `file.path()` from it.
- Base pipe `|>`. Call functions directly after `library()`; reach for `pkg::fun()` to resolve a
  real name conflict.
- Hold every cutoff in a named variable set once in `main.R`, and use that variable both in the
  filter and in the text that reports it.
- Prefer explicit intermediate objects over nested expressions. Write a `function()` when the
  researcher asked for one, or when the same block would otherwise repeat.
- Follow the style of the R already in this project before introducing a new pattern. Align
  `<-` and `=` within a related block where it helps, and use the fewest headers that make a
  script easy to navigate.
- Comment where the code is not readable from its names. Leave the rest to the names.
- Reach for these where the task calls for them: `set.seed()` where the researcher asked for
  reproducible random output, `tryCatch()` where there is a clear reason to recover from an
  expected error, `stop()` where the error prevents an incorrect result, and `apply`, `vapply`
  and their like where a vectorised expression or an explicit loop genuinely will not serve.
- Calling an external tool: pass absolute paths and escape any that may contain spaces —
  `system2("python", args = c(script_path, shQuote(data_path), shQuote(output_dir)))`.

**Preferred libraries:** `tidyverse`, `ggplot2`, `ggdist`, `brms`, `cmdstanr`, `posterior`,
`bayesplot`, `patchwork`, `here`, `knitr`.

**Lab variable names:** `df` for the main data frame; `reward`, `reward_oneback`, `choice`,
`stay_ch` where they apply.

## 7. Running the code

The agent writes code and leaves the running to the researcher, who runs `main.R` and brings back
the output. This is deliberate: it is the point at which a person looks at the result.

---

## This project

<!-- Fill this in for your study. Everything above is Shahar-Lab's and is replaced when the Shahar-Lab
     rules are refreshed. Everything below is yours and is never touched. -->

**Study:** Test-retest comparison of depression-symptom measurement: the PHQ-9 questionnaire
versus a pairwise-choice task (CBCU) over the same symptoms. Two online sessions (`time1`,
`time2`) per Prolific participant; the question is the reliability (ICC, consistency and
agreement) of each measure and how the two relate.

**Task:** CBCU — on each trial two of 15 symptom items are offered and the participant picks
A, B, or None. Modelled as Bradley-Terry: per-participant item utilities, with None as a 16th
utility (`tau`) and choice consistency as the utility spread (`sigma`; older models use an
inverse temperature `beta`). Model definitions live in `models/bradley_terry_*`.

**Key variables:** `prolific_id`, `time` (`time1` / `time2`), `block`, offered items, `choice`,
`rt`; PHQ-9 item and total scores; demographics including the MacArthur ladder (`ladder_rung`).

**Anything unusual about this project's data:**
- `data/collected/` arrives as Pavlovia CSVs under `session 1` / `session 2`, plus one Qualtrics
  demographics export. `session_id` other than `session_2` is recoded to `session_1`.
- `preprocessing/artifacts/collected.csv` is git-ignored (over GitHub's 100 MB limit), as are
  all `.rds` files — fits must be rerun locally.
- `data/collected/pilot data/first_wave/.claude/` is an old copy of the lab's earlier agent
  setup, kept as it arrived. Its rules are superseded by this file; do not follow them.
- RT is exploratory only: no RT cutoff and no RT-based exclusion.
