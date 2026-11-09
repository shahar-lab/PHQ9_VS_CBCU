#### SYMPTOM-LEVEL CHOICES: HOW OFTEN EACH SYMPTOM IS CHOSEN, OBSERVED VS SIMULATED ####
# A/B is only the side of the screen. Here the simulated choices are turned back into symptoms:
# choice A = the symptom shown on the left, choice B = the one on the right, None = neither.
# Each symptom appears in 14 of the 105 trials, so the number of times a participant chooses it
# (when shown) is between 0 and 14. For every symptom we show how that count is distributed over the
# 100 simulated sequences and where the participant's real count falls.
# Uses the same 20 randomly drawn participant-sessions as plot_choice_distributions.R (df_sample).

# Item key: item number -> PHQ-9 code and text (from the observed data)
df_item_key <- df_cbcu |>
  distinct(item_number = item_number_left, item_phq9 = item_phq9_left, item_text = item_text_left) |>
  arrange(item_number)
write_csv(df_item_key, file.path(output_dir, "ppc_item_key.csv"))
item_codes <- df_item_key$item_phq9[order(df_item_key$item_number)]

# Times each symptom is chosen, per draw (rows) x symptom (columns), for one session
chosen_counts <- function(choice, left, right) {
  # choice: draws x trials; left, right: item numbers per trial
  n_d <- nrow(choice)
  counts <- sapply(seq_len(n_items), \(i) {
    rowSums((choice == 1L & rep(left == i, each = n_d)) | (choice == 2L & rep(right == i, each = n_d)))
  })
  matrix(counts, nrow = n_d)   # sapply drops to a vector when there is a single draw (the observed data)
}

symptom_data_for <- function(m) {
  map_dfr(seq_len(nrow(df_sample)), \(i) {
    w <- df_sample$time[i]; s <- df_sample$subject[i]
    sim_counts <- chosen_counts(sim_choices[[m]][[w]][, s, ], obs_data[[w]]$left[s, ], obs_data[[w]]$right[s, ])
    obs_counts <- chosen_counts(matrix(obs_data[[w]]$choice[s, ], nrow = 1), obs_data[[w]]$left[s, ], obs_data[[w]]$right[s, ])
    map_dfr(seq_len(n_items), \(j) {
      tibble(label = df_sample$label[i], item = factor(item_codes[j], levels = item_codes),
             times_chosen = 0:14,
             share_of_draws = tabulate(sim_counts[, j] + 1, nbins = 15) / nrow(sim_counts),
             observed = obs_counts[1, j],
             sim_mean = mean(sim_counts[, j]), sim_q05 = quantile(sim_counts[, j], 0.05, names = FALSE),
             sim_q95 = quantile(sim_counts[, j], 0.95, names = FALSE))
    })
  })
}

plot_symptoms <- function(df, title) {
  ggplot(df, aes(x = item, y = times_chosen)) +
    geom_tile(aes(fill = share_of_draws), width = 0.95, height = 0.95) +
    geom_point(data = distinct(df, label, item, observed), aes(y = observed), colour = "#c0392b", size = 1.3) +
    scale_fill_gradient(low = "white", high = "grey15", limits = c(0, 1), name = "share of the 100 simulated sequences") +
    scale_y_continuous(breaks = c(0, 7, 14)) +
    facet_wrap(~ label, ncol = 4) +
    labs(title = title, x = "Symptom (PHQ-9 code, see ppc_item_key.csv)",
         y = "Times the symptom was chosen (out of the 14 trials it appeared in)",
         subtitle = "Shading: how often the model's simulated sequences chose the symptom this many times. Red dot: the participant's real count.") +
    theme_bw(base_size = 7) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, size = 5), legend.position = "bottom",
          strip.text = element_text(size = 6))
}

for (m in names(sim_choices)) {
  df_sym <- symptom_data_for(m)
  p <- plot_symptoms(df_sym, model_labels[[m]])
  ggsave(file.path(output_dir, paste0("ppc_symptom_choices_", m, ".pdf")), p, width = 13, height = 12)
  if (m == "per") {
    ggsave(file.path(output_dir, "ppc_symptom_choices.png"), p, width = 13, height = 12, dpi = 120)
    df_sym_per <- df_sym
  }
}

# Numbers: is the real count inside the central 90% of the simulated counts?
df_symptom_check <- df_sym_per |>
  distinct(label, item, observed, sim_mean, sim_q05, sim_q95) |>
  mutate(inside = observed >= sim_q05 & observed <= sim_q95)
write_csv(df_symptom_check, file.path(output_dir, "ppc_symptom_choices_sampled_sessions.csv"))

cat("\nSampled sessions, model per: real count inside the simulated central 90%:",
    round(mean(df_symptom_check$inside), 3), "of", nrow(df_symptom_check), "participant x symptom cells\n")
cat("Mean absolute difference (real count - simulated mean):", round(mean(abs(df_symptom_check$observed - df_symptom_check$sim_mean)), 2), "choices\n")
df_cor <- df_symptom_check |> group_by(label) |> summarise(r = cor(observed, sim_mean), .groups = "drop")
cat("Per session correlation across the 15 symptoms (real count vs simulated mean): median", round(median(df_cor$r), 2),
    " range", round(min(df_cor$r), 2), "to", round(max(df_cor$r), 2), "\n")

# Same check over ALL sessions (no plots)
all_check <- map_dfr(names(sim_choices), \(m) {
  map_dfr(waves, \(w) {
    map_dfr(seq_len(nrow(obs_data[[w]]$lookup)), \(s) {
      sc <- chosen_counts(sim_choices[[m]][[w]][, s, ], obs_data[[w]]$left[s, ], obs_data[[w]]$right[s, ])
      oc <- chosen_counts(matrix(obs_data[[w]]$choice[s, ], nrow = 1), obs_data[[w]]$left[s, ], obs_data[[w]]$right[s, ])[1, ]
      tibble(model = model_labels[[m]], time = w, subject = s,
             inside = oc >= apply(sc, 2, quantile, 0.05) & oc <= apply(sc, 2, quantile, 0.95),
             abs_diff = abs(oc - colMeans(sc)), r = suppressWarnings(cor(oc, colMeans(sc))))
    })
  })
})
df_all_summary <- all_check |>
  group_by(model, time, subject) |>
  summarise(share_inside = mean(inside), mean_abs_diff = mean(abs_diff), r = first(r), .groups = "drop") |>
  group_by(model) |>
  summarise(sessions = n(), share_cells_inside_90 = round(mean(share_inside), 3),
            mean_abs_diff_choices = round(mean(mean_abs_diff), 2), median_r_across_symptoms = round(median(r, na.rm = TRUE), 2),
            .groups = "drop")
write_csv(df_all_summary, file.path(output_dir, "ppc_symptom_choices_all_sessions.csv"))
print(df_all_summary)
