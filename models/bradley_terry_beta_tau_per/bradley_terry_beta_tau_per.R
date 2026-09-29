#### MODEL: bradley_terry_beta_tau_per ####
# Generating code, matching the likelihood in bradley_terry_beta_tau_per.stan.
# Extends bradley_terry_beta_tau with a per-outcome (A / B / None) perseveration
# key_value that carries across trials, decays after each trial's choice is evaluated,
# and bumps up on the chosen slot.

sim.block <- function(subject, u, beta, tau, key_decay, rho, cfg){

  Noffer  <- cfg$Noffer
  Ntrials <- cfg$Ntrials

  df <- data.frame()

  # key_value starts at zero for every outcome slot
  # (1 = A, 2 = B, 3 = None)
  key_value <- c(0, 0, 0)

  for (trial in 1:Ntrials) {

    # Sample 2 distinct symptoms
    offer <- sample(1:Noffer, 2, replace = FALSE)

    u1 <- u[offer[1]]
    u2 <- u[offer[2]]

    # Save the perseveration values that affect THIS trial's choice
    key_contrib <- key_value

    # Decoupled Softmax weights, with key_contrib added elementwise
    exp_1    <- exp(beta * u1 + key_contrib[1])
    exp_2    <- exp(beta * u2 + key_contrib[2])
    exp_none <- exp(tau       + key_contrib[3])

    denom <- exp_1 + exp_2 + exp_none

    prob_A    <- exp_1 / denom
    prob_B    <- exp_2 / denom
    prob_None <- exp_none / denom

    # Sample the choice
    # 1 = A, 2 = B, 3 = None
    choice_num <- sample(
      c(1, 2, 3),
      size = 1,
      prob = c(prob_A, prob_B, prob_None)
    )

    choice <- factor(
      ifelse(
        choice_num == 1, "A",
        ifelse(choice_num == 2, "B", "None")
      ),
      levels = c("A", "B", "None")
    )

    is_choice_A <- as.numeric(choice_num == 1)

    # Update the perseveration state for the NEXT trial:
    # first decay the previous history...
    key_value <- key_value * key_decay

    # ...then add rho to the option chosen on this trial
    key_value[choice_num] <- key_value[choice_num] + rho

    df <- rbind(
      df,
      data.frame(
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

        # Perseveration values that affected THIS trial
        key_contrib_A = key_contrib[1],
        key_contrib_B = key_contrib[2],
        key_contrib_None = key_contrib[3],

        # Updated values carried into the NEXT trial
        key_value_A = key_value[1],
        key_value_B = key_value[2],
        key_value_None = key_value[3]
      )
    )
  }

  return(df)
}