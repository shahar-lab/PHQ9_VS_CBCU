#### EXTRACT A THINNED SET OF POSTERIOR DRAWS PER MODEL AND WAVE ####
# Per model: beta, tau, utilities for all models; rho for models 2 and 3; key_decay for model 3.
# Parameters a model does not have are filled with 0 (no perseveration = rho 0; no decay = key_decay 0),
# so one simulator serves all three models.

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
  fit  <- readRDS(file.path(job_dirs[[model_key]], paste0(fit_prefix[[model_key]], wave, ".rds")))
  vars <- c("beta", "tau", "u_matrix", if (model_key != "base") "rho", if (model_key == "per") "key_decay")
  dr   <- fit$draws(vars, format = "draws_matrix")
  mat  <- matrix(as.numeric(dr), nrow = nrow(dr), dimnames = list(NULL, colnames(dr)))

  set.seed(seed)   # same seed for every model, so the same draw indices are used when the fits have equal length
  keep <- sort(sample(nrow(mat), n_draws))
  mat  <- mat[keep, , drop = FALSE]

  beta <- subject_param(mat, "beta")
  list(beta  = beta,
       tau   = subject_param(mat, "tau"),
       rho   = if (model_key == "base") beta * 0 else subject_param(mat, "rho"),
       decay = if (model_key == "per") subject_param(mat, "key_decay") else beta * 0,
       U     = utility_array(mat),
       draw_index = keep)
}

draws_by_model <- map(names(fit_prefix), \(m) {
  map(waves, \(w) extract_params(m, w)) |> setNames(waves)
}) |> setNames(names(fit_prefix))

# Each fit must have the same number of subjects as the observed data
for (m in names(draws_by_model)) for (w in waves) {
  stopifnot(ncol(draws_by_model[[m]][[w]]$beta) == nrow(obs_data[[w]]$lookup))
}
