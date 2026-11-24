// Hierarchical Bradley-Terry choice model with a "None" option, without beta.
// Differs from bradley_terry_beta_tau_halfnormal_stz in two ways:
//   1. There is no inverse temperature. Choice consistency (transitivity) is
//      carried by sigma, the subject-level SD of the utilities: larger sigma ->
//      utilities further apart -> more deterministic, more transitive choices.
//   2. There is no separate tau. "None" is the (N_options + 1)-th utility, drawn
//      from the same distribution as the item utilities.
//
// On each trial a subject sees options A and B and chooses A, B, or None:
//   logit(A)    = u[A]
//   logit(B)    = u[B]
//   logit(None) = u[None]          (None = N_options + 1)
//
// u     : subject-level utilities of the N_options items and None,
//         sum to zero across all N_options + 1 within subject,
//         u_s ~ normal(0, sigma_s) (marginal SD of each utility = sigma_s)
// sigma : subject-level SD of the utilities, normal truncated at 0 across subjects
//         sigma ~ normal(sigma_location, sigma_scale) T[0, ]
//
// sigma and u are non-centered.
// Outputs for analysis (all in transformed parameters):
//   sigma, u_matrix (items only, N_subjects x N_options),
//   tau (utility of None, = u[None]), log_lik.
// Note: because None is part of the sum-to-zero vector, the item utilities in
// u_matrix sum to -tau, not to 0.

data {
  int<lower=1> N_trials;
  int<lower=1> N_subjects;
  int<lower=2> N_options;   // real items, not counting None

  array[N_trials] int<lower=1, upper=N_subjects> subject_index;
  array[N_trials] int<lower=1, upper=N_options> offer_A;
  array[N_trials] int<lower=1, upper=N_options> offer_B;
  array[N_trials] int<lower=1, upper=3> choice;   // 1 = A, 2 = B, 3 = None
}

transformed data {
  int N_utilities = N_options + 1;   // items + None
  int none_index = N_utilities;

  // Prior SD for u_raw, the non-centering helper (see the model block).
  // u_raw has SD 1 only as a sampling device; the utilities themselves are
  // u = sigma * u_raw, so their spread is sigma (estimated per subject), not 1.
  real u_raw_prior_sd = sqrt(N_utilities / (N_utilities - 1.0));
}

parameters {
  real<lower=0> sigma_location;  // mean of sigma (before truncation)
  real<lower=0> sigma_scale;     // SD of sigma (before truncation)
  vector<lower=-sigma_location / sigma_scale>[N_subjects] sigma_raw;   // lower bound keeps sigma > 0

  array[N_subjects] sum_to_zero_vector[N_utilities] u_raw;   // non-centering helper (SD 1); utilities are u = sigma * u_raw
}

transformed parameters {
  vector<lower=0>[N_subjects] sigma = sigma_location + sigma_scale * sigma_raw;

  // All utilities (items + None): row = subject, column = utility
  matrix[N_subjects, N_utilities] u_all;
  for (i in 1:N_subjects) {
    u_all[i] = sigma[i] * u_raw[i]';
  }

  // Item utilities and the None utility, split out for analysis
  matrix[N_subjects, N_options] u_matrix = u_all[:, 1:N_options];
  vector[N_subjects] tau = u_all[:, none_index];

  // Pointwise log-likelihood (used in the model block and for LOO)
  vector[N_trials] log_lik;
  for (t in 1:N_trials) {
    int s = subject_index[t];
    vector[3] eta;
    eta[1] = u_all[s, offer_A[t]];
    eta[2] = u_all[s, offer_B[t]];
    eta[3] = u_all[s, none_index];
    log_lik[t] = categorical_logit_lpmf(choice[t] | eta);
  }
}

model {
  // Priors
  // sigma ~ normal(sigma_location, sigma_scale) T[0, ], written non-centered:
  // sigma_raw is a standard normal truncated below at -sigma_location / sigma_scale.
  // The truncation's normalizing constant depends on the hyperparameters, so it
  // must be added explicitly (one term per subject).
  // sigma is the SD of the logits. Behavioral meaning: P(choose the higher of two
  // random items) is ~.73 at sigma = 1, ~.91 at 4, ~.96 at 10 (near-deterministic;
  // above ~10-15 the data barely separate sigma values).
  // sigma_location: 95% ~ [0, 11], from near-random to near-deterministic choosers.
  // sigma_scale: allows between-subject SDs up to ~6 (beta model fits gave ~3).
  // Truncated normal rather than lognormal: implied sigma in the beta-model fits
  // is left-skewed (long low tail, ceiling ~11); a lognormal would over-shrink
  // the least consistent subjects.
  sigma_location ~ normal(5, 3);
  sigma_scale ~ normal(0, 3);        // half-normal
  sigma_raw ~ std_normal();
  target += -N_subjects * normal_lccdf(0 | sigma_location, sigma_scale);

  // u_raw: marginal SD of exactly 1 each, so u = sigma * u_raw
  // has marginal SD sigma. Why u_raw_prior_sd = sqrt(K / (K - 1)) and not 1:
  // forcing K values to sum to zero shrinks each one's marginal SD by
  // sqrt((K - 1) / K); scaling the prior SD up by the inverse undoes that
  // (as in the Stan User's Guide). Here K = N_options + 1 (items + None).
  // No beta multiplies u, so the scale of u is identified by the likelihood;
  // sum-to-zero fixes the location (softmax is invariant to shifting all utilities).
  for (i in 1:N_subjects) {
    u_raw[i] ~ normal(0, u_raw_prior_sd);
  }

  // Likelihood
  target += sum(log_lik);
}
