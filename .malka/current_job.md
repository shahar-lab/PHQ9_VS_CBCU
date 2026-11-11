Job Card
JOB
Fit bradley_terry_beta_tau_rho_noncentered to the real data; diagnostics, test-retest, relationships between parameters, mirroring analysis/beta_tau_per_pairwise
FOLDER
analysis/beta_tau_rho_noncentered/ (new)
ROUTED READS
- 02-analysis/smart_clone.md
- visualization/plot-types/plot-scatter.md
- visualization/standards/EXPORT_STANDARD.md, COLOR_STANDARD.md
CHECKS
- answered below
SPECIFICATION
- Source job-folder: analysis/beta_tau_per_pairwise (clone code/ and main.R; empty artifacts/ and output/)
- Model: models/bradley_terry_beta_tau_rho_noncentered/bradley_terry_beta_tau_rho_noncentered.stan
- Data: data/processed/cbcu.csv, data/processed/phq.csv; one fit per wave (time1, time2)
- Priors: as in the .stan file
- Sampling: 4 chains, 2000 warmup, 2000 sampling
- Subject estimates: posterior medians of u_1..u_15, beta, tau, rho (no key_decay)
- Diagnostics per wave: beta_location, beta_scale, tau_location, tau_scale, rho_location, rho_scale
- Test-retest: u, beta, tau, rho, PHQ9 sum and items
- Relationships: as in source, plus u vs rho, beta vs rho, tau vs rho per wave, PHQ9 sum / item SD vs rho
- Plot styles: as in source

Job Card
JOB
Create bradley_terry_beta_tau_rho_noncentered without rho
FOLDER
models/bradley_terry_beta_tau_noncentered/ (new)
ROUTED READS
- 03-models/references/how-to-write-a-model-definition.md
CHECKS
- answered below
SPECIFICATION
- Same as bradley_terry_beta_tau_rho_noncentered with rho, key_contrib and first_trial_of_subject removed (.stan and .R)
- Priors for beta, tau, u unchanged; non-centered

Job Card
JOB
Fit bradley_terry_beta_tau_noncentered to the real data; same outputs as job 1 without rho
FOLDER
analysis/beta_tau_noncentered/ (new)
ROUTED READS
- 02-analysis/smart_clone.md
- visualization/plot-types/plot-scatter.md
- visualization/standards/EXPORT_STANDARD.md, COLOR_STANDARD.md
CHECKS
- answered below
SPECIFICATION
- As job 1, model models/bradley_terry_beta_tau_noncentered, no rho anywhere
- Diagnostics: beta_location, beta_scale, tau_location, tau_scale
- Waits for job 2
