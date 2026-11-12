// Hierarchical Bradley-Terry choice model with a "None" option.
//
// On each trial a subject sees options A and B and chooses A, B, or None:
//   logit(A)    = beta * u[A]
//   logit(B)    = beta * u[B]
//   logit(None) = beta * tau
//
// u    : subject-level item utilities, sum to zero within subject
// beta : inverse temperature, lognormal across subjects (beta > 0)
// tau  : threshold for choosing None, on the utility scale
//
// beta and tau are non-centered.
// Outputs for analysis: beta, tau, u_matrix, log_lik (all in transformed parameters).

data {
  int<lower=1> N_trials;
  int<lower=1> N_subjects;
  int<lower=2> N_options;

  array[N_trials] int<lower=1, upper=N_subjects> subject_index;
  array[N_trials] int<lower=1, upper=N_options> offer_A;
  array[N_trials] int<lower=1, upper=N_options> offer_B;
  array[N_trials] int<lower=1, upper=3> choice;   // 1 = A, 2 = B, 3 = None
}

parameters {
  array[N_subjects] sum_to_zero_vector[N_options] u;   // utilities per subject

  real beta_location;           // mean of log(beta)
  real<lower=0> beta_scale;     // SD of log(beta)
  vector[N_subjects] beta_raw;

  real tau_location;
  real<lower=0> tau_scale;
  vector[N_subjects] tau_raw;
}

transformed parameters {
  vector<lower=0>[N_subjects] beta = exp(beta_location + beta_scale * beta_raw);
  vector[N_subjects] tau = tau_location + tau_scale * tau_raw;

  // Utilities as a matrix: row = subject, column = item
  matrix[N_subjects, N_options] u_matrix;
  for (i in 1:N_subjects) {
    u_matrix[i] = u[i]';
  }

  // Pointwise log-likelihood (used in the model block and for LOO)
  vector[N_trials] log_lik;
  for (t in 1:N_trials) {
    int s = subject_index[t];
    vector[3] eta;
    eta[1] = beta[s] * u_matrix[s, offer_A[t]];
    eta[2] = beta[s] * u_matrix[s, offer_B[t]];
    eta[3] = beta[s] * tau[s];
    log_lik[t] = categorical_logit_lpmf(choice[t] | eta);
  }
}

model {
  // Priors
  // beta ~ lognormal(beta_location, beta_scale), written non-centered;
  // the hyperparameters are on the log scale
  beta_location ~ normal(1, 1);   // typical beta ~ exp(1) = 2.7
  beta_scale ~ normal(0, 1);      // half-normal
  beta_raw ~ std_normal();

  tau_location ~ normal(0, 2);
  tau_scale ~ normal(0, 2);       // half-normal
  tau_raw ~ std_normal();

  // Gives each utility a marginal SD of 1 under the sum-to-zero constraint;
  // this also fixes the scale of u relative to beta
  for (i in 1:N_subjects) {
    u[i] ~ normal(0, sqrt(N_options / (N_options - 1.0)));
  }

  // Likelihood
  target += sum(log_lik);
}
