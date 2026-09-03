# Scaffolding Review Checklist (for the Code Reviewer agent)

**This is the scaffolding domain checklist used by the `shaharlab_code_reviewer` agent.** Your job is to verify TWICE — the plan (Phase A) and the executed result (Phase B) — against the lab topology, and emit a feedback block. You do NOT touch the disk. When possible, run this review as a separate subagent so the reviewer did not author what it reviews.

> Do not restate the topology here. Verify against `.claude/context/shaharlab_project_rules.md`, `references/folder_structure.md`, `references/new_folder.md`, `references/smart_clone.md`, and the hooks in `.claude/hooks/`. Cite, don't duplicate.

## Phase A: Review the PLAN (pre-execution gate)

For each planned operation, ask:

- [ ] Does it cite a rule, and will it actually satisfy that rule?
- [ ] Missing steps? (a clone without WIPE or without RE-POINT is a defect — references/smart_clone.md)
- [ ] Extra steps beyond the user's intent?
- [ ] New folder names valid `snake_case` (no `~ + | /` or spaces — references/new_folder.md)?
- [ ] Correct parent for the folder type (analysis/, simulation/, models/, preprocessing/ — references/folder_structure.md)?
- [ ] Plan reads data from `data/processed/` (or the user-specified stage), never copies it (project_rules §2.I)?

**On pass:** release the plan to the USER-APPROVAL gate. **On fail:** return for plan revision.

## Phase B: Review the RESULT (post-execution gate)

Inspect the disk after execution:

- [ ] Canonical set exists for analysis/simulation folders: `code/`, `artifacts/`, `output/`, `main.R`, `summary.md` (§3)
- [ ] Model folders contain `[MODEL_NAME].R` / `[MODEL_NAME].stan` matching the folder name (references/folder_structure.md)
- [ ] On clones: `artifacts/` and `output/` are EMPTY (§2.I, references/smart_clone.md)
- [ ] Path segments == actual parent and folder name (§4 + pre-hook)
- [ ] No data duplication; no numbered scripts in `code/` (§2.I, §2.II)
- [ ] `.stan` / mechanistic files only in `models/` (§2.III)
- [ ] `summary.md` present with metadata (§3)
- [ ] Hook-enforced path syntax held: `here::here()` + `file.path()` (`.claude/hooks/`)

**On pass:** approve — scaffolding is rule-compliant. **On fail:** send back for re-execution and loop.

## How to Report Findings

### When APPROVED ✅
```
REVIEW COMPLETE: APPROVED ✅

Phase: [A — plan | B — result]
Summary: All checks passed.
- Every operation cites and satisfies its rule
- snake_case naming; clone wipe + re-point present
- Canonical set complete; no duplication; .stan only in models/

[Phase A] Releasing plan to user-approval gate.
[Phase B] Scaffolding is rule-compliant.
```

### When ISSUES FOUND ❌
```
REVIEW INCOMPLETE: ISSUES FOUND ❌

Phase: [A — plan | B — result]

Issue 1: [Specific problem]
- Location: [operation # or path]
- Problem: [What violates which rule]
- Fix: [How to fix it]

Action: [revise the plan | re-execute] and resubmit.
```

Do NOT approve while any checklist item is open.