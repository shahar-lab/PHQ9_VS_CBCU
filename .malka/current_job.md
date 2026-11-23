Job Card
JOB
ICC of item profiles for CBCU utilities and PHQ-9 item ratings, centred within participant x occasion (no scaling)
FOLDER
analysis/beta_tau_halfnormal_stz/ (existing)
ROUTED READS
- regression/01_sampling_and_priors.md
- regression/02_diagnostics.md
- visualization/plot-types/plot-posterior.md
- visualization/standards/EXPORT_STANDARD.md
- visualization/standards/COLOR_STANDARD.md
CHECKS
- Formula and RE structure
- Family
- Priors (offer weakly informative)
- Sampling (offer 4 / 2000 / half warmup)
- Which parameters or effects
- Effect vs bounded vs other
- Single figure or composite
SPECIFICATION
- Sample: 185 participants with both occasions, same people for both measures; nobody dropped
- CBCU: posterior medians u_1..u_15 from artifacts/participant_parameters.csv; 5,550 rows; centred within participant x occasion, not scaled (replaces the standardised fit; standardised ICC 0.76 kept as a note in summary.md)
- PHQ-9: phq9_1..phq9_9 from artifacts/participant_parameters.csv; 3,330 rows; centred within participant x occasion, not scaled; flat profiles kept (all zeros after centring)
- Formula (both): y ~ 1 + (1 | item) + (1 | participant:item) + (1 | occasion:item); gaussian; no participant or participant x occasion term
- Priors (both): Intercept ~ Normal(0, 1); sd(item), sd(participant:item), sd(occasion:item), sigma ~ Half-Normal(0, 1)
- Sampling (both): 4 chains, iter 3000, warmup 1000, adapt_delta 0.95, seed 2026, cmdstanr
- Diagnostics: ESS/R-hat table, divergences, rank plots, pairs plot per model; pass before interpreting
- ICC = s2(participant:item) / (s2(participant:item) + s2(occasion:item) + s2(residual)) per draw
- Report: CSV per measure, ICC + each variance component, median + 95% CrI
- Plots: one single-posterior plot per measure (gray, 90% interval, x 0-1, dashed 0.80) + one comparison plot (CBCU #4477AA, PHQ-9 #EE6677, medians in legend); PDF + PNG in "test-retest across sessions"
- summary.md: model, centring rule, ICC definition, diagnostics
