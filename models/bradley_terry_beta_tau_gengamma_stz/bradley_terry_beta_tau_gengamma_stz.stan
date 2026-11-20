// Hierarchical Bradley-Terry choice model with a "None" option.
// Same as bradley_terry_beta_tau_halfnormal_stz, except that beta has a
// generalized gamma population distribution, which can have a left tail:
//
//   log(beta) = beta_mu + beta_sigma * z
//   z = (log(G) - digamma(k)) / sqrt(trigamma(k)),   G ~ gamma(k, 1),   k = 1 / beta_Q^2
//
// z is a standardized log-gamma variable: mean 0, SD 1, skewed to the left. So:
//   beta_mu    = mean of log(beta)
//   beta_sigma = SD of log(beta)
//   beta_Q     = shape only (how long the left tail of log(beta) is):
//                Q -> 0  : z -> standard normal, i.e. beta is lognormal
//                          (as in bradley_terry_beta_tau_lognormal_stz)
//                Q = 1   : beta is Weibull
//                Q > 1   : longer left tail (skewness of log(beta) goes towards -2)
// This is the Prentice (1974) generalized gamma, re-parameterized so that mu and sigma
// keep the same meaning for every Q. Q is estimated, so the posterior of beta_Q tests
// whether the population of beta has a left tail beyond the lognormal.
//
// On each trial a subject sees options A and B and chooses A, B, or None:
//   logit(A)    = beta * u[A]
//   logit(B)    = beta * u[B]
//   logit(None) = beta * tau
//
// u    : subject-level item utilities, sum to zero within subject
// beta : inverse temperature, generalized gamma across subjects (beta > 0)
// tau  : threshold for choosing None, on the utility scale
//
// beta and tau are non-centered.
// Outputs for analysis: beta, tau, u_matrix, log_lik (transformed parameters),
// beta_new (generated quantities).

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

  real beta_mu;                       // mean of log(beta)
  real<lower=0> beta_sigma;           // SD of log(beta)
  real<lower=0.2, upper=3> beta_Q;    // shape of the left tail (see header)
  vector[N_subjects] beta_raw;        // log(G), G ~ gamma(beta_k, 1); no bounds needed

  real tau_location;
  real<lower=0> tau_scale;
  vector[N_subjects] tau_raw;
}

transformed parameters {
  real beta_k = 1 / square(beta_Q);   // gamma shape implied by Q

  // Non-centered: standardize log(G) to mean 0, SD 1, then shift and scale.
  // beta = exp(...) is positive by construction, so no truncation is needed.
  vector<lower=0>[N_subjects] beta
    = exp(beta_mu + beta_sigma * (beta_raw - digamma(beta_k)) / sqrt(trigamma(beta_k)));
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
  // Population of beta. Because mu and sigma are the mean and SD of log(beta) for
  // every Q, these are on the same scale as the lognormal models' hyperpriors
  // (lognormal_stz_v2: normal(1.25, 0.25), half-normal(0, 0.35)), but wider, so the
  // data can move the population. Check with code/prior_predictive_beta.R.
  beta_mu ~ normal(1.4, 0.3);         // exp(1.4) ~ 4, the typical beta in earlier fits
  beta_sigma ~ normal(0, 0.4);        // half-normal
  beta_Q ~ normal(1, 0.6);            // truncated to [0.2, 3] by the bounds (constant, no correction)

  // beta_raw = log(G), G ~ gamma(beta_k, 1). Its log density is
  //   k * x - exp(x) - lgamma(k).
  // lgamma(k) depends on beta_Q, so it must be kept (one term per subject).
  target += beta_k * sum(beta_raw) - sum(exp(beta_raw)) - N_subjects * lgamma(beta_k);

  tau_location ~ normal(0, 1.5);
  tau_scale ~ normal(0, 1.5);         // half-normal
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

generated quantities {
  // beta for a new subject drawn from the population distribution
  // (the population prior to carry into a single-subject model)
  real beta_new = exp(beta_mu + beta_sigma * (log(gamma_rng(beta_k, 1)) - digamma(beta_k))
                                             / sqrt(trigamma(beta_k)));
}
