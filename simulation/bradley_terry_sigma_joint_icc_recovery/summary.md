# Recovery Notebook: joint two-session sigma model with ICCs as parameters

**Generative model:** `models/bradley_terry_sigma_joint_icc/` (`bradley_terry_sigma_joint_icc.R`)
**Fitted model:** `models/bradley_terry_sigma_joint_icc/bradley_terry_sigma_joint_icc.stan`
**Job-folder:** `simulation/bradley_terry_sigma_joint_icc_recovery/`
**Date Created:** 2026-11-26

## 1. Design (set in `main.R`)

The model (see the `.stan` header) fits both sessions at once. A unit is one participant in one
session (c = -1/2, +1/2). Choice rule as `bradley_terry_sigma`: logit(A) = u[A], logit(B) = u[B],
logit(None) = u[16] = tau.

* **log(sigma):** mu + c·delta + s·(√ICC_σ·z_i + √(1−ICC_σ)·e_ij). ICC_σ is the consistency ICC.
* **Utilities (k = 1..16, 16 = None), pooled:** x = m_k + c·delta_k + √(16/15)·centred(√ICC_k·z_ik + √(1−ICC_k)·e_ijk), u = sigma·x, with ICC_k = ICC_profile for the 15 items (one shared value, as in Hypothesis 1, eq. [1]) and ICC_tau for None. Each utility's SD across people is fixed at 1 (identifies the scale against sigma), so sigma is the spread of a unit's utilities around the population item means (~0.7× the `bradley_terry_sigma` sigma in the real data).
* **Mapping to eq. [1]:** participant × item variance = ICC_profile; residual = 1 − ICC_profile; occasion × item variance = mean(delta_k²)/2 over the 15 items.
* **Agreement ICCs (derived, McGraw & Wong ICC(A,1)):** ICC_A,σ = ICC_σ·s² / (s² + delta²/2); ICC_profile_A = ICC_profile / (1 + mean(delta_k²)/2) — this is **Hypothesis 1, eq. [2]**; ICC_A,tau = ICC_tau / (1 + delta_None²/2).
* **n_subjects:** 185 · **n_sessions:** 2 · **n_trials:** 105 per session (every pair once, random order and sides)
* **Population location:** mu_log_sigma = 1.65, delta_log_sigma = 0.20; item means m_k ~ Normal(0, 0.7), shifted to sum to zero with the None mean fixed at −0.25 (gives 25–28% None choices; real data 27.5%); session shifts delta_k ~ Normal(0, 0.3) centred
* **Population scale:** s_log_sigma = 0.45
* **True consistency ICCs, three runs (crossed):** run 1: sigma 0.5, items 0.8, tau 0.7 · run 2: sigma 0.7, items 0.6, tau 0.9 · run 3: sigma 0.9, items 0.4, tau 0.5 (`artifacts/icc_sigma_<value>/`)
* **Unit-interval transforms:** none (ICCs set directly on [0, 1])
* **Fitted priors:** ICC_σ, ICC_profile, ICC_tau Beta(1, 1); mu Normal(1.6, 0.75); s Half-Normal(0, 1); delta Normal(0, 0.5); m_k Normal(0, 1) sum-to-zero; delta_k Normal(0, 0.5) sum-to-zero
* **Sampler:** Stan via cmdstanr, 4 chains, 3000 warmup, 2000 sampling, `init = 0.5`
* **Recovery criteria:** reported, no pass/fail thresholds: ICC posterior median vs true and 95% coverage; unit-level Pearson r, bias, slope, median posterior SD

## 2. Generating true parameters

* `01_generate_true_parameters.R`: per run, population values and standard normals z, e; combined with `compose_log_sigma()` / `compose_utilities()` from the model's `.R` (same steps as the `.stan`).
* Artifacts per run: `true_population.rds` (incl. true agreement ICCs), `true_parameters.rds`, `true_u.rds`
* `02_plot_true_parameters.R` → `output/02_true_parameters_<run>.{pdf,png}`: sigma and tau per session with their population densities.

