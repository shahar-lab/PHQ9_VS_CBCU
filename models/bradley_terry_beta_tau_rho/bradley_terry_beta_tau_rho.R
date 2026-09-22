#### MODEL: bradley_terry_beta_tau_rho ####
# Generating code, matching the likelihood in bradley_terry_beta_tau_rho.stan.
# Variant of bradley_terry_beta_tau_per with key_decay fixed at 0 (perfect decay):
# key_value resets to zero every trial before the current choice is evaluated, so
# only the immediately preceding trial's chosen slot carries a perseveration bump
# of rho, added elementwise into the same 3-way decoupled Softmax as the base model.

sim.block <- function(subject, u, beta, tau, rho, cfg){

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

    # 2. key_decay fixed at 0: nothing carries forward from before the
    # previous trial's bump was added, so key_value already holds only
    # rho on the slot chosen last trial (or all zeros on the first trial).

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

    # 5. key_decay fixed at 0: next trial's key_value starts from zero, not
    # from this trial's key_value, so only this trial's chosen slot carries
    # forward into the next trial.
    key_value <- c(0, 0, 0)
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
