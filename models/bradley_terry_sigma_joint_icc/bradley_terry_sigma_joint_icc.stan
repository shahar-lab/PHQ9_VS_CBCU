// Joint test-retest Bradley-Terry sigma model: both sessions in one fit, ICCs as parameters.
//
// Choice: on each trial, A vs B vs None, softmax over (u[A], u[B], u[None]); None = utility 16 (tau).
// Unit = participant i in session j; c_j = -1/2, +1/2, so delta = session 2 - session 1.
//
// sigma (choice consistency), on the log scale:
//   log sigma_ij = mu + c_j*delta + s*( sqrt(ICC_sigma)*z_i + sqrt(1 - ICC_sigma)*e_ij )
//   z_i = stable person part, e_ij = session-specific part (both N(0,1)); ICC_sigma = z share.
//
// Utilities, k = 1..16 (15 items + None):
//   x_ijk = m_k + c_j*delta_k + centred( sqrt(ICC_k)*z_ik + sqrt(1 - ICC_k)*e_ijk ),  u_ij = sigma_ij * x_ij
//   ICC_k = ICC_profile for the 15 items (pooled, Hypothesis 1 eq. [1]); ICC_tau for None.
//   SD of each x across people fixed at 1, so sigma is the only scale (identification).
//
// Free parameters are consistency ICCs. Agreement ICCs (McGraw & Wong ICC(A,1)) are derived:
//   ICC_A_sigma   = ICC_sigma * s^2 / (s^2 + delta^2/2)
//   ICC_profile_A = ICC_profile / (1 + mean(delta_k^2)/2)        <- Hypothesis 1, eq. [2]
//   ICC_A_tau     = ICC_tau / (1 + delta_None^2/2)

functions {
  // Utilities: rows = units, columns = 15 items + None.
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
  real stz_sd = sqrt(K / (K - 1.0));             // gives each sum-to-zero element SD 1
  vector[N_units] c;                             // session code -1/2, +1/2
  for (n in 1:N_units) c[n] = unit_session[n] - 1.5;

  // Index of each trial's A, B, None and chosen option in to_vector(u) (for a fast likelihood)
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
  real mu_log_sigma;                             // mean over sessions
  real<lower=0> s_log_sigma;                     // SD across people within a session
  real delta_log_sigma;                          // session 2 - session 1
  real<lower=0, upper=1> icc_sigma;              // consistency ICC
  vector[N_subjects] z_sigma;                    // person part
  vector[N_units] e_sigma;                       // session part

  // utilities (items + None)
  sum_to_zero_vector[K] m;                       // population mean per utility
  sum_to_zero_vector[K] delta_u;                 // session shift per utility
  real<lower=0, upper=1> icc_profile_C;          // consistency ICC, shared by the 15 items
  real<lower=0, upper=1> icc_tau;                // consistency ICC of None
  matrix[N_subjects, K] z_u;                     // person part
  matrix[N_units, K] e_u;                        // session part
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

  // Priors
  mu_log_sigma    ~ normal(1.6, 0.75);           // median sigma ~ exp(1.6) = 5
  s_log_sigma     ~ normal(0, 1);                // half-normal
  delta_log_sigma ~ normal(0, 0.5);
  icc_sigma       ~ beta(1, 1);                  // uniform on [0, 1]
  icc_profile_C   ~ beta(1, 1);
  icc_tau         ~ beta(1, 1);
  m               ~ normal(0, 1 * stz_sd);       // SD 1 per utility
  delta_u         ~ normal(0, 0.5 * stz_sd);     // SD 0.5 per utility
  z_sigma ~ std_normal();
  e_sigma ~ std_normal();
  to_vector(z_u) ~ std_normal();
  to_vector(e_u) ~ std_normal();

  // Likelihood: log P(choice) = u[chosen] - log(exp(u[A]) + exp(u[B]) + exp(u[None]))
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

  // Agreement ICCs
  real icc_A_sigma   = icc_sigma * square(s_log_sigma)
                       / (square(s_log_sigma) + square(delta_log_sigma) / 2);
  real icc_profile_A = icc_profile_C / (1 + mean(square(delta_u[1:N_options])) / 2);   // eq. [2]
  real icc_A_tau     = icc_tau / (1 + square(delta_u[K]) / 2);
}
