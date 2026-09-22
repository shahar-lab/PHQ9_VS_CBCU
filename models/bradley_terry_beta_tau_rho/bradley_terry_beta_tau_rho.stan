// MODEL: bradley_terry_beta_tau_rho
// Stan fitting code. Lives in models/bradley_terry_beta_tau_rho/ (project_rules §2.III).
//
// Variant of bradley_terry_beta_tau_per with key_decay fixed at 0 (perfect decay):
// key_value resets to zero every trial before the current choice is evaluated, so
// only the immediately preceding trial's chosen slot carries a perseveration bump
// of rho. There is no key_decay parameter, and no mu_logit_key_decay /
// sigma_key_decay group-level hyperparameters.
//
// ASSUMED[no within-subject trial-order field given]: first_trial_in_block makes
// subject boundaries explicit and checkable from the data itself (it flags each
// subject's first trial), resolving the earlier lack of any way to verify where
// one subject's trials end and the next begin. What remains assumed is the order
// of trials WITHIN a subject's block: trials between two resets are assumed to be
// in their experienced chronological order (as bradley_terry_beta_tau_rho.R's
// sim.block() produces them), since first_trial_in_block marks only where a
// block starts, not the internal order of the trials inside it.

data {
  int<lower=1> N_trials;     // Total number of trials
  int<lower=1> N_subjects;   // Number of unique subjects
  int<lower=1> N_options;    // Number of available options (symptoms)

  array[N_trials] int<lower=1, upper=N_subjects> subject_index; // Subject ID for each trial
  array[N_trials] int<lower=1, upper=N_options> offer_A;         // Option A ID
  array[N_trials] int<lower=1, upper=N_options> offer_B;         // Option B ID

  // Choice tracks 3 possible states (1 = A, 2 = B, 3 = None)
  array[N_trials] int<lower=1, upper=3> choice;

  // Explicit block-start flag, 1 on the first trial belonging to each subject
  // (in the order trials appear in the arrays), 0 otherwise. Lets the
  // key_value running pass in transformed parameters reset per subject with a
  // single flat loop instead of an implicit subject-grouping scan.
  array[N_trials] int<lower=0, upper=1> first_trial_in_block;
}

parameters {
  // Raw, unconstrained utility parameters
  matrix[N_subjects, N_options] u_raw;

  // Group-level beta parameters
  real mu_log_beta;
  real<lower=0> sigma_log_beta;

  // Subject-level betas
  vector<lower=0>[N_subjects] beta;

  // Group-level tau (Burden Threshold) parameters
  real mu_tau;
  real<lower=0> sigma_tau;

  // Subject-level taus
  vector[N_subjects] tau;

  // Group-level rho (perseveration) parameters, unconstrained like tau
  real mu_rho;
  real<lower=0> sigma_rho;

  // Subject-level rho
  vector[N_subjects] rho;
}

transformed parameters {
  // Constrained utilities
  matrix[N_subjects, N_options] u_matrix;

  // Deterministic per-trial key_value contribution, one row per trial, one
  // column per outcome slot (1 = A, 2 = B, 3 = None). With key_decay fixed at
  // 0, only the immediately preceding trial's chosen slot ever carries a
  // nonzero value (rho); it is zero on each subject's first_trial_in_block,
  // since there is no preceding trial within that subject's block to carry a
  // bump forward from.
  matrix[N_trials, 3] key_contrib;

  // Hard constraint: Force mean = 0 and variance = 1 for each subject
  for (i in 1:N_subjects) {
    real mu_u = mean(to_vector(u_raw[i, ]));
    real sd_u = sd(to_vector(u_raw[i, ]));

    u_matrix[i, ] = (u_raw[i, ] - mu_u) / sd_u;
  }

  // key_value is declared outside the loop so it carries forward exactly one
  // trial (key_decay fixed at 0 means it never survives a second decay step),
  // and is reset to zero whenever first_trial_in_block flags a new subject's
  // block start, so no bump leaks in from the previous subject's last trial.
  vector[3] key_value = rep_vector(0, 3);

  for (t in 1:N_trials) {
    if (first_trial_in_block[t] == 1) {
      key_value = rep_vector(0, 3);
    }

    key_contrib[t, 1] = key_value[1];
    key_contrib[t, 2] = key_value[2];
    key_contrib[t, 3] = key_value[3];

    // key_decay fixed at 0: next trial's key_value starts from zero, not
    // from this trial's key_value, so only this trial's chosen slot (not
    // any earlier bump) carries forward.
    key_value = rep_vector(0, 3);
    key_value[choice[t]] += rho[subject_index[t]];
  }
}

model {
  // Hierarchical priors for beta
  mu_log_beta ~ normal(0, 2);
  sigma_log_beta ~ exponential(2);
  beta ~ lognormal(mu_log_beta, sigma_log_beta);

  // Hierarchical priors for tau
  mu_tau ~ normal(0, 2);
  sigma_tau ~ exponential(2);
  tau ~ normal(mu_tau, sigma_tau);

  // Hierarchical priors for rho
  mu_rho ~ normal(0, 2);
  sigma_rho ~ exponential(2);
  rho ~ normal(mu_rho, sigma_rho);

  // Weak prior on u_raw to provide initial geometry before transformation
  to_vector(u_raw) ~ normal(0, 1);

  // Likelihood function
  for (t in 1:N_trials) {
    vector[3] log_weights;

    // Weight for Option A (Temperature * Utility + perseveration)
    log_weights[1] = beta[subject_index[t]] * u_matrix[subject_index[t], offer_A[t]] + key_contrib[t, 1];

    // Weight for Option B (Temperature * Utility + perseveration)
    log_weights[2] = beta[subject_index[t]] * u_matrix[subject_index[t], offer_B[t]] + key_contrib[t, 2];

    // Weight for None (The independent Burden Threshold + perseveration)
    log_weights[3] = tau[subject_index[t]] + key_contrib[t, 3];

    choice[t] ~ categorical_logit(log_weights);
  }
}
