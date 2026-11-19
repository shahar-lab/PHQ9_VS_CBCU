// Hierarchical Bradley-Terry choice model with a "None" option, fit to BOTH sessions at
// once, with the test-retest model for log(beta) (Hypothesis 2, eq. [3]) built in.
//
// Same choice rule as bradley_terry_beta_tau_lognormal_stz.stan. On each trial a
// participant sees options A and B and chooses A, B, or None:
//   logit(A)    = beta * u[A]
//   logit(B)    = beta * u[B]
//   logit(None) = beta * tau
//
// A "unit" is one participant in one session. Each unit has its own u, beta and tau.
//
// beta (test-retest model, eq. [3]):
//   log(beta_ij) = b_0 + b_0i + e_ij
//   b_0i ~ Normal(0, sigma_b^2)   participant i, shared by both sessions (between-subject)
//   e_ij ~ Normal(0, sigma_e^2)   participant i in session j (within-subject)
//   ICC = sigma_b^2 / (sigma_b^2 + sigma_e^2)   (eq. [4], in generated quantities)
// No session effect: a shift shared by everyone in session 2 goes into e (absolute agreement).
// Because beta is estimated inside this model, its uncertainty is accounted for directly.
//
// tau: separate hierarchical model per session (own location and scale), as in the
//      per-session fits.
// u:   sum to zero within each unit, same prior as in the per-session fits.
//
// b_0i and e are non-centered. No log_lik output, to keep the output files small.

data {
  int<lower=1> N_trials;
  int<lower=1> N_subjects;                  // participants
  int<lower=1> N_sessions;
  int<lower=1> N_units;                     // participant x session pairs with data
  int<lower=2> N_options;

  array[N_units] int<lower=1, upper=N_subjects> unit_subject;
  array[N_units] int<lower=1, upper=N_sessions> unit_session;

  array[N_trials] int<lower=1, upper=N_units> unit_index;
  array[N_trials] int<lower=1, upper=N_options> offer_A;
  array[N_trials] int<lower=1, upper=N_options> offer_B;
  array[N_trials] int<lower=1, upper=3> choice;   // 1 = A, 2 = B, 3 = None
}

transformed data {
  // Prior SD for the sum-to-zero utilities (see the u prior in the model block)
  real u_prior_sd = sqrt(N_options / (N_options - 1.0));
}

parameters {
  array[N_units] sum_to_zero_vector[N_options] u;   // utilities per unit

  real b_0;                       // population mean of log(beta)
  real<lower=0> sigma_b;          // between-subject SD of log(beta)
  real<lower=0> sigma_e;          // within-subject SD of log(beta)
  vector[N_subjects] b_0i_raw;
  vector[N_units] e_raw;

  vector[N_sessions] tau_location;
  vector<lower=0>[N_sessions] tau_scale;
  vector[N_units] tau_raw;
}

transformed parameters {
  vector[N_units] log_beta = b_0 + sigma_b * b_0i_raw[unit_subject] + sigma_e * e_raw;
  vector<lower=0>[N_units] beta = exp(log_beta);
  vector[N_units] tau = tau_location[unit_session] + tau_scale[unit_session] .* tau_raw;
}

model {
  // Priors, log(beta) scale. b_0 has the same prior as beta_location in the
  // per-session model; sigma_b and sigma_e each get the beta_scale prior.
  b_0 ~ normal(2, 0.75);            // typical beta ~ exp(2) = 7.39
  sigma_b ~ normal(0, 0.5);         // half-normal
  sigma_e ~ normal(0, 0.5);         // half-normal
  b_0i_raw ~ std_normal();
  e_raw ~ std_normal();

  tau_location ~ normal(0, 1.5);
  tau_scale ~ normal(0, 1.5);       // half-normal
  tau_raw ~ std_normal();

  // Utility prior: needed for identification (it fixes the spread of u, and with it the
  // scale of beta). See bradley_terry_beta_tau_lognormal_stz.stan for the derivation.
  for (k in 1:N_units) {
    u[k] ~ normal(0, u_prior_sd);
  }

  // Likelihood
  for (t in 1:N_trials) {
    int k = unit_index[t];
    vector[3] eta = beta[k] * [u[k][offer_A[t]], u[k][offer_B[t]], tau[k]]';
    choice[t] ~ categorical_logit(eta);
  }
}

generated quantities {
  real icc_beta = square(sigma_b) / (square(sigma_b) + square(sigma_e));
}
