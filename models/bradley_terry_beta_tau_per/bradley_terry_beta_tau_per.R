#### MODEL: bradley_terry_beta_tau_per ####
# Generating code, matching the likelihood in bradley_terry_beta_tau_per.stan.
# Extends bradley_terry_beta_tau with a per-outcome (A / B / None) perseveration
# key_value that decays every trial and bumps up on the chosen slot, added
# elementwise into the same 3-way decoupled Softmax as the base model.

sim.block <- function(subject, u, beta, tau, key_decay, rho, cfg){

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

    # 2. Decay the whole key_value vector before the choice is made
    key_value <- key_value * key_decay

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

    # 5. Bump the chosen slot; this carries into next trial's decay step
    key_value[choice_num] <- key_value[choice_num] + rho

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
      is_choice_A = is_choice_A,
      key_value_A = key_value[1],
      key_value_B = key_value[2],
      key_value_None = key_value[3]
    ))
  }

  return(df)
}
