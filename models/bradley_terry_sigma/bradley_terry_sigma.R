#### MODEL: bradley_terry_sigma ####
# Generating code, matching the likelihood in bradley_terry_sigma.stan.
# No beta and no separate tau: "None" is the (Noffer + 1)-th utility, and the
# logits are the utilities themselves.
# u: utilities for one subject, length Noffer + 1 (items 1..Noffer, then None),
#    summing to 0 across all Noffer + 1. sigma (the SD of u) does not enter the
#    choice rule directly; it acts only through the spread of u. Draw u with
#    draw.u() below so it matches the Stan prior.

# Draw one subject's utilities: sum-to-zero over Noffer + 1, marginal SD = sigma.
draw.u <- function(sigma, Noffer){
  n_utilities <- Noffer + 1
  z <- rnorm(n_utilities)
  z <- (z - mean(z)) * sqrt(n_utilities / (n_utilities - 1))   # sum to 0, marginal SD 1
  return(sigma * z)
}

sim.block <- function(subject, u, cfg){

  Noffer  <- cfg$Noffer
  Ntrials <- cfg$Ntrials
  u_none  <- u[Noffer + 1]

  df <- data.frame()

  for (trial in 1:Ntrials) {
    # Sample 2 distinct items
    offer <- sample(1:Noffer, 2, replace = FALSE)

    u1 <- u[offer[1]]
    u2 <- u[offer[2]]

    # Softmax over A, B, None
    exp_1    <- exp(u1)
    exp_2    <- exp(u2)
    exp_none <- exp(u_none)

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

    df <- rbind(df, data.frame(
      subject   = subject,
      trial     = trial,
      offer_A   = offer[1],
      offer_B   = offer[2],
      u1        = u1,
      u2        = u2,
      prob_A    = prob_A,
      prob_B    = prob_B,
      prob_None = prob_None,
      choice    = choice
    ))
  }

  return(df)
}
