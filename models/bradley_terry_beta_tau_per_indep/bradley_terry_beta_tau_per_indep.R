#### MODEL: bradley_terry_beta_tau_per_indep ####
# Generating code, matching the likelihood in bradley_terry_beta_tau_per_indep.stan.
# Two-session extension of bradley_terry_beta_tau_per following the "independent
# model" of Schurr et al. (2024): each scalar parameter (log_beta, tau,
# logit_key_decay, rho) has a subject mean mu^s ~ N(mu^g, eta), and each session
# value is y_t^s ~ N(mu^s, sigma). Utilities are drawn independently per session.
# Within a session, choices follow the same per-outcome perseveration Softmax as
# bradley_terry_beta_tau_per.

sim.block <- function(subject, session, u, beta, tau, key_decay, rho, cfg){

  Noffer  <- cfg$Noffer
  Ntrials <- cfg$Ntrials

  df <- data.frame()

  # 1. key_value starts at zero for every outcome slot (1 = A, 2 = B, 3 = None)
  key_value <- c(0, 0, 0)

  for (trial in 1:Ntrials) {
    # Sample 2 distinct symptoms
    offer <- sample(1:Noffer, 2, replace = FALSE)

    u1 <- u[offer[1]]
    u2 <- u[offer[2]]

    # 2. This trial sees the full rho bump from the previous trial's choice
    # (decay is applied after the choice, in step 5)

    # 3. Decoupled Softmax weights, with key_value added elementwise
    exp_1    <- exp(beta * u1   + key_value[1])
    exp_2    <- exp(beta * u2   + key_value[2])
    exp_none <- exp(tau         + key_value[3])

    denom <- exp_1 + exp_2 + exp_none

    prob_A    <- exp_1 / denom
    prob_B    <- exp_2 / denom
    prob_None <- exp_none / denom

    # 4. Sample the choice (1 = A, 2 = B, 3 = None)
    choice_num <- sample(c(1, 2, 3), size = 1, prob = c(prob_A, prob_B, prob_None))

    choice <- factor(
      ifelse(choice_num == 1, "A",
             ifelse(choice_num == 2, "B", "None")),
      levels = c("A", "B", "None"))

    is_choice_A <- as.numeric(choice_num == 1)

    # 5. After the choice: decay the old values, then bump the chosen slot;
    # the next trial sees key_decay * key_value + rho on the chosen slot
    key_value <- key_value * key_decay
    key_value[choice_num] <- key_value[choice_num] + rho

    df <- rbind(df, data.frame(
      subject = subject,
      session = session,
      trial = trial,
      offer_A = offer[1],
      offer_B = offer[2],
      u1 = u1,
      u2 = u2,
      prob_A = prob_A,
      prob_B = prob_B,
      prob_None = prob_None,
      choice = choice,
      is_choice_A = is_choice_A,
      key_value_A = key_value[1],
      key_value_B = key_value[2],
      key_value_None = key_value[3]
    ))
  }

  return(df)
}

# Draws true subject x session parameters from the independent model.
# cfg needs: Nsubjects, Nsessions, Noffer, and for each scalar p in
# {log_beta, tau, logit_key_decay, rho}: mu_g_<p>, eta_<p>, sigma_<p>.
# Returns a list of [Nsubjects, Nsessions] matrices (natural scale for beta and
# key_decay), the subject means mu_s_<p> (unconstrained scale), and u, a list of
# per-session [Nsubjects, Noffer] utility matrices standardized per subject.
sim.subject.params <- function(cfg){

  Nsubjects <- cfg$Nsubjects
  Nsessions <- cfg$Nsessions
  Noffer    <- cfg$Noffer

  scalars <- c("log_beta", "tau", "logit_key_decay", "rho")

  out <- list()

  for (p in scalars) {
    # 1. Subject mean around the group mean
    mu_s <- rnorm(Nsubjects, mean = cfg[[paste0("mu_g_", p)]], sd = cfg[[paste0("eta_", p)]])

    # 2. Session values around the subject mean, shared between-session SD
    sess <- matrix(rnorm(Nsubjects * Nsessions, mean = rep(mu_s, Nsessions),
                         sd = cfg[[paste0("sigma_", p)]]),
                   nrow = Nsubjects, ncol = Nsessions)

    out[[paste0("mu_s_", p)]] <- mu_s
    out[[p]] <- sess
  }

  # 3. Natural-scale versions, matching the Stan transformed parameters
  out$beta      <- exp(out$log_beta)
  out$key_decay <- plogis(out$logit_key_decay)

  # 4. Utilities: independent per session, standardized per subject (mean 0, sd 1),
  # matching the u_matrix hard constraint in the Stan model
  out$u <- lapply(1:Nsessions, function(k) {
    u_raw <- matrix(rnorm(Nsubjects * Noffer), nrow = Nsubjects, ncol = Noffer)
    matrix(t(scale(t(u_raw))), nrow = Nsubjects, ncol = Noffer)
  })

  return(out)
}
