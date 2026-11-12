#### EXTRACT A THINNED SET OF POSTERIOR DRAWS PER MODEL AND WAVE ####
# Per draw and subject: beta, tau, the 15 utilities (u_matrix, already standardized inside Stan) and,
# for beta_tau_rho, rho. beta_tau has no rho, so it gets rho = 0 and one predictor serves both models.

# Columns of a draws matrix named name[s], returned as draws x subjects (ordered by s)
subject_param <- function(mat, name) {
  cols <- grep(paste0("^", name, "\\[\\d+\\]$"), colnames(mat), value = TRUE)
  s    <- as.integer(str_extract(cols, "\\d+"))
  mat[, cols[order(s)], drop = FALSE]
}

# u_matrix[s,i] as a draws x subjects x items array
utility_array <- function(mat) {
  cols <- grep("^u_matrix\\[\\d+,\\d+\\]$", colnames(mat), value = TRUE)
  idx  <- str_match(cols, "\\[(\\d+),(\\d+)\\]")
  arr  <- array(NA_real_, dim = c(nrow(mat), max(as.integer(idx[, 2])), max(as.integer(idx[, 3]))))
  for (j in seq_along(cols)) arr[, as.integer(idx[j, 2]), as.integer(idx[j, 3])] <- mat[, cols[j]]
  arr
}

extract_params <- function(model_key, wave) {
  message("Loading ", model_key, " ", wave, " (large file, this takes a while)")
  fit  <- readRDS(file.path(job_dirs[[model_key]], paste0("fit_", wave, ".rds")))
  vars <- c("beta", "tau", "u_matrix", if (model_key == "rho") "rho")
  dr   <- fit$draws(vars, format = "draws_matrix")
  rm(fit); gc()
  mat  <- matrix(as.numeric(dr), nrow = nrow(dr), dimnames = list(NULL, colnames(dr)))

  set.seed(seed)   # same seed for every fit, so the same draw indices are used (all fits have 8000 draws)
  keep <- sort(sample(nrow(mat), n_draws))
  mat  <- mat[keep, , drop = FALSE]

  beta <- subject_param(mat, "beta")
  list(beta = beta,
       tau  = subject_param(mat, "tau"),
       rho  = if (model_key == "rho") subject_param(mat, "rho") else beta * 0,
       U    = utility_array(mat),
       draw_index = keep)
}

if (reuse_cached_draws && file.exists(draws_cache_path)) {
  draws_by_model <- readRDS(draws_cache_path)
  stopifnot(nrow(draws_by_model$base$time1$beta) == n_draws)
} else {
  draws_by_model <- map(names(job_dirs), \(m) {
    map(waves, \(w) extract_params(m, w)) |> setNames(waves)
  }) |> setNames(names(job_dirs))
  saveRDS(draws_by_model, draws_cache_path)
}

# Each fit must have the same number of subjects as the observed data
for (m in names(draws_by_model)) for (w in waves) {
  stopifnot(ncol(draws_by_model[[m]][[w]]$beta) == nrow(obs_data[[w]]$lookup),
            dim(draws_by_model[[m]][[w]]$U)[2] == nrow(obs_data[[w]]$lookup))
}