## 3. Generating data

* `03_generate_data.R` with `generate_bradley_terry_sigma_joint_icc()`; prints the share of None choices and of choices for the higher item.
* Artifacts per run: `simulated_data.rds`, `stan_data.rds`

## 4. Recovering parameters

* `04_fit_model.R`: one joint fit per run. The fit object is not saved (several GB); saved per run: `draws_pop.rds` (population parameters and all ICCs), `draws_sbj.rds` (sigma, tau per unit), `summary_u.rds` (utilities), `diagnostics.rds`.
* `05_extract_recovered_parameters.R` → `artifacts/recovery_population.rds`, `artifacts/recovered_parameters.rds`

## 5. Outputs

* `06_convergence.csv` — divergences, tree depth, E-BFMI, R-hat, ESS per run (read first).
* `07_population_location` (Fig. 1: mu, s, delta of log sigma; item means and shifts), `08_icc_posteriors` (Fig. 2: consistency and agreement ICCs of sigma, item profile, tau), `09_icc_recovery` (Fig. 3 + `.csv`: every ICC, true vs recovered), `10_individual_recovery` (Fig. 4 + `.csv`).
* `11_recovery_figures.pdf` (Figures 1–4), `12_recovery_report.docx` (narrative, tables, figures with captions).

## 6. Findings / Summary

* **Sampling:** all three fits clean: 0 divergences, 0 max-treedepth hits, E-BFMI ≥ 0.74, R-hat ≤ 1.007, bulk ESS ≥ 927 (population; lowest for icc_sigma) and ≥ 3268 (units). 4.9–6.0 h per run (12 chains run in parallel).
* **Item profile ICC (Hypothesis 1):** recovered precisely in every run. Consistency 0.80 / 0.61 / 0.42 (true 0.8 / 0.6 / 0.4); agreement (eq. [2]) 0.77 / 0.59 / 0.40 (true 0.78 / 0.58 / 0.39); 95% intervals ~±0.04, all covering.
* **ICC of tau:** recovered well: 0.64 / 0.89 / 0.49 (true 0.7 / 0.9 / 0.5), intervals ~±0.1, all covering; agreement likewise.
* **ICC of sigma:** covered in all three runs, but imprecise (95% interval width 0.29–0.42) and the median is below the true value in every run: 0.43 / 0.57 / 0.84 (true 0.5 / 0.7 / 0.9). The agreement ICC of sigma missed in run 2 (0.45, interval 0.26–0.62, true 0.64) because delta_log_sigma was overestimated there (0.31, interval 0.21–0.41, true 0.20); the other two runs recovered delta.
* **Other population parameters:** mu and s of log sigma, the 16 item means and the 16 session shifts recovered well (r ≥ 0.94; coverage 0.88–1.0).
* **Units:** sigma per unit-session r = 0.68 / 0.76 / 0.80, OLS slope 0.46–0.65 (strong shrinkage of large sigma, as in the single-session model); tau r = 0.94, item utilities r = 0.90–0.91; 95% coverage 0.95–0.97 for all.
* **Reading:** the joint model recovers the utility-level ICCs (profile, tau) accurately, so the H1 ICC can be estimated in one step. The sigma ICC is identified but weak and leans low, consistent with the ceiling on large sigma (near-deterministic choosers): the sigma ICC from real data should be read as a lower-leaning estimate with a wide interval. Three runs cannot tell a systematic bias from chance; more runs (or a larger n) would be needed to quantify it.
* **Implementation note:** the likelihood and the utility step of the `.stan` are vectorised; log density and gradient are identical to the loop version (|diff| < 2e-11), 1.5x faster per gradient.

## 7. Manuscript excerpt — example 1

[Placeholder until the pipeline is run.]

## 8. Manuscript excerpt — example 2

[Placeholder until the pipeline is run.]
