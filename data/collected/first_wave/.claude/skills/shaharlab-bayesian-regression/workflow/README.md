# Bayesian Regression Workflow

This folder contains the mandatory validation and enforcement workflow for all Bayesian regression analyses in the Shahar Lab.

## How It Works

When you invoke `/shaharlab-bayesian-regression`, follow these three files in order:

### 1. **VALIDATION.md** (Steps 1-3)
**What happens:** You (Claude Code) validate with the user before any code is written.

**In this file, you will:**
- Suggest a specific regression formula
- Confirm or request the user's priors
- Present a 3-step plan
- **Obtain explicit user approval** on ALL THREE before proceeding

**Gate Check:** Do NOT proceed until:
- ✅ Formula is approved
- ✅ Priors are approved
- ✅ Plan is approved

### 2. **EXPERT-INSTRUCTIONS.md** (After User Approval)
**What happens:** You invoke a sub-agent to write the code.

**In this file, you will:**
- Verify you have all approved specifications
- Provide context to the sub-agent with the exact user approvals
- Reference the expert agent instructions
- Verify the sub-agent's output

### 3. **Assumptions** (Reference During Coding)
**What happens:** The sub-agent writes code into an environment the caller has prepared.

**The caller provides** (see SKILL.md "Assumptions"):
- A prepared working folder with `code_dir`, `artifacts_dir`, `output_dir` defined
- A `data_path` (or `df` in scope) for clean data
- Libraries loaded in the orchestrator script

The sub-agent saves fits to `artifacts_dir`, plots to `output_dir`, and sources scripts via `code_dir`.

---

## Critical Rule

**DO NOT SKIP THE VALIDATION STEP.**

The biggest mistake is reading these files, understanding them, and then proceeding directly to code generation without getting explicit user approval on formula, priors, and plan. This defeats the entire purpose of the workflow.

If you find yourself writing code before the user has approved all three items, you are breaking the gate. Stop and return to VALIDATION.md.

---

## Reference

For sub-agent code patterns, also reference:
- `references/sampling/sampling.md`
- `references/prior_predictive_check/prior_predictive_check.md`
- `references/posterior_predictive_check/posterior_predictive_check.md`
- `references/diagnostics/diagnostics.md`
