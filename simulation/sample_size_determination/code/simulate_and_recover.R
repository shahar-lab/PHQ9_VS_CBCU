#### SIMULATE + FIT ONE REPLICATE ####

# Repeated simulate+fit run 50 times over a loop is the case where a custom
# function is warranted (per coding-rules.md).
simulate_and_recover <- function(n, true_r) {

  sigma <- matrix(c(1, true_r, true_r, 1), nrow = 2)
  draws <- MASS::mvrnorm(n, mu = c(0, 0), Sigma = sigma)
  df    <- tibble(y1 = draws[, 1], y2 = draws[, 2])

  rescor_prior <- prior(lkj(1), class = "rescor")

  fit <- brm(
    formula = bf(y1 ~ 1) + bf(y2 ~ 1) + set_rescor(TRUE),
    data    = df,
    family  = gaussian(),
    prior   = rescor_prior,
    chains  = 4,
    iter    = 2000,
    warmup  = 1000,
    backend = "cmdstanr",
    cores   = 4
  )

  rescor_draws <- as_draws_df(fit)$rescor__y1__y2

  hdi_85 <- ggdist::median_hdi(rescor_draws, .width = 0.85)
  hdi_90 <- ggdist::median_hdi(rescor_draws, .width = 0.90)
  hdi_95 <- ggdist::median_hdi(rescor_draws, .width = 0.95)

  tibble(
    median_r      = hdi_85$y,
    hdi_width_85  = hdi_85$ymax - hdi_85$ymin,
    hdi_width_90  = hdi_90$ymax - hdi_90$ymin,
    hdi_width_95  = hdi_95$ymax - hdi_95$ymin
  )
}
