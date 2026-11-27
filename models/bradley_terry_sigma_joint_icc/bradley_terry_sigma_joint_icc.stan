// MODEL: bradley_terry_sigma_joint_icc
// Bradley-Terry sigma model (no beta; None is the 16th utility) fit to BOTH sessions at once,
// with the test-retest structure built in and the ICCs as free parameters.
//
// Choice rule (same as bradley_terry_sigma.stan). On each trial a unit sees items A and B and
// chooses A, B or None:
//   logit(A) = u[A],  logit(B) = u[B],  logit(None) = u[None]   (None = utility K = N_options + 1)
//
// A unit is one participant in one session. Session code c = -1/2 (session 1), +1/2 (session 2),
// so a shift delta is "session 2 - session 1" and the location is the mean over sessions.
//
// Consistency, log scale (agreement 2: the .R file builds log_sigma the same way):
//   log_sigma_ij = mu + c_j * delta + s * ( sqrt(icc_sigma) * z_i + sqrt(1 - icc_sigma) * e_ij )
//   s = total SD of log_sigma within a session; icc_sigma = consistency ICC = between / total.
//
// Utilities (k = 1..K, K = 16, k = 16 is None = tau). Pooled over the 15 items (Hypothesis 1,
// eq. [1]: the same variance components for every item); None has its own ICC:
//   icc_k = icc_profile_C for the 15 items, icc_tau for None
//   x_ijk = m_k + c_j * delta_k + sqrt(K / (K - 1)) * centred_k( sqrt(icc_k) z_ik + sqrt(1 - icc_k) e_ijk )
//   u_ij  = sigma_ij * x_ij
//   Centring over k keeps the utilities sum-to-zero (softmax ignores a shift of all K); the
//   factor sqrt(K / (K - 1)) restores a marginal SD of 1 per utility. That SD is fixed at 1 (not
//   estimated): sigma and the spread of x would otherwise trade off (sigma * x = (2 sigma) * (x / 2)).
//   So sigma = the spread of a unit's utilities around the population item means m.
//   m and delta_u are sum-to-zero for the same reason.
//
// Mapping to eq. [1] (per item, in units of x): participant x item variance = icc_profile_C,
// residual = 1 - icc_profile_C, occasion x item variance = mean(delta_u[items]^2) / 2
// (two occasions at -+ delta_k / 2). icc_profile_C, icc_tau, icc_sigma are consistency ICCs.
// Agreement ICCs (McGraw & Wong ICC(A,1), session shift counted as disagreement), in generated
// quantities; icc_profile_A is eq. [2]:
//   icc_A_sigma   = icc_sigma * s^2 / (s^2 + delta^2 / 2)
//   icc_profile_A = icc_profile_C / (1 + mean(delta_u[items]^2) / 2)
//   icc_A_tau     = icc_tau / (1 + delta_u[K]^2 / 2)
// The ICCs are defined on the latent values before centring; centring over 16 mixes the
// utilities slightly (the centred ICC is ((K - 2) icc_k + mean(icc)) / (K - 1)).
//
// No log_lik output, to keep the output files small.

