#### GENERATE DATA (ONE DATASET PER SESSION) ####
# reads: artifacts/true_u.rds
# writes: artifacts/simulated_data.rds, stan_data_list.rds

true_u <- readRDS(file.path(artifacts_dir, "true_u.rds"))   # items + None

sessions <- paste0("session", 1:n_sessions)

sim_list <- list()

for (session in sessions) {
  for (s in 1:n_subjects) {
    sim_list[[paste(session, s)]] <- sim.block(
      subject = s,
      u       = true_u[s, ],
      cfg     = list(Noffer = n_options, Ntrials = n_trials)
    ) |>
      mutate(session = session, .before = 1)
  }
}

# Stan reads an integer choice: 1 = A, 2 = B, 3 = None (the factor's level order)
df_simulated <- bind_rows(sim_list) |>
  mutate(choice_int = as.integer(choice))

stan_data_list <- map(setNames(sessions, sessions), function(this_session) {
  df_session <- filter(df_simulated, session == this_session)
  list(
    N_trials      = nrow(df_session),
    N_subjects    = n_subjects,
    N_options     = n_options,
    subject_index = df_session$subject,
    offer_A       = df_session$offer_A,
    offer_B       = df_session$offer_B,
    choice        = df_session$choice_int
  )
})

saveRDS(df_simulated, file.path(artifacts_dir, "simulated_data.rds"))
saveRDS(stan_data_list, file.path(artifacts_dir, "stan_data_list.rds"))
