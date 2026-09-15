#### SIMULATE CROSSED SUBJECT x ITEM DATA ####

# Repeated simulate+fit run across sample sizes and two outcomes is the case
# where a custom function is warranted (per coding-rules.md).
simulate_subjects_items <- function(n, grand_mean, sigma_subject, sigma_item, sigma_e, n_items) {

  subject_effects <- rnorm(n, 0, sigma_subject)
  item_effects    <- rnorm(n_items, 0, sigma_item)

  df <- tibble(
    subject = rep(seq_len(n), each = n_items),
    item    = rep(seq_len(n_items), times = n),
    y       = grand_mean +
      rep(subject_effects, each = n_items) +
      rep(item_effects, times = n) +
      rnorm(n * n_items, 0, sigma_e)
  )

  df
}
