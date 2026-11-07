#### BUILD POOLED TRIAL-LEVEL LOG-LIKELIHOOD MATRICES (TIME1 + TIME2 STACKED) ####
# Session is ignored: each model's two wave fits are stacked column-wise, so every trial of both
# waves is one LOO observation. The waves are independent fits, so their draws are simply
# stacked (iteration i of time1 next to iteration i of time2).

waves <- c("time1", "time2")

# model label -> job artifacts folder and fit-file prefix
models <- list(
  "beta_tau (no perseveration)"            = list(dir = job_dirs$base, prefix = "bt_fit_"),
  "beta_tau_rho (rho, no decay)"           = list(dir = job_dirs$rho,  prefix = "bt_rho_fit_"),
  "beta_tau_per (rho + key_decay)"         = list(dir = job_dirs$per,  prefix = "bt_per_fit_")
)

# All jobs must list the same participants (same trial order: prolific_id, block, trial)
for (wave in waves) {
  lookups <- map(job_dirs, \(d) read_csv(file.path(d, paste0("subject_lookup_", wave, ".csv")), show_col_types = FALSE))
  stopifnot(identical(lookups$base, lookups$rho), identical(lookups$base, lookups$per))
}

# Returns the (draws x trials) log_lik matrix and per-trial relative ESS for one fit
extract_log_lik <- function(fit_path) {
  fit      <- readRDS(fit_path)
  ll_array <- fit$draws("log_lik", format = "draws_array")
  ll_mat   <- as.matrix(as_draws_matrix(ll_array))
  r_eff    <- relative_eff(exp(ll_array))
  list(log_lik = ll_mat, r_eff = r_eff)
}

# Stacked per model: (draws x all trials of both waves)
ll_by_model <- map(models, \(m) {
  per_wave <- map(waves, \(w) extract_log_lik(file.path(m$dir, paste0(m$prefix, w, ".rds"))))
  list(log_lik = do.call(cbind, map(per_wave, "log_lik")),
       r_eff   = unlist(map(per_wave, "r_eff")))
})

stopifnot(
  length(unique(map_int(ll_by_model, \(m) ncol(m$log_lik)))) == 1,
  length(unique(map_int(ll_by_model, \(m) nrow(m$log_lik)))) == 1
)
