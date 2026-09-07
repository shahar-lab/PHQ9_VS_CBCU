#### SIMULATE PER-SUBJECT LIKERT + CBCU DATA ####

# Repeated simulate+fit run 50 times over a loop is the case where a custom
# function is warranted (per coding-rules.md).
simulate_subjects <- function(n, likert_r_mean, cbcu_r_mean, r_sd) {

  personal_likert_correlation <- rnorm(n, likert_r_mean, r_sd) |> pmin(0.99) |> pmax(-0.99)
  personal_cbcu_correlation   <- rnorm(n, cbcu_r_mean,   r_sd) |> pmin(0.99) |> pmax(-0.99)

  likert_df <- map_dfr(seq_len(n), function(s) {
    r     <- personal_likert_correlation[s]
    sigma <- matrix(c(1, r, r, 1), nrow = 2)
    draws <- MASS::mvrnorm(9, mu = c(0, 0), Sigma = sigma)
    tibble(subject = s, likert_time1 = draws[, 1], likert_time2 = draws[, 2])
  })

  cbcu_df <- map_dfr(seq_len(n), function(s) {
    r     <- personal_cbcu_correlation[s]
    sigma <- matrix(c(1, r, r, 1), nrow = 2)
    draws <- MASS::mvrnorm(15, mu = c(0, 0), Sigma = sigma)
    tibble(subject = s, cbcu_time1 = draws[, 1], cbcu_time2 = draws[, 2])
  })

  list(likert_df = likert_df, cbcu_df = cbcu_df)
}
