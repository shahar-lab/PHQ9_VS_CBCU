// MODEL: bradley_terry_beta_tau_per_indep
// Stan fitting code. Lives in models/bradley_terry_beta_tau_per_indep/ (project_rules §2.III).
//
// Two-session (test-retest) extension of bradley_terry_beta_tau_per, following the
// "independent model" of Schurr et al. (2024, Nat Hum Behav, Methods):
//   session level:     y_t^s ~ N(mu^s, sigma)
//   participant level: mu^s  ~ N(mu^g, eta_g)
// applied to the four scalar parameters (log_beta, tau, logit_key_decay, rho) on
// their unconstrained scale. sigma (between-session SD) is one value per parameter,
// shared across subjects. Utilities are estimated independently per session (no
// pooling across sessions). Likelihood is unchanged from the base model, but
// indexed by [subject, session]. Unlike the base model, key_value decays AFTER
// the trial uses it (use -> decay -> bump), so the next trial sees the full rho.
//
// Non-centered parameterization: mathematically identical to the centered form
// above, used because with only 2 sessions and a possibly small sigma the centered
// form produces funnel geometry.
//
// ASSUMED[no within-subject trial-order field given]: first_trial_in_block flags the
// first trial of each subject x session block, and trials between two resets are
// assumed to be in their experienced chronological order (as
// bradley_terry_beta_tau_per_indep.R's sim.block() produces them).

data {
  int<lower=1> N_trials;     // Total number of trials (all subjects, all sessions)
  int<lower=1> N_subjects;   // Number of unique subjects
  int<lower=1> N_sessions;   // Number of sessions (days) per subject
  int<lower=1> N_options;    // Number of available options (symptoms)

  array[N_trials] int<lower=1, upper=N_subjects> subject_index; // Subject ID for each trial
  array[N_trials] int<lower=1, upper=N_sessions> session_index; // Session ID for each trial
  array[N_trials] int<lower=1, upper=N_options> offer_A;         // Option A ID
  array[N_trials] int<lower=1, upper=N_options> offer_B;         // Option B ID

  // Choice tracks 3 possible states (1 = A, 2 = B, 3 = None)
  array[N_trials] int<lower=1, upper=3> choice;

  // 1 on the first trial of each subject x session block, 0 otherwise.
  // key_value resets at every flagged trial, i.e. at the start of each day.
  array[N_trials] int<lower=0, upper=1> first_trial_in_block;
}

parameters {
  // Raw, unconstrained utility parameters, one independent matrix per session
  array[N_sessions] matrix[N_subjects, N_options] u_raw;

  // log_beta: group mean, between-subject SD, between-session SD, raw deviations
  real mu_g_log_beta;
  real<lower=0> eta_log_beta;
  real<lower=0> sigma_log_beta;
  vector[N_subjects] z_subj_log_beta;
  matrix[N_subjects, N_sessions] z_sess_log_beta;

  // tau (Burden Threshold)
  real mu_g_tau;
  real<lower=0> eta_tau;
  real<lower=0> sigma_tau;
  vector[N_subjects] z_subj_tau;
  matrix[N_subjects, N_sessions] z_sess_tau;

  // key_decay, on the logit scale so the decay factor is constrained to (0, 1)
  real mu_g_logit_key_decay;
  real<lower=0> eta_logit_key_decay;
  real<lower=0> sigma_logit_key_decay;
  vector[N_subjects] z_subj_logit_key_decay;
  matrix[N_subjects, N_sessions] z_sess_logit_key_decay;

  // rho (perseveration bump), unconstrained like tau
  real mu_g_rho;
  real<lower=0> eta_rho;
  real<lower=0> sigma_rho;
  vector[N_subjects] z_subj_rho;
  matrix[N_subjects, N_sessions] z_sess_rho;
}

