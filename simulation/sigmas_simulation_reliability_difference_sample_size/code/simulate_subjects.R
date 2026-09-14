#### SIMULATE PER-SUBJECT PHQ9 REPEATED-MEASURES DATA ####

# Repeated simulate+fit run across sample sizes is the case where a custom
# function is warranted (per coding-rules.md).
simulate_subjects <- function(n, sigma_0, sigma_e, mean_phq9) {

  subject_intercepts <- rnorm(n, mean_phq9, sigma_0)

  df <- tibble(
    subject = rep(seq_len(n), each = 2),
    time    = rep(c(1, 2), times = n),
    y       = rep(subject_intercepts, each = 2) + rnorm(2 * n, 0, sigma_e)
  )

  df
}
