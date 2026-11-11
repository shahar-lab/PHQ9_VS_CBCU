#### MODEL: bradley_terry_beta_tau_noncentered ####
# Generating code, matching the likelihood in bradley_terry_beta_tau_noncentered.stan.
# Same as bradley_terry_beta_tau_rho_noncentered with rho removed: no perseveration,
# so each trial's choice depends only on the offered utilities and tau. tau is
# multiplied by beta in the None weight (beta * tau), so tau is a Burden Threshold
# on the standardized utility scale. The non-centered parameterization only changes
# how Stan samples the subject-level parameters, not the generating process, so
# sim.block() takes beta and tau directly.

sim.block <- function(subject, u, beta, tau, cfg){

  Noffer  <- cfg$Noffer
  Ntrials <- cfg$Ntrials

  df <- data.frame()

  for (trial in 1:Ntrials) {
    # Sample 2 distinct symptoms
    offer <- sample(1:Noffer, 2, replace = FALSE)

    u1 <- u[offer[1]]
    u2 <- u[offer[2]]

    # 1. Decoupled Softmax weights, with tau scaled by beta like the option utilities
    exp_1    <- exp(beta * u1)
    exp_2    <- exp(beta * u2)
    exp_none <- exp(beta * tau)

    denom <- exp_1 + exp_2 + exp_none

    prob_A    <- exp_1 / denom
    prob_B    <- exp_2 / denom
    prob_None <- exp_none / denom

    # 2. Sample the choice (1 = A, 2 = B, 3 = None)
    choice_num <- sample(c(1, 2, 3), size = 1, prob = c(prob_A, prob_B, prob_None))

    choice <- factor(
      ifelse(choice_num == 1, "A",
             ifelse(choice_num == 2, "B", "None")),
      levels = c("A", "B", "None"))

    is_choice_A <- as.numeric(choice_num == 1)

    df <- rbind(df, data.frame(
      subject = subject,
      trial = trial,
      offer_A = offer[1],
      offer_B = offer[2],
      u1 = u1,
      u2 = u2,
      prob_A = prob_A,
      prob_B = prob_B,
      prob_None = prob_None,
      choice = choice,
      is_choice_A = is_choice_A
    ))
  }

  return(df)
}
