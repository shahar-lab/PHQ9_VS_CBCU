#### FULL CHOICE DISTRIBUTIONS FOR A RANDOM SAMPLE OF PARTICIPANT-SESSIONS ####
# 20 participant-sessions are drawn at random (seeded). For each one the model's 100 simulated
# sequences (one per posterior draw, all parameters taken from the same draw) are shown against
# the real choices:
#   View 1 (counts):  how many A, B and None choices out of 105 the model produces across the
#                     100 draws (bars) and how many the participant actually made (red line).
#   View 2 (trials):  for every one of the 105 trials, the share of the 100 draws that chose A, B
#                     or None (darker = more draws) and the participant's actual choice (black dot).

n_sample_sessions <- 20

all_sessions <- bind_rows(map(waves, \(w) {
  tibble(time = w, subject = seq_len(nrow(obs_data[[w]]$lookup)), prolific_id = obs_data[[w]]$lookup$prolific_id)
}))

set.seed(seed)
df_sample <- all_sessions |>
  slice_sample(n = n_sample_sessions) |>
  arrange(time, prolific_id) |>
  mutate(n_skips = map2_int(time, subject, \(w, s) sum(obs_data[[w]]$choice[s, ] == 3L)),
         label = factor(sprintf("%s  %s\n%d skips", substr(prolific_id, 1, 8), time, n_skips),
                        levels = sprintf("%s  %s\n%d skips", substr(prolific_id, 1, 8), time, n_skips)))
write_csv(df_sample |> select(-label), file.path(output_dir, "ppc_sampled_sessions.csv"))

outcome_levels <- c("A (left)", "B (right)", "None (skip)")

# View 1 data: counts per draw, and the observed count
counts_for <- function(m) {
  map_dfr(seq_len(nrow(df_sample)), \(i) {
    w <- df_sample$time[i]; s <- df_sample$subject[i]
    sim <- sim_choices[[m]][[w]][, s, ]   # draws x trials
    obs <- obs_data[[w]]$choice[s, ]
    map_dfr(1:3, \(k) tibble(label = df_sample$label[i], outcome = factor(outcome_levels[k], outcome_levels),
                             sim_count = rowSums(sim == k), obs_count = sum(obs == k)))
  })
}

# View 2 data: per trial, share of draws choosing each outcome, and the observed choice
trials_for <- function(m) {
  map_dfr(seq_len(nrow(df_sample)), \(i) {
    w <- df_sample$time[i]; s <- df_sample$subject[i]
    sim <- sim_choices[[m]][[w]][, s, ]
    obs <- obs_data[[w]]$choice[s, ]
    map_dfr(1:3, \(k) tibble(label = df_sample$label[i], trial = seq_along(obs),
                             outcome = factor(outcome_levels[k], rev(outcome_levels)),
                             share = colMeans(sim == k), observed = obs[seq_along(obs)] == k))
  })
}

plot_counts <- function(df) {
  ggplot(df, aes(x = sim_count)) +
    geom_bar(fill = "grey55", width = 0.9) +
    geom_vline(aes(xintercept = obs_count), colour = "#c0392b", linewidth = 0.9) +
    facet_grid(label ~ outcome, scales = "free") +
    labs(x = "Number of trials out of 105 (bars: 100 simulated sequences; red line: observed)",
         y = "Number of draws") +
    theme_bw(base_size = 8) +
    theme(strip.text.y = element_text(angle = 0, size = 6))
}

plot_trials <- function(df) {
  ggplot(df, aes(x = trial, y = outcome)) +
    geom_tile(aes(fill = share), colour = NA) +
    geom_point(data = filter(df, observed), shape = 19, size = 1.1, colour = "#c0392b") +
    scale_fill_gradient(low = "white", high = "grey15", limits = c(0, 1), name = "share of draws") +
    facet_grid(label ~ ., switch = "y") +
    labs(x = "Trial", y = NULL, subtitle = "Shading: share of the 100 simulated sequences that chose the outcome. Red dot: what the participant actually chose.") +
    theme_bw(base_size = 8) +
    theme(strip.text.y.left = element_text(angle = 0, size = 6), legend.position = "bottom",
          panel.spacing.y = unit(2, "pt"))
}

for (m in names(sim_choices)) {
  df_counts <- counts_for(m)
  df_trials <- trials_for(m)

  pdf(file.path(output_dir, paste0("ppc_choice_distributions_", m, ".pdf")), width = 9, height = 14)
  print(plot_counts(df_counts) + labs(title = model_labels[[m]]))
  walk(split(levels(df_sample$label), rep(1:2, each = n_sample_sessions / 2)), \(lbls) {
    print(plot_trials(filter(df_trials, label %in% lbls)) + labs(title = model_labels[[m]]))
  })
  dev.off()

  # One PNG pair for the model with the most parameters, for quick viewing
  if (m == "per") {
    ggsave(file.path(output_dir, "ppc_choice_counts.png"), plot_counts(df_counts) + labs(title = model_labels[[m]]), width = 9, height = 14, dpi = 130)
    ggsave(file.path(output_dir, "ppc_choice_trials_part1.png"),
           plot_trials(filter(df_trials, label %in% levels(df_sample$label)[1:10])) + labs(title = model_labels[[m]]), width = 10, height = 8, dpi = 130)
    ggsave(file.path(output_dir, "ppc_choice_trials_part2.png"),
           plot_trials(filter(df_trials, label %in% levels(df_sample$label)[11:20])) + labs(title = model_labels[[m]]), width = 10, height = 8, dpi = 130)
  }
}

# Numbers behind the pictures, for the model with all parameters
df_counts_per <- counts_for("per")
df_trials_per <- trials_for("per")
df_sample_summary <- df_counts_per |>
  group_by(label, outcome) |>
  summarise(observed = first(obs_count), sim_median = median(sim_count),
            sim_q05 = quantile(sim_count, 0.05, names = FALSE), sim_q95 = quantile(sim_count, 0.95, names = FALSE),
            .groups = "drop")
write_csv(df_sample_summary, file.path(output_dir, "ppc_sampled_sessions_counts.csv"))

# Per sampled session: share of trials where the simulated probability of the observed choice is >= 0.5,
# and share where no simulated sequence made the observed choice
df_trial_agreement <- df_trials_per |>
  filter(observed) |>
  group_by(label) |>
  summarise(share_obs_choice_ge_half = mean(share >= 0.5), share_obs_choice_never_simulated = mean(share == 0), .groups = "drop")
write_csv(df_trial_agreement, file.path(output_dir, "ppc_sampled_sessions_trial_agreement.csv"))
print(df_trial_agreement, n = Inf)