functions {
  // Utilities of every unit (row) for every option incl. None (column). Same steps as compose_utilities() in the .R file.
  matrix unit_utilities(vector sigma, vector c, array[] int unit_subject,
                        vector m, vector delta_u, vector icc_u,
                        matrix z_u, matrix e_u) {
    int N_units = rows(e_u);
    int K = cols(e_u);
    real centre_scale = sqrt(K / (K - 1.0));
    matrix[N_units, K] latent = diag_post_multiply(z_u[unit_subject], sqrt(icc_u))
                                + diag_post_multiply(e_u, sqrt(1 - icc_u));
    vector[N_units] latent_mean = latent * rep_vector(1.0 / K, K);
    matrix[N_units, K] x = rep_matrix(m', N_units) + c * delta_u'
                           + centre_scale * (latent - rep_matrix(latent_mean, K));
    return diag_pre_multiply(sigma, x);
  }
}

data {
  int<lower=1> N_trials;
  int<lower=1> N_subjects;
  int<lower=2, upper=2> N_sessions;              // the c = -1/2, +1/2 coding assumes two sessions
  int<lower=1> N_units;                          // participant x session pairs with data
  int<lower=2> N_options;                        // real items, not counting None

  array[N_units] int<lower=1, upper=N_subjects> unit_subject;
  array[N_units] int<lower=1, upper=N_sessions> unit_session;

  array[N_trials] int<lower=1, upper=N_units> unit_index;
  array[N_trials] int<lower=1, upper=N_options> offer_A;
  array[N_trials] int<lower=1, upper=N_options> offer_B;
  array[N_trials] int<lower=1, upper=3> choice;  // 1 = A, 2 = B, 3 = None
}

transformed data {
  int K = N_options + 1;                         // items + None
  real stz_sd = sqrt(K / (K - 1.0));             // prior SD giving a sum-to-zero vector marginal SD 1
  vector[N_units] c;
  for (n in 1:N_units) c[n] = unit_session[n] - 1.5;

  // Positions in to_vector(u) (column-major: row n, column k -> (k - 1) * N_units + n) of the
  // three options on each trial and of the chosen one, for the vectorised likelihood.
  array[N_trials] int pos_A;
  array[N_trials] int pos_B;
  array[N_trials] int pos_None;
  array[N_trials] int pos_chosen;
  for (t in 1:N_trials) {
    pos_A[t]    = (offer_A[t] - 1) * N_units + unit_index[t];
    pos_B[t]    = (offer_B[t] - 1) * N_units + unit_index[t];
    pos_None[t] = (K - 1) * N_units + unit_index[t];
    pos_chosen[t] = choice[t] == 1 ? pos_A[t] : (choice[t] == 2 ? pos_B[t] : pos_None[t]);
  }
}

parameters {
  // log(sigma)
  real mu_log_sigma;
  real<lower=0> s_log_sigma;
  real delta_log_sigma;
  real<lower=0, upper=1> icc_sigma;
  vector[N_subjects] z_sigma;
  vector[N_units] e_sigma;

  // utilities (items + None)
  sum_to_zero_vector[K] m;                       // population mean per utility
  sum_to_zero_vector[K] delta_u;                 // session shift per utility
  real<lower=0, upper=1> icc_profile_C;          // shared by the 15 items
  real<lower=0, upper=1> icc_tau;                // None
  matrix[N_subjects, K] z_u;
  matrix[N_units, K] e_u;
}

transformed parameters {
  vector[N_units] log_sigma = mu_log_sigma + c * delta_log_sigma
                              + s_log_sigma * (sqrt(icc_sigma) * z_sigma[unit_subject]
                                               + sqrt(1 - icc_sigma) * e_sigma);
  vector<lower=0>[N_units] sigma = exp(log_sigma);
}

model {
  vector[K] icc_u = append_row(rep_vector(icc_profile_C, N_options), icc_tau);
  matrix[N_units, K] u = unit_utilities(sigma, c, unit_subject, m, delta_u, icc_u, z_u, e_u);

  // Priors (approved)
  mu_log_sigma    ~ normal(1.6, 0.75);           // median sigma ~ exp(1.6) = 5
  s_log_sigma     ~ normal(0, 1);                // half-normal
  delta_log_sigma ~ normal(0, 0.5);
  icc_sigma       ~ beta(1, 1);
  icc_profile_C   ~ beta(1, 1);
  icc_tau         ~ beta(1, 1);
  m               ~ normal(0, 1 * stz_sd);       // marginal SD 1 per utility
  delta_u         ~ normal(0, 0.5 * stz_sd);     // marginal SD 0.5 per utility
  z_sigma ~ std_normal();
  e_sigma ~ std_normal();
  to_vector(z_u) ~ std_normal();
  to_vector(e_u) ~ std_normal();

  // Likelihood (agreement 3: same softmax over A, B, None as the .R generating function)
  // log P(choice) = u[chosen] - log(exp(u[A]) + exp(u[B]) + exp(u[None])), all trials at once
  {
    vector[N_units * K] u_flat = to_vector(u);
    target += sum(u_flat[pos_chosen])
              - sum(log_sum_exp(u_flat[pos_A], log_sum_exp(u_flat[pos_B], u_flat[pos_None])));
  }
}

generated quantities {
  vector[K] icc_u = append_row(rep_vector(icc_profile_C, N_options), icc_tau);
  matrix[N_units, K] u_all = unit_utilities(sigma, c, unit_subject, m, delta_u, icc_u, z_u, e_u);
  vector[N_units] tau = u_all[:, K];

  real icc_A_sigma   = icc_sigma * square(s_log_sigma)
                       / (square(s_log_sigma) + square(delta_log_sigma) / 2);
  real icc_profile_A = icc_profile_C / (1 + mean(square(delta_u[1:N_options])) / 2);   // eq. [2]
  real icc_A_tau     = icc_tau / (1 + square(delta_u[K]) / 2);
}
