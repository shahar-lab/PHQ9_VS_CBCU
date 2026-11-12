#### MODEL: bradley_terry_beta_tau_lognormal_stz ####
# Generating code, matching the likelihood in bradley_terry_beta_tau_lognormal_stz.stan.
# u: item utilities for one subject (should sum to 0).
# beta: inverse temperature (> 0). tau: None threshold on the utility scale.

sim.block <- function(subject, u, beta, tau, cfg){

  Noffer  <- cfg$Noffer
  Ntrials <- cfg$Ntrials

  df <- data.frame()

  for (trial in 1:Ntrials) {
    # Sample 2 distinct items
    offer <- sample(1:Noffer, 2, replace = FALSE)

    u1 <- u[offer[1]]
    u2 <- u[offer[2]]

    # Softmax over A, B, None
    exp_1    <- exp(beta * u1)
    exp_2    <- exp(beta * u2)
    exp_none <- exp(beta * tau)

    denom <- exp_1 + exp_2 + exp_none

    prob_A    <- exp_1 / denom
    prob_B    <- exp_2 / denom
    prob_None <- exp_none / denom

    # Sample the choice (1 = A, 2 = B, 3 = None)
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
