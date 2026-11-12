#### BUILD POOLED TRIAL-LEVEL LOG-LIKELIHOOD MATRICES (TIME1 + TIME2 STACKED) ####
# Session is ignored: each model's two wave fits are stacked column-wise, so every trial of both
# waves is one LOO observation. The waves are independent fits, so their draws are simply
# stacked (iteration i of time1 next to iteration i of time2).

waves <- c("time1", "time2")

# All jobs must list the same participants (same trial order: prolific_id, block, trial)
subject_lookup <- map(waves, \(wave) {
  lookups <- map(models, \(m) as.data.frame(read_csv(file.path(m$dir, paste0("subject_lookup_", wave, ".csv")), show_col_types = FALSE)))
  # as.data.frame + all.equal: read_csv attaches per-file spec/problems attributes that make identical() fail
  for (k in seq_along(lookups)[-1]) stopifnot(isTRUE(all.equal(lookups[[1]], lookups[[k]], check.attributes = FALSE)))
  as_tibble(lookups[[1]])
}) |> setNames(waves)

# Which participant-session each log_lik column belongs to (same order as the fits: 105 trials per subject)
trial_index <- map_dfr(waves, \(wave) {
  n_subjects <- nrow(subject_lookup[[wave]])
  tibble(time = wave,
         prolific_id = rep(subject_lookup[[wave]]$prolific_id, each = 105),
         trial = rep(seq_len(105), times = n_subjects))
})

# Returns the (draws x trials) log_lik matrix and per-trial relative ESS for one fit
extract_log_lik <- function(fit_path) {
  message("Loading ", fit_path)
  fit      <- readRDS(fit_path)
  ll_array <- fit$draws("log_lik", format = "draws_array")
  rm(fit); gc()
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
  length(unique(map_int(ll_by_model, \(m) nrow(m$log_lik)))) == 1,
  ncol(ll_by_model[[1]]$log_lik) == nrow(trial_index)
)
