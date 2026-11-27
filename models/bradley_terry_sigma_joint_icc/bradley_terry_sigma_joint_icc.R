#### MODEL: bradley_terry_sigma_joint_icc ####
# Generating code for bradley_terry_sigma_joint_icc.stan. Draws nothing except the choices
# (and the trial order): the calling study draws z, e and the population values.
#
# A unit is one participant in one session; session code c = -1/2 (session 1), +1/2 (session 2).
# Utilities: columns 1..n_options are the items, column n_options + 1 is None (= tau).

# Agreement 2 (scale), log(sigma): same line as log_sigma in the .stan transformed parameters.
#   z_subject: one standard normal per unit's participant; e_unit: one per unit.
compose_log_sigma <- function(mu, delta, s, icc, c, z_subject, e_unit) {
  mu + c * delta + s * (sqrt(icc) * z_subject + sqrt(1 - icc) * e_unit)
}

# Agreement 2 (scale), utilities: same steps as unit_utilities() in the .stan functions block.
#   sigma: per unit; c: per unit; z_u: units x K (each unit's participant row); e_u: units x K;
#   m, delta_u: sum-to-zero vectors of length K; icc_u: length K.
compose_utilities <- function(sigma, c, m, delta_u, icc_u, z_u, e_u) {
  K            <- length(m)
  centre_scale <- sqrt(K / (K - 1))
  latent       <- sweep(z_u, 2, sqrt(icc_u), `*`) + sweep(e_u, 2, sqrt(1 - icc_u), `*`)
  centred      <- (latent - rowMeans(latent)) * centre_scale
  x            <- sweep(centred, 2, m, `+`) + outer(c, delta_u)
  sigma * x
}

# Agreement 3 (choice rule): softmax over u[A], u[B], u[None], as categorical_logit in the .stan.
# Each unit sees every pair of items once, in random order and with random left/right sides.
#   params: list(units = tibble(unit, subject, session), u_all = units x (n_options + 1) matrix)
# Returns one row per trial, with the columns the .stan data block reads.
generate_bradley_terry_sigma_joint_icc <- function(params, n_options) {
  pairs   <- t(combn(n_options, 2))
  n_pairs <- nrow(pairs)
  none    <- n_options + 1

  trials <- lapply(seq_len(nrow(params$units)), \(n) {
    order  <- sample(n_pairs)
    swap   <- runif(n_pairs) < 0.5
    offer_A <- ifelse(swap, pairs[order, 2], pairs[order, 1])
    offer_B <- ifelse(swap, pairs[order, 1], pairs[order, 2])

    u   <- params$u_all[n, ]
    eta <- cbind(u[offer_A], u[offer_B], u[none])
    p   <- exp(eta - apply(eta, 1, max))
    p   <- p / rowSums(p)
    choice <- apply(p, 1, \(prob) sample(1:3, 1, prob = prob))   # 1 = A, 2 = B, 3 = None

    tibble(unit_index = n,
           subject    = params$units$subject[n],
           session    = params$units$session[n],
           trial      = seq_len(n_pairs),
           offer_A, offer_B,
           prob_A = p[, 1], prob_B = p[, 2], prob_None = p[, 3],
           choice)
  })

  bind_rows(trials)
}
