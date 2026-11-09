#### SUMMARY STATISTICS PER PARTICIPANT-SESSION (OBSERVED AND SIMULATED) ####
# compute_stats() takes a draws x subjects x trials array of choices (1 = A, 2 = B, 3 = None). The
# observed data are passed as an array with one "draw", so the same function serves both.
#
#   skip_rate   share of trials with None
#   left_share  share of answered trials that used the left key
#   key_repeat  share of consecutive answered trials (both A/B) that used the same key
#   longest_run longest run of identical responses (None counts as a response)
#   viol_rate   share of fully answered triads of items that form a cycle (skips treated as missing)
#   n_triads    number of fully answered triads (how much information viol_rate has)

n_items <- 15
triads  <- combn(n_items, 3)

compute_stats <- function(choice, left, right) {
  n_d <- dim(choice)[1]
  n_s <- dim(choice)[2]
  n_t <- dim(choice)[3]

  answered <- choice < 3L

  skip_rate  <- rowSums(!answered, dims = 2) / n_t
  left_share <- rowSums(choice == 1L, dims = 2) / rowSums(answered, dims = 2)

  prev <- choice[, , -n_t, drop = FALSE]
  nxt  <- choice[, , -1, drop = FALSE]
  both <- prev < 3L & nxt < 3L
  key_repeat <- rowSums(both & prev == nxt, dims = 2) / rowSums(both, dims = 2)

  run <- longest_run <- matrix(1, n_d, n_s)
  for (t in 2:n_t) {
    same        <- matrix(choice[, , t] == choice[, , t - 1], n_d, n_s)
    run         <- ifelse(same, run + 1, 1)
    longest_run <- pmax(longest_run, run)
  }

  # W[d, s, i, j] = TRUE if item i was chosen over item j (skips leave no entry)
  d_idx <- rep(seq_len(n_d), times = n_s)
  s_idx <- rep(seq_len(n_s), each = n_d)
  W <- array(FALSE, dim = c(n_d, n_s, n_items, n_items))
  for (t in seq_len(n_t)) {
    ch   <- as.vector(matrix(choice[, , t], n_d, n_s))
    l    <- left[s_idx, t]
    r    <- right[s_idx, t]
    ok   <- ch < 3L
    win  <- ifelse(ch == 1L, l, r)
    lose <- ifelse(ch == 1L, r, l)
    W[cbind(d_idx, s_idx, win, lose)[ok, , drop = FALSE]] <- TRUE
  }

  full <- cyc <- matrix(0, n_d, n_s)
  for (k in seq_len(ncol(triads))) {
    x <- triads[1, k]; y <- triads[2, k]; z <- triads[3, k]
    xy <- matrix(W[, , x, y], n_d, n_s); yx <- matrix(W[, , y, x], n_d, n_s)
    xz <- matrix(W[, , x, z], n_d, n_s); zx <- matrix(W[, , z, x], n_d, n_s)
    yz <- matrix(W[, , y, z], n_d, n_s); zy <- matrix(W[, , z, y], n_d, n_s)
    complete <- (xy | yx) & (xz | zx) & (yz | zy)
    cycle    <- complete & ((xy & yz & zx) | (yx & zy & xz))
    full <- full + complete
    cyc  <- cyc + cycle
  }

  list(skip_rate   = skip_rate,
       left_share  = left_share,
       key_repeat  = key_repeat,
       longest_run = longest_run,
       viol_rate   = ifelse(full > 0, cyc / full, NA_real_),
       n_triads    = full)
}

stat_names <- c("skip_rate", "left_share", "key_repeat", "longest_run", "viol_rate")

obs_stats <- map(obs_data, \(o) {
  compute_stats(array(o$choice, dim = c(1, nrow(o$choice), ncol(o$choice))), o$left, o$right)
})

sim_stats <- map(names(sim_choices), \(m) {
  map(waves, \(w) compute_stats(sim_choices[[m]][[w]], obs_data[[w]]$left, obs_data[[w]]$right)) |>
    setNames(waves)
}) |> setNames(names(sim_choices))

saveRDS(sim_stats, file.path(artifacts_dir, "simulated_statistics.rds"))

df_observed <- map_dfr(waves, \(w) {
  tibble(time = w, prolific_id = obs_data[[w]]$lookup$prolific_id,
         !!!map(obs_stats[[w]], \(m) as.vector(m)))
})
write_csv(df_observed, file.path(artifacts_dir, "observed_statistics.csv"))
