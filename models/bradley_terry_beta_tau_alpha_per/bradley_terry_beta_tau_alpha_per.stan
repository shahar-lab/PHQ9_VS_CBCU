// MODEL: bradley_terry_beta_tau_alpha_per
// Stan fitting code. Lives in models/bradley_terry_beta_tau_alpha_per/ (project_rules §2.III).
//
// Extends bradley_terry_beta_tau with a per-outcome (A / B / None) key_value learned
// with a learning rate alpha_per: after each choice the chosen slot moves toward 1 and
// each unchosen slot moves toward 0. key_value enters the 3-way decoupled Softmax
// scaled by rho. key_value is deterministic given alpha_per and the observed choice
// sequence, so it is reconstructed with a single flat running pass over all trials in
// transformed parameters.
//
// Agreements with bradley_terry_beta_tau_alpha_per.R:
//   population form: log(beta), tau, rho, logit(alpha_per) are normal across subjects
//   parameter scale: alpha_per is a probability in (0, 1) = inv_logit(logit scale)
//   choice rule:     exp(beta*u1 + rho*key[1]), exp(beta*u2 + rho*key[2]), exp(tau + rho*key[3])
//
// ASSUMED: trials between two first_trial_in_block resets are in their experienced
// chronological order (as sim.block() produces them) — the flag marks only where a
// subject's block starts, not the internal trial order.

data {
  int<lower=1> N_trials;     // Total number of trials
  int<lower=1> N_subjects;   // Number of unique subjects
  int<lower=1> N_options;    // Number of available options (symptoms)

  array[N_trials] int<lower=1, upper=N_subjects> subject_index; // Subject ID for each trial
  array[N_trials] int<lower=1, upper=N_options> offer_A;         // Option A ID
  array[N_trials] int<lower=1, upper=N_options> offer_B;         // Option B ID

  // Choice tracks 3 possible states (1 = A, 2 = B, 3 = None)
  array[N_trials] int<lower=1, upper=3> choice;

  // 1 on each subject's first trial; resets key_value per subject below.
  array[N_trials] int<lower=0, upper=1> first_trial_in_block;
}

parameters {
  // Raw, unconstrained utility parameters
  matrix[N_subjects, N_options] u_raw;

  // Group-level beta parameters
  real mu_log_beta;
  real<lower=0> sigma_log_beta;
  vector[N_subjects] beta_raw;   // non-centered raw term -> beta

  // Group-level tau (Burden Threshold) parameters
  real mu_tau;
  real<lower=0> sigma_tau;
  vector[N_subjects] tau_raw;    // non-centered raw term -> tau

  // Group-level alpha_per parameters (logit scale, so alpha_per stays in (0,1))
  real mu_logit_alpha;
  real<lower=0> sigma_alpha;
  vector[N_subjects] alpha_raw;  // non-centered raw term -> alpha_per

  // Group-level rho parameters
  real mu_rho;
  real<lower=0> sigma_rho;
  vector[N_subjects] rho_raw;    // non-centered raw term -> rho
}

transformed parameters {
  // Constrained utilities
  matrix[N_subjects, N_options] u_matrix;

  // Non-centered reconstructions (raw std-normal * scale + location)
  vector<lower=0>[N_subjects] beta = exp(mu_log_beta + sigma_log_beta * beta_raw);
  vector[N_subjects] tau = mu_tau + sigma_tau * tau_raw;
  vector[N_subjects] rho = mu_rho + sigma_rho * rho_raw;
  vector[N_subjects] logit_alpha_per = mu_logit_alpha + sigma_alpha * alpha_raw;
  vector<lower=0, upper=1>[N_subjects] alpha_per = inv_logit(logit_alpha_per);

  // Per-trial key_value seen by the choice (1 = A, 2 = B, 3 = None), reconstructed
  // via a single flat pass over all trials, reset at each subject's block start.
  matrix[N_trials, 3] key_contrib;

  // Force mean = 0, sd = 1 per subject
  for (i in 1:N_subjects) {
    real mu_u = mean(to_vector(u_raw[i, ]));
    real sd_u = sd(to_vector(u_raw[i, ]));

    u_matrix[i, ] = (u_raw[i, ] - mu_u) / sd_u;
  }

  // Carries forward across trials; reset to zero at each subject's block start.
  vector[3] key_value;

  for (t in 1:N_trials) {
    if (first_trial_in_block[t] == 1) {
      key_value = rep_vector(0, 3);
    }

    key_contrib[t, 1] = key_value[1];
    key_contrib[t, 2] = key_value[2];
    key_contrib[t, 3] = key_value[3];

    // After the choice: chosen slot moves toward 1, each unchosen slot toward 0
    for (k in 1:3) {
      real key_target = (k == choice[t]) ? 1.0 : 0.0;
      key_value[k] += alpha_per[subject_index[t]] * (key_target - key_value[k]);
    }
  }
}

model {
  // Hierarchical priors, all non-centered (raw ~ std_normal(), scaled/shifted above)
  // sigma priors are half-normal(0, 2): normal(0, 2) on a <lower=0> parameter
  mu_log_beta ~ normal(0, 2);
  sigma_log_beta ~ normal(0, 2);
  beta_raw ~ std_normal();

  mu_tau ~ normal(0, 2);
  sigma_tau ~ normal(0, 2);
  tau_raw ~ std_normal();

  mu_logit_alpha ~ normal(0, 1.5);
  sigma_alpha ~ normal(0, 2);
  alpha_raw ~ std_normal();

  mu_rho ~ normal(0, 2);
  sigma_rho ~ normal(0, 2);
  rho_raw ~ std_normal();

  // Weak prior on u_raw to provide initial geometry before transformation
  to_vector(u_raw) ~ normal(0, 1);

  // Likelihood function
  for (t in 1:N_trials) {
    vector[3] log_weights;

    // Weight for Option A (Temperature * Utility + rho * key_value)
    log_weights[1] = beta[subject_index[t]] * u_matrix[subject_index[t], offer_A[t]]
                     + rho[subject_index[t]] * key_contrib[t, 1];

    // Weight for Option B (Temperature * Utility + rho * key_value)
    log_weights[2] = beta[subject_index[t]] * u_matrix[subject_index[t], offer_B[t]]
                     + rho[subject_index[t]] * key_contrib[t, 2];

    // Weight for None (The independent Burden Threshold + rho * key_value)
    log_weights[3] = tau[subject_index[t]] + rho[subject_index[t]] * key_contrib[t, 3];

    choice[t] ~ categorical_logit(log_weights);
  }
}
