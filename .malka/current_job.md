Job Card
JOB
Fit the same model to both sessions together (session ignored), in a separate job folder
FOLDER
analysis/beta_tau_halfnormal_stz_joint/ (new)
ROUTED READS
- 02-analysis/smart_clone.md
CHECKS
- Source job-folder
- What changes in the clone
SPECIFICATION
- Source job-folder: analysis/beta_tau_halfnormal_stz/ (code/ and main.R copied; artifacts/ and output/ start empty; source untouched)
- Model: models/bradley_terry_beta_tau_halfnormal_stz/bradley_terry_beta_tau_halfnormal_stz.stan, unchanged
- Priors (in the .stan file): beta_location ~ normal(4, 0.9); beta_scale ~ half-normal(0, 1); tau_location ~ normal(0, 0.4); tau_scale ~ normal(1, 0.3) truncated at 0; u ~ normal(0, sqrt(N/(N-1))) sum-to-zero
- Data: data/processed/cbcu.csv, session ignored; one unit per subject (185), all trials from both sessions (210 per subject); one fit
- Sampling: 4 chains, 3000 warmup, 5000 sampling per chain
- PHQ-9: sum and items 1-9 averaged over each subject's available sessions
- Kept (adapted to one fit): diagnostics PDF, participant parameter table, hyperparameter posterior plot (single density per panel; location filled, scale diagonal hatching, thick median line), u vs tau / u vs beta / beta vs tau scatters, PHQ-9 vs parameter scatters, utility vs PHQ-9 item, mean utility vs PHQ-9 item, parameter relationships summary
- Dropped: all test-retest scatters, beta test-retest posterior, beta posterior width, test-retest summary, both P(higher-utility option) test-retest measures
- Script and output names kept as in the source folder (approved on the Summary Card)
