#### SIMULATE NEW CHOICE SEQUENCES FROM THE POSTERIOR ####
# Replays every participant-session's 105 trials (same item pairs, same order) once per posterior draw,
# using the model's own choice rule, including the perseveration update. The perseveration update uses
# the SIMULATED choices (full-sequence simulation), not the observed ones.
#
# Vectorised over (draw x subject); the loop runs over trial position only.

simulate_choices <- function(par, left, right) {
  n_draws    <- nrow(par$beta)
  n_subjects <- ncol(par$beta)
  n_trials   <- ncol(left)
  n_cells    <- n_draws * n_subjects

  # Cell index: draw varies fastest, so as.vector() of a draws x subjects matrix lines up with these
  d_idx <- rep(seq_len(n_draws), times = n_subjects)
  s_idx <- rep(seq_len(n_subjects), each = n_draws)

  beta  <- as.vector(par$beta)
  tau   <- as.vector(par$tau)
  rho   <- as.vector(par$rho)
  decay <- as.vector(par$decay)

  # Perseveration state per outcome slot (A, B, None); starts at zero for every participant-session
  kv_A <- kv_B <- kv_N <- numeric(n_cells)

  choice_sim <- array(NA_integer_, dim = c(n_draws, n_subjects, n_trials))

  for (t in seq_len(n_trials)) {
    u_A <- par$U[cbind(d_idx, s_idx, left[s_idx, t])]
    u_B <- par$U[cbind(d_idx, s_idx, right[s_idx, t])]

    # Log-weights exactly as in the Stan models (key_value is 0 when there is no perseveration)
    w_A <- beta * u_A + kv_A
    w_B <- beta * u_B + kv_B
    w_N <- tau + kv_N

    m   <- pmax(w_A, w_B, w_N)
    e_A <- exp(w_A - m)
    e_B <- exp(w_B - m)
    e_N <- exp(w_N - m)

    r      <- runif(n_cells) * (e_A + e_B + e_N)
    choice <- 1L + (r > e_A) + (r > e_A + e_B)

    choice_sim[cbind(d_idx, s_idx, t)] <- choice

    # Decay first, then bump the slot just chosen (Stan: key_value * key_decay, then += rho)
    kv_A <- kv_A * decay + rho * (choice == 1L)
    kv_B <- kv_B * decay + rho * (choice == 2L)
    kv_N <- kv_N * decay + rho * (choice == 3L)
  }

  choice_sim
}

sim_choices <- map(names(draws_by_model), \(m) {
  map(waves, \(w) simulate_choices(draws_by_model[[m]][[w]], obs_data[[w]]$left, obs_data[[w]]$right)) |>
    setNames(waves)
}) |> setNames(names(draws_by_model))