transformed parameters {
  // Subject-level means (mu^s), unconstrained scale
  vector[N_subjects] mu_s_log_beta        = mu_g_log_beta        + eta_log_beta        * z_subj_log_beta;
  vector[N_subjects] mu_s_tau             = mu_g_tau             + eta_tau             * z_subj_tau;
  vector[N_subjects] mu_s_logit_key_decay = mu_g_logit_key_decay + eta_logit_key_decay * z_subj_logit_key_decay;
  vector[N_subjects] mu_s_rho             = mu_g_rho             + eta_rho             * z_subj_rho;

  // Session-level values (y_t^s), [subject, session]
  matrix[N_subjects, N_sessions] log_beta;
  matrix[N_subjects, N_sessions] tau;
  matrix[N_subjects, N_sessions] logit_key_decay;
  matrix[N_subjects, N_sessions] rho;

  for (k in 1:N_sessions) {
    log_beta[, k]        = mu_s_log_beta        + sigma_log_beta        * z_sess_log_beta[, k];
    tau[, k]             = mu_s_tau             + sigma_tau             * z_sess_tau[, k];
    logit_key_decay[, k] = mu_s_logit_key_decay + sigma_logit_key_decay * z_sess_logit_key_decay[, k];
    rho[, k]             = mu_s_rho             + sigma_rho             * z_sess_rho[, k];
  }

  // Natural-scale session values
  matrix<lower=0>[N_subjects, N_sessions] beta = exp(log_beta);
  matrix<lower=0, upper=1>[N_subjects, N_sessions] key_decay = inv_logit(logit_key_decay);

  // Constrained utilities, one matrix per session
  array[N_sessions] matrix[N_subjects, N_options] u_matrix;

  // Hard constraint: Force mean = 0 and variance = 1 for each subject x session
  for (k in 1:N_sessions) {
    for (i in 1:N_subjects) {
      real mu_u = mean(to_vector(u_raw[k][i, ]));
      real sd_u = sd(to_vector(u_raw[k][i, ]));

      u_matrix[k][i, ] = (u_raw[k][i, ] - mu_u) / sd_u;
    }
  }

  // Deterministic per-trial key_value contribution, one row per trial, one
  // column per outcome slot (1 = A, 2 = B, 3 = None). Single flat running pass,
  // reset at each subject x session block start.
  matrix[N_trials, 3] key_contrib;

  vector[3] key_value;

  for (t in 1:N_trials) {
    int s = subject_index[t];
    int k = session_index[t];

    if (first_trial_in_block[t] == 1) {
      key_value = rep_vector(0, 3);
    }

    // This trial sees the full rho bump from the previous trial's choice
    key_contrib[t, 1] = key_value[1];
    key_contrib[t, 2] = key_value[2];
    key_contrib[t, 3] = key_value[3];

    // After this trial's choice: decay the old values, then bump only the
    // chosen slot, so the next trial sees key_decay * key_value + rho on it
    key_value = key_value * key_decay[s, k];
    key_value[choice[t]] += rho[s, k];
  }
}

model {
  // ASSUMED[paper priors are on a standardized phenotype scale]: group means and
  // between-subject SDs keep the base model's hyperpriors (parameters here are on
  // native log/logit scales); only the between-session SD sigma takes the paper's
  // half-normal(0, 1).

  // log_beta
  mu_g_log_beta ~ normal(0, 2);
  eta_log_beta ~ exponential(2);
  sigma_log_beta ~ normal(0, 1);
  z_subj_log_beta ~ std_normal();
  to_vector(z_sess_log_beta) ~ std_normal();

  // tau
  mu_g_tau ~ normal(0, 2);
  eta_tau ~ exponential(2);
  sigma_tau ~ normal(0, 1);
  z_subj_tau ~ std_normal();
  to_vector(z_sess_tau) ~ std_normal();

  // logit_key_decay
  mu_g_logit_key_decay ~ normal(0, 1.5);
  eta_logit_key_decay ~ exponential(2);
  sigma_logit_key_decay ~ normal(0, 1);
  z_subj_logit_key_decay ~ std_normal();
  to_vector(z_sess_logit_key_decay) ~ std_normal();

  // rho
  mu_g_rho ~ normal(0, 2);
  eta_rho ~ exponential(2);
  sigma_rho ~ normal(0, 1);
  z_subj_rho ~ std_normal();
  to_vector(z_sess_rho) ~ std_normal();

  // Weak prior on u_raw to provide initial geometry before transformation
  for (k in 1:N_sessions) {
    to_vector(u_raw[k]) ~ normal(0, 1);
  }

  // Likelihood function
  for (t in 1:N_trials) {
    int s = subject_index[t];
    int k = session_index[t];
    vector[3] log_weights;

    // Weight for Option A (Temperature * Utility + perseveration)
    log_weights[1] = beta[s, k] * u_matrix[k][s, offer_A[t]] + key_contrib[t, 1];

    // Weight for Option B (Temperature * Utility + perseveration)
    log_weights[2] = beta[s, k] * u_matrix[k][s, offer_B[t]] + key_contrib[t, 2];

    // Weight for None (The independent Burden Threshold + perseveration)
    log_weights[3] = tau[s, k] + key_contrib[t, 3];

    choice[t] ~ categorical_logit(log_weights);
  }
}
