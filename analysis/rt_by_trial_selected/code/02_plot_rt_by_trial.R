# reads: artifacts/rt_selected.rds · writes: output/02_rt_by_trial.pdf, output/02_rt_by_trial.png

#### PLOT RT BY TRIAL ####

df <- readRDS(file.path(artifacts_dir, "rt_selected.rds"))

p_rt_by_trial <- ggplot(df, aes(x = trial, y = rt_sec, colour = time)) +
  geom_line(linewidth = 0.5, alpha = 0.8) +
  geom_point(size = 1.2, alpha = 0.8) +
  facet_wrap(~ prolific_id, ncol = 2) +
  scale_colour_manual(values = c(time1 = "#4477AA", time2 = "#EE6677"), name = NULL) +
  scale_x_continuous(breaks = c(1, seq(15, 105, by = 15))) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank(), legend.position = "top") +
  labs(x = "Trial", y = "RT (seconds)")

plot_name <- "02_rt_by_trial"

ggsave(file.path(output_dir, paste0(plot_name, ".pdf")),
       plot = p_rt_by_trial, width = 10, height = 8, bg = "white")

ggsave(file.path(output_dir, paste0(plot_name, ".png")),
       plot = p_rt_by_trial, width = 10, height = 8, dpi = 300, bg = "white")
