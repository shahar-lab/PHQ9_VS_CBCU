# Skill: Bayesian Regression Analysis (brms)

**🛑 MANDATORY WORKFLOW — Do not skip steps.**

## When to Invoke
Use this skill automatically when the user requests help with:
* Bayesian regression modeling using `brms`
* Setting up MCMC sampling or defining priors
* Running posterior predictive checks (PPCs) or diagnostics
* Organizing Bayesian analysis workflows
* **Triggers:** "brms", "bayesian regression", "bayesian model", "mcmc fitting", "fit brms"

## Workflow Gate (CRITICAL)

You MUST NOT write code until:
1. ✅ User has approved the regression **formula**
2. ✅ User has approved the **priors**
3. ✅ User has approved the **3-step plan**

## Step 1: Validation Workflow
Read and follow: `workflow/VALIDATION.md`

This file contains the exact sequence for:
- Suggesting a specific formula based on the user's research question
- Suggesting informative priors based on domain knowledge
- Presenting a 3-step plan
- Waiting for user approval on ALL THREE before proceeding

## Step 2: Sub-Agent Code Generation (After User Approval)
Once the user has approved formula, priors, and plan:
1. Read: `workflow/EXPERT-INSTRUCTIONS.md`
2. Invoke the sub-agent with the user's approved specifications
3. Reference the examples in `references/` as needed

## Assumptions (Standalone Skill)

This skill is standalone: it knows brms modeling, nothing about projects or folders. It assumes the caller provides, before code generation:

- A prepared working folder and the variables `code_dir`, `artifacts_dir`, `output_dir` defined in the orchestrator script
- A `data_path` (or a `df` already in scope) pointing at clean, analysis-ready data
- Libraries loaded in the orchestrator script — sourced scripts never call `library()`

Fitted models and draws save to `artifacts_dir`; plots and tables to `output_dir`; scripts are sourced via `file.path(code_dir, ...)`. If any assumption is unmet, stop and tell the caller what is missing — do not create folders or invent paths.