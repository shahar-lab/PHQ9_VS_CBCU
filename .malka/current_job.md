Job Card
JOB
Joint two-session sigma model with ICCs as free parameters (consistency free, agreement derived)
FOLDER
models/bradley_terry_sigma_joint_icc/ (new)
ROUTED READS
- 03-models/references/how-to-write-a-model-definition.md
- 04-simulations/references/how-to-build-a-recovery-pipeline.md
CHECKS
- Parameters, what each does, and the scale each is on
- Task structure
- New definition or structural variant
- The three generating/fitting agreements if a recovery will use the pair
SPECIFICATION
- Choice rule as bradley_terry_sigma: logit(A) = u[A], logit(B) = u[B], logit(None) = u[16]
- Unit = participant x session; c_j = -1/2 (session 1), +1/2 (session 2)
- log sigma_ij = mu + c_j*delta + s*(sqrt(ICC_sigma)*z_i + sqrt(1-ICC_sigma)*e_ij)
- x_ijk = m_k + c_j*delta_k + sqrt(K/(K-1))*centred(sqrt(ICC_k)*z_ik + sqrt(1-ICC_k)*e_ijk), K = 16; u = sigma*x
- REVISED (user, pooled): ICC_k = ICC_profile (one value, the 15 items; Hypothesis 1 eq. [1]) and ICC_tau (None)
- Item SD across people fixed at 1 (identification)
- Agreement: ICC_A_sigma = ICC*s^2/(s^2 + delta^2/2); ICC_profile_A = ICC_profile/(1 + mean(delta_items^2)/2) (= eq. [2]); ICC_A_tau = ICC_tau/(1 + delta_None^2/2)
- Priors: ICCs Beta(1,1); mu N(1.6, 0.75); s half-N(0,1); delta N(0,0.5); m_k N(0,1) sum-to-zero; delta_k N(0,0.5) sum-to-zero

Job Card
JOB
Parameter recovery of the joint ICC sigma model, three runs (ICC_sigma = 0.5, 0.7, 0.9)
FOLDER
simulation/bradley_terry_sigma_joint_icc_recovery/ (new)
ROUTED READS
- parameter_recovery/context.md
- parameter_recovery/template_summary.md
- 04-simulations/references/how-to-build-a-recovery-pipeline.md
- 04-simulations/references/how-to-read-recovery.md
- visualization/plot-types/plot-dot-histogram.md
- visualization/plot-types/plot-scatter.md
- visualization/plot-types/plot-posterior.md
- visualization/standards/COLOR_STANDARD.md
- visualization/standards/EXPORT_STANDARD.md
- visualization/standards/PANEL_TAGGING_STANDARD.md
CHECKS
- Which models/ definition generates and which is fitted
- Population location and scale per parameter (set in main.R)
- n_subjects, n_trials, n_sessions
- Sampler
- Success criteria: correlation, bias, precision
SPECIFICATION
- Generates and fits models/bradley_terry_sigma_joint_icc/ (waits for job 1)
- n_subjects 185, n_sessions 2, n_trials 105 per session (all 105 pairs once per session, random order)
- True: mu 1.65, s 0.45, delta 0.2; m_k ~ N(0, 0.7) centred, None mean fixed -0.25 (~27% None, as real data); delta_k ~ N(0, 0.3) centred
- REVISED (user): three crossed runs: (sigma, items, tau) = (0.5, 0.8, 0.7), (0.7, 0.6, 0.9), (0.9, 0.4, 0.5); everything else drawn fresh per run
- Stan via cmdstanr: 4 chains, 3000 warmup, 2000 sampling, init 0.5
- Criteria: report only (no pass/fail): ICC posterior median vs true, 95% coverage; unit-level Pearson r, bias, median posterior SD
- Outputs: dot histograms of true params, population posteriors vs true, ICC recovery figure, unit-level scatter, diagnostics, Word report, multi-page PDF
