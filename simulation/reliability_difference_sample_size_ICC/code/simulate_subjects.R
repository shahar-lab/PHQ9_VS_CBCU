#### SIMULATE PER-SUBJECT CBCU + PHQ9 REPEATED-MEASURES DATA ####

# Repeated simulate+fit run 50 times over a loop is the case where a custom
# function is warranted (per coding-rules.md).
simulate_subjects <- function(n, cbcu_icc, phq9_icc, cbcu_n_items = 15, phq9_n_items = 9) {

  # tau derived from target ICC with sigma fixed at 1: ICC = tau^2 / (tau^2 + sigma^2)
  # => tau = sqrt(ICC / (1 - ICC)).
  cbcu_tau <- sqrt(cbcu_icc / (1 - cbcu_icc))
  phq9_tau <- sqrt(phq9_icc / (1 - phq9_icc))
  sigma    <- 1

  cbcu_intercepts <- rnorm(n, 0, cbcu_tau)
  phq9_intercepts <- rnorm(n, 0, phq9_tau)

  cbcu_df <- map_dfr(seq_len(n), function(s) {
    tibble(
      subject = s,
      time    = rep(c(1, 2), each = cbcu_n_items),
      item    = rep(seq_len(cbcu_n_items), times = 2),
      y       = cbcu_intercepts[s] + rnorm(2 * cbcu_n_items, 0, sigma)
    )
  })

  phq9_df <- map_dfr(seq_len(n), function(s) {
    tibble(
      subject = s,
      time    = rep(c(1, 2), each = phq9_n_items),
      item    = rep(seq_len(phq9_n_items), times = 2),
      y       = phq9_intercepts[s] + rnorm(2 * phq9_n_items, 0, sigma)
    )
  })

  list(cbcu_df = cbcu_df, phq9_df = phq9_df)
}
