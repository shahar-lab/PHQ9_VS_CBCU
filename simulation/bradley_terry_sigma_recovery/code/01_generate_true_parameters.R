#### GENERATE TRUE PARAMETERS ####
# writes: artifacts/true_population.rds, true_parameters.rds, true_u.rds
#
# true_u has n_options + 1 columns: items 1..n_options, then None (= tau).

true_population <- tibble(
  parameter  = c("sigma_location", "sigma_scale"),
  true_value = c(true_sigma_location, true_sigma_scale)
)

# sigma: non-centered, as in the Stan model.
# sigma_raw is a standard normal truncated below at -location / scale (so sigma > 0),
# drawn by the inverse CDF.
sigma_raw_lower <- -true_sigma_location / true_sigma_scale

true_parameters <- tibble(
  subject   = 1:n_subjects,
  sigma_raw = qnorm(runif(n_subjects, min = pnorm(sigma_raw_lower), max = 1))
) |>
  mutate(sigma = true_sigma_location + true_sigma_scale * sigma_raw)

stopifnot(all(true_parameters$sigma > 0))

# Utilities (items + None): drawn from the model's own prior with draw.u()
# (sum to zero over n_options + 1, marginal SD = sigma)
true_u <- t(sapply(true_parameters$sigma, draw.u, Noffer = n_options))
stopifnot(dim(true_u) == c(n_subjects, n_options + 1),
          all(abs(rowSums(true_u)) < 1e-8))

true_parameters <- mutate(true_parameters, tau = true_u[, n_options + 1])

saveRDS(true_population, file.path(artifacts_dir, "true_population.rds"))
saveRDS(true_parameters, file.path(artifacts_dir, "true_parameters.rds"))
saveRDS(true_u, file.path(artifacts_dir, "true_u.rds"))
