data {
  int<lower=1> N_trials;     // Total number of trials
  int<lower=1> N_subjects;   // Number of unique subjects
  int<lower=1> N_options;    // Number of available options (symptoms)

  array[N_trials] int<lower=1, upper=N_subjects> subject; // Subject ID for each trial
  array[N_trials] int<lower=1, upper=N_options> offer_A;  // Option A ID
  array[N_trials] int<lower=1, upper=N_options> offer_B;  // Option B ID
  
  // NEW: Choice must now track 3 possible states (1 = A, 2 = B, 3 = None)
  array[N_trials] int<lower=1, upper=3> choice; 
}

parameters {
  // Raw, unconstrained utility parameters
  matrix[N_subjects, N_options] u_raw;

  // Group-level beta parameters
  real mu_log_beta;
  real<lower=0> sigma_log_beta;

  // Subject-level betas
  vector<lower=0>[N_subjects] beta;

  // NEW: Group-level tau (Burden Threshold) parameters
  real mu_tau;
  real<lower=0> sigma_tau;
  
  // NEW: Subject-level taus
  vector[N_subjects] tau;
}

transformed parameters {
  // Constrained utilities
  matrix[N_subjects, N_options] u_matrix;
  
  // Hard constraint: Force mean = 0 and variance = 1 for each subject
  for (i in 1:N_subjects) {
    real mu_u = mean(to_vector(u_raw[i, ]));
    real sd_u = sd(to_vector(u_raw[i, ]));
    
    // Standardize the raw parameters
    u_matrix[i, ] = (u_raw[i, ] - mu_u) / sd_u; 
  }
}

model {
  // Hierarchical priors for beta
  mu_log_beta ~ normal(0, 2);
  sigma_log_beta ~ exponential(2);
  beta ~ lognormal(mu_log_beta, sigma_log_beta);

  // NEW: Hierarchical priors for tau
  mu_tau ~ normal(0, 2);
  sigma_tau ~ exponential(2);
  tau ~ normal(mu_tau, sigma_tau);

  // Weak prior on u_raw to provide initial geometry before transformation
  to_vector(u_raw) ~ normal(0, 1);
  
  // Likelihood function
  for (t in 1:N_trials) {
    // NEW: Build the 3-way log-weights for the decoupled Softmax
    vector[3] log_weights;
    
    // Weight for Option A (Temperature * Utility)
    log_weights[1] = beta[subject[t]] * u_matrix[subject[t], offer_A[t]];
    
    // Weight for Option B (Temperature * Utility)
    log_weights[2] = beta[subject[t]] * u_matrix[subject[t], offer_B[t]];
    
    // Weight for None (The independent Burden Threshold)
    log_weights[3] = tau[subject[t]];
    
    // Evaluate the choice using categorical_logit
    choice[t] ~ categorical_logit(log_weights);
  }
}

generated quantities {
  // Pointwise log-likelihood per trial, for LOO model comparison
  vector[N_trials] log_lik;

  for (t in 1:N_trials) {
    vector[3] log_weights;

    log_weights[1] = beta[subject[t]] * u_matrix[subject[t], offer_A[t]];
    log_weights[2] = beta[subject[t]] * u_matrix[subject[t], offer_B[t]];
    log_weights[3] = tau[subject[t]];

    log_lik[t] = categorical_logit_lpmf(choice[t] | log_weights);
  }
}
