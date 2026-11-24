Job Card
JOB
ICC of choice prediction (mean probability of the chosen option, A/B/None) across days, without and with measurement error
FOLDER
analysis/beta_tau_halfnormal_stz/ (existing)
ROUTED READS
- regression/01_sampling_and_priors.md
- regression/02_diagnostics.md
- visualization/plot-types/plot-posterior.md
CHECKS
- Formula and RE structure
- Family
- Priors (offer weakly informative)
- Sampling
- Effect vs bounded vs other
SPECIFICATION
- Measure: per participant x day, mean over all 105 trials of exp(log_lik) (probability of the chosen option, A, B or None), per posterior draw -> posterior of choice prediction; definition as in simulation/.../07_plot_choice_prediction_test_retest.R (choice_prediction_all)
- Sample: 185 participants with both days
- Without ms: cp ~ 1 + (1 | id); cp = posterior median
- With ms: cp | se(se_cp, sigma = TRUE) ~ 1 + (1 | id); cp = posterior median, se_cp = posterior SD
- Scale: raw probability; gaussian
- Priors (both): Intercept ~ Normal(0.75, 0.25); sd(id), sigma ~ Half-Normal(0, 0.25)
- Sampling (both): 4 chains, iter 3000, warmup 1000, adapt_delta 0.95, seed 2026, cmdstanr
- ICC = sigma_b^2 / (sigma_b^2 + sigma_e^2) per draw (absolute agreement, no day effect)
- Diagnostics in diagnose_icc.R; pass before interpreting
- Outputs: icc_choice_prediction.csv; icc_choice_prediction_posterior (both, #4477AA / #EE6677) and icc_choice_prediction_without_ms_posterior (gray80); PDF + PNG in "test-retest across sessions"
- main.R and summary.md updated
