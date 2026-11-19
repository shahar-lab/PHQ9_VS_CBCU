// Hierarchical Bradley-Terry choice model with a "None" option.
// Same as bradley_terry_beta_tau_lognormal_stz, except that beta is not lognormal:
// its population distribution is a normal truncated at 0,
//   beta ~ normal(beta_location, beta_scale) T[0, ]
// with beta_location ~ normal(4, 0.9) and beta_scale ~ half-normal(0, 1.1).
//
// On each trial a subject sees options A and B and chooses A, B, or None:
//   logit(A)    = beta * u[A]
//   logit(B)    = beta * u[B]
//   logit(None) = beta * tau
//
// u    : subject-level item utilities, sum to zero within subject
// beta : inverse temperature, normal truncated at 0 across subjects (beta > 0)
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

transformed data {
  // Prior SD for the sum-to-zero utilities (see the u prior in the model block)
  real u_prior_sd = sqrt(N_options / (N_options - 1.0));
}

parameters {
  array[N_subjects] sum_to_zero_vector[N_options] u;   // utilities per subject

  real<lower=0> beta_location;  // mean of beta (before truncation), on the beta scale
  real<lower=0> beta_scale;     // SD of beta (before truncation), on the beta scale
  vector<lower=-beta_location / beta_scale>[N_subjects] beta_raw;   // lower bound keeps beta > 0

  real tau_location;
  real<lower=0> tau_scale;
  vector[N_subjects] tau_raw;
}

transformed parameters {
  vector<lower=0>[N_subjects] beta = beta_location + beta_scale * beta_raw;
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
  // beta ~ normal(beta_location, beta_scale) T[0, ], written non-centered:
  // beta_raw is a standard normal truncated below at -beta_location / beta_scale.
  // The truncation's normalizing constant depends on the hyperparameters, so it
  // must be added explicitly (one term per subject).
  beta_location ~ normal(4, 0.9);   // typical beta ~ 4; lower=0 cuts off < 0.001% of this prior
  beta_scale ~ normal(0, 1.1);      // half-normal
  beta_raw ~ std_normal();
  target += -N_subjects * normal_lccdf(0 | beta_location, beta_scale);

  tau_location ~ normal(0, 1.5);
  tau_scale ~ normal(0, 1.5);       // half-normal
  tau_raw ~ std_normal();

  // Utility prior: needed for identification, not just regularization.
  // The likelihood only sees beta * u and beta * tau, so scaling u and tau
  // by c and beta by 1/c leaves it unchanged. Sum-to-zero fixes the mean of
  // u but not its spread; this prior fixes the spread (SD ~1), and with it
  // the scale of beta.
  // Why u_prior_sd = sqrt(N / (N - 1)) and not 1: forcing N values to sum to
  // zero shrinks each one's marginal SD by sqrt((N - 1) / N). Scaling the
  // prior SD up by the inverse gives each utility a marginal SD of exactly 1
  // (as in the Stan User's Guide).
  for (i in 1:N_subjects) {
    u[i] ~ normal(0, u_prior_sd);
  }

  // Likelihood
  target += sum(log_lik);
}
