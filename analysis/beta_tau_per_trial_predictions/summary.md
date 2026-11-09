# Analysis Notebook: beta_tau_per_trial_predictions

**Model:** `models/bradley_terry_beta_tau_per/bradley_terry_beta_tau_per.stan`, using the existing fits in `analysis/beta_tau_per_pairwise/artifacts/` (no refit).
**Date Created:** 2026-11-08

## 1. Goal

One row per trial of `data/processed/cbcu.csv` (time1 and time2 stacked), plus each participant's parameters, the utilities of the offered items, the perseveration value per key, and the model's choice probabilities.

## 2. Added columns

| Column | Meaning |
|---|---|
| `beta`, `tau`, `decay`, `rho` | Participant posterior mean (`decay` is the model's `key_decay`) |
| `utility_A`, `utility_B` | Posterior-mean standardized utility (`u_matrix`) of the left (A) and right (B) item |
| `key_contrib_A/B/None` | Perseveration value on the log-weight scale (rho times decayed memory of earlier choices), before the trial; 0 on a participant's first trial |
| `prob_A/B/None` | Softmax of the log-weights: `beta*utility + key_contrib` for A and B, `tau + key_contrib` for None (same as exponentiating Stan's `categorical_logit`) |

## 3. Design notes

- Posterior MEAN of each parameter (the pairwise folder's `participant_parameters.csv` holds medians, so values differ slightly).
- Probabilities are plug-in values from the posterior-mean parameters, not averages over draws.
- `key_contrib` is recomputed in R in the fits' trial order (`prolific_id`, `block`, `trial`, per wave), mirroring the Stan `transformed parameters` block.
- `main.R` checks that probabilities sum to 1, the row count matches `cbcu.csv`, and no value is missing.

## 4. Findings

(placeholder: filled in after the researcher inspects the output)
