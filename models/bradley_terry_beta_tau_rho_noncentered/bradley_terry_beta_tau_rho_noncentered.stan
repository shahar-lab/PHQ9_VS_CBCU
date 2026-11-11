// Hierarchical Bradley-Terry choice model with a "None" option and one-trial perseveration.
//
// On each trial a subject sees two options (A, B) and chooses A, B, or None:
//   logit(A)    = beta * u[A]  + rho * (A chosen on previous trial)
//   logit(B)    = beta * u[B]  + rho * (B chosen on previous trial)
//   logit(None) = beta * tau   + rho * (None chosen on previous trial)
//
// u: subject-level utilities, standardized to mean 0, SD 1 per subject
// beta: inverse temperature (> 0); population distribution is normal(beta_location, beta_scale)
//       truncated at 0, which also fixes the sign of u and tau
// tau: threshold for choosing None, on the utility scale
// rho: perseveration bonus for repeating the previous response
//
// Subject-level parameters are non-centered. Trials must be ordered
// chronologically within each subject.

data {
  int<lower=1> N_trials;
  int<lower=1> N_subjects;
  int<lower=1> N_options;

  array[N_trials] int<lower=1, upper=N_subjects> subject_index;
  array[N_trials] int<lower=1, upper=N_options> offer_A;
  array[N_trials] int<lower=1, upper=N_options> offer_B;
  array[N_trials] int<lower=1, upper=3> choice;                 // 1 = A, 2 = B, 3 = None
  array[N_trials] int<lower=0, upper=1> first_trial_of_subject; // 1 on each subject's first trial
}

parameters {
  matrix[N_subjects, N_options] u_raw;

  real<lower=0> beta_location;
  real<lower=0> beta_scale;
  vector<lower=-beta_location / beta_scale>[N_subjects] beta_raw;  // lower bound keeps beta > 0

  real tau_location;
  real<lower=0> tau_scale;
  vector[N_subjects] tau_raw;

  real rho_location;
  real<lower=0> rho_scale;
  vector[N_subjects] rho_raw;
}

transformed parameters {
  vector<lower=0>[N_subjects] beta = beta_location + beta_scale * beta_raw;
  vector[N_subjects] tau = tau_location + tau_scale * tau_raw;
  vector[N_subjects] rho = rho_location + rho_scale * rho_raw;

  matrix[N_subjects, N_options] u_matrix;
  matrix[N_trials, 3] key_contrib;  // perseveration bonus per trial and response (A, B, None)

  // Standardize utilities within subject (identifies the utility scale)
  for (i in 1:N_subjects) {
    real mu_u = mean(to_vector(u_raw[i, ]));
    real sd_u = sd(to_vector(u_raw[i, ]));

    u_matrix[i, ] = (u_raw[i, ] - mu_u) / sd_u;
  }

  // Perseveration: only the previous trial's response gets rho; reset at each subject's first trial
  {
    vector[3] key_value = rep_vector(0, 3);

    for (t in 1:N_trials) {
      if (first_trial_of_subject[t] == 1) {
        key_value = rep_vector(0, 3);
      }

      key_contrib[t, 1] = key_value[1];
      key_contrib[t, 2] = key_value[2];
      key_contrib[t, 3] = key_value[3];

      key_value = rep_vector(0, 3);
      key_value[choice[t]] += rho[subject_index[t]];
    }
  }

  // Pointwise log-likelihood: used by the model block and saved for LOO
  vector[N_trials] log_lik;

  for (t in 1:N_trials) {
    vector[3] log_weights;

    log_weights[1] = beta[subject_index[t]] * u_matrix[subject_index[t], offer_A[t]] + key_contrib[t, 1];
    log_weights[2] = beta[subject_index[t]] * u_matrix[subject_index[t], offer_B[t]] + key_contrib[t, 2];
    log_weights[3] = beta[subject_index[t]] * tau[subject_index[t]] + key_contrib[t, 3];

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

  rho_location ~ normal(0, 3);
  rho_scale ~ normal(0, 2);  // half-normal via lower=0
  rho_raw ~ std_normal();

  to_vector(u_raw) ~ normal(0, 1);

  // Likelihood
  target += sum(log_lik);
}
