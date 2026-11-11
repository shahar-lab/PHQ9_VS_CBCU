// Hierarchical Bradley-Terry choice model with a "None" option, no perseveration.
// Same as bradley_terry_beta_tau_rho_noncentered with rho removed.
//
// On each trial a subject sees two options (A, B) and chooses A, B, or None:
//   logit(A)    = beta * u[A]
//   logit(B)    = beta * u[B]
//   logit(None) = beta * tau
//
// u: subject-level utilities, standardized to mean 0, SD 1 per subject
// beta: inverse temperature (> 0); population distribution is normal(beta_location, beta_scale)
//       truncated at 0, which also fixes the sign of u and tau
// tau: threshold for choosing None, on the utility scale
//
// Subject-level parameters are non-centered.

data {
  int<lower=1> N_trials;
  int<lower=1> N_subjects;
  int<lower=1> N_options;

  array[N_trials] int<lower=1, upper=N_subjects> subject_index;
  array[N_trials] int<lower=1, upper=N_options> offer_A;
  array[N_trials] int<lower=1, upper=N_options> offer_B;
  array[N_trials] int<lower=1, upper=3> choice;                 // 1 = A, 2 = B, 3 = None
}

parameters {
  matrix[N_subjects, N_options] u_raw;

  real<lower=0> beta_location;
  real<lower=0> beta_scale;
  vector<lower=-beta_location / beta_scale>[N_subjects] beta_raw;  // lower bound keeps beta > 0

  real tau_location;
  real<lower=0> tau_scale;
  vector[N_subjects] tau_raw;
}

transformed parameters {
  vector<lower=0>[N_subjects] beta = beta_location + beta_scale * beta_raw;
  vector[N_subjects] tau = tau_location + tau_scale * tau_raw;

  matrix[N_subjects, N_options] u_matrix;

  // Standardize utilities within subject (identifies the utility scale)
  for (i in 1:N_subjects) {
    real mu_u = mean(to_vector(u_raw[i, ]));
    real sd_u = sd(to_vector(u_raw[i, ]));

    u_matrix[i, ] = (u_raw[i, ] - mu_u) / sd_u;
  }

  // Pointwise log-likelihood: used by the model block and saved for LOO
  vector[N_trials] log_lik;

  for (t in 1:N_trials) {
    vector[3] log_weights;

    log_weights[1] = beta[subject_index[t]] * u_matrix[subject_index[t], offer_A[t]];
    log_weights[2] = beta[subject_index[t]] * u_matrix[subject_index[t], offer_B[t]];
    log_weights[3] = beta[subject_index[t]] * tau[subject_index[t]];

    log_lik[t] = categorical_logit_lpmf(choice[t] | log_weights);
  }
}

model {
  // Priors
  beta_location ~ normal(0, 3);  // half-normal via lower=0
  beta_scale ~ normal(0, 2);  // half-normal via lower=0
  // beta ~ normal(beta_location, beta_scale) T[0, ], written on the raw scale;
  // the truncation normalizer depends on the hyperparameters, so it must be added
  beta_raw ~ std_normal();
  target += -N_subjects * normal_lccdf(0 | beta_location, beta_scale);

  tau_location ~ normal(0, 2);
  tau_scale ~ normal(0, 2);  // half-normal via lower=0
  tau_raw ~ std_normal();

  to_vector(u_raw) ~ normal(0, 1);

  // Likelihood
  target += sum(log_lik);
}
