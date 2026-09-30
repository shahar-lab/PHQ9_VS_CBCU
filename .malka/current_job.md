Job Card
JOB
New model pair: Bradley-Terry beta/tau with alpha_per (learning-rate) perseveration
FOLDER
models/bradley_terry_beta_tau_alpha_per/ (new)
ROUTED READS
- 03-models/references/how-to-write-a-model-definition.md
CHECKS
- Parameters, task structure, new vs variant, generating/fitting agreements
SPECIFICATION
- Variant of models/bradley_terry_beta_tau_per (leave it untouched); same task (N_options symptoms, 2 offered per trial, None option)
- key_value (slots 1=A, 2=B, 3=None) starts at 0, reset at each subject's first trial
- Softmax: exp(beta*u1 + rho*key[1]), exp(beta*u2 + rho*key[2]), exp(tau + rho*key[3])
- Update after choice: key[chosen] += alpha_per*(1 - key[chosen]); key[each unchosen] += alpha_per*(0 - key[unchosen]). No key_decay parameter.
- Hierarchical non-centered: beta = exp(mu_log_beta + sigma_log_beta*raw); tau, rho normal; alpha_per = inv_logit(mu_logit_alpha + sigma_alpha*raw)
- Priors: mu_log_beta, mu_tau, mu_rho ~ normal(0,2); mu_logit_alpha ~ normal(0,1.5); ALL FOUR sigmas ~ half-normal(0,2) (normal(0,2) on <lower=0>); raw terms std_normal; u_raw ~ normal(0,1); u_matrix standardized per subject as in existing model
- Files: bradley_terry_beta_tau_alpha_per.R (sim.block generator, arguments subject,u,beta,tau,alpha_per,rho,cfg) and .stan

Job Card
JOB
Parameter-recovery study for the alpha_per model
FOLDER
simulation/bradley_terry_beta_tau_alpha_per_recovery/ (new)  -- waits for Job 1
ROUTED READS
- parameter_recovery/context.md
- parameter_recovery/template_summary.md
- 04-simulations/references/how-to-build-a-recovery-pipeline.md
- 04-simulations/references/how-to-read-recovery.md
- visualization/plot-scatter.md, plot-dot-histogram.md, standards/COLOR, EXPORT, PANEL_TAGGING
SPECIFICATION
- Clone structure from simulation/bradley_terry_beta_tau_per_recovery, re-pointed to the new model; alpha replaces key_decay (plot_alpha_per_recovery.R)
- 200 subjects, 15 options, 105 trials
- True group values: mu_log_beta 0.5/sigma 0.3; mu_tau 0/sigma 1; mu_rho 0/sigma 0.75; mu_logit_alpha 0/sigma 1
- Stan via cmdstanr, 4 chains, 3000 warmup, 2000 sampling
- Outputs: individual recovery for u, beta, tau, alpha_per, rho; group-level mu/sigma recovery; combined summary PDF
- Criteria: r >= 0.75; bias within 10% of true SD; 90% CI coverage 80-95%
