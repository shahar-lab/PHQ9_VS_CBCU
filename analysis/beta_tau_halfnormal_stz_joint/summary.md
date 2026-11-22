# Analysis Notebook: Bradley-Terry with None option, both sessions fitted jointly

**Model:** `models/bradley_terry_beta_tau_halfnormal_stz/bradley_terry_beta_tau_halfnormal_stz.stan` (unchanged)
**Date Created:** 2026-11-22
**Cloned from:** `analysis/beta_tau_halfnormal_stz/` (one fit per session)

On each trial a subject sees items A and B and chooses A, B or None:

- logit(A) = β·u_A, logit(B) = β·u_B, logit(None) = β·τ
- u: 15 item utilities per subject, sum to zero, prior normal(0, sqrt(15/14))
- β ~ normal(β_location, β_scale) truncated at 0; τ ~ normal(τ_location, τ_scale)
- Priors: β_location ~ normal(4, 0.9), β_scale ~ half-normal(0, 1),
  τ_location ~ normal(0, 0.4), τ_scale ~ normal(1, 0.3) truncated at 0

## 1. Hypotheses
* The same model as the per-session analysis, fitted once to all the data with session
  ignored. Each subject has one β, one τ and one set of utilities, estimated from both
  sessions' trials, so the estimates use twice the data of a per-session fit.
* Comparing with `analysis/beta_tau_halfnormal_stz/` shows how much the per-subject and
  population estimates change when the sessions are pooled.

## 2. Variables
* **Data:** `data/processed/cbcu.csv`, both sessions pooled: 185 subjects, 210 trials each
  (all 105 item pairs, once per session).
* **Choice:** 1 = A (left), 2 = B (right), 3 = None (skip).
* **PHQ-9:** `data/processed/phq.csv`, the sum score and items 1–9 averaged over each
  subject's sessions (all 185 subjects have both).
* **Sampling:** 4 chains, 3000 warmup and 5000 sampling iterations per chain.

## 3. Outputs
* `output/diagnostic.pdf` — ESS / R-hat table, rank plots and pairs plot of the hyperparameters.
* `output/hyperparameter_posteriors.png` — posterior of β_location, β_scale, τ_location, τ_scale.
* `output/relations between parameters/` — u vs τ, u vs β, β vs τ, PHQ-9 vs β and τ,
  utility vs PHQ-9 item, mean utility vs PHQ-9 item, and a combined PDF.
* `artifacts/participant_parameters.csv` — posterior medians per subject, with PHQ-9.

## 4. Findings / Summary
* (Leave this section blank until the model is completely fitted and evaluated).
