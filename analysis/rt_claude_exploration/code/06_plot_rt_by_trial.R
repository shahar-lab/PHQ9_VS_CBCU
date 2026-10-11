#### PLOT RT BY TRIAL ####
# reads: artifacts/df_trials.rds · writes: output/06_rt_by_trial.{pdf,png}

df <- readRDS(file.path(artifacts_dir, "df_trials.rds")) |>
  filter(!is.na(trial), !is.na(rt))

point_colour <- "#4477AA"
line_colour  <- "#EE6677"
x_breaks     <- c(1, 36, 70, 105)
y_breaks     <- seq(0, rt_axis_cap, length.out = 4)

cat("Trials above the RT axis cap (", rt_axis_cap, "ms ):\n")
print(df |> group_by(agent) |> summarise(n_above_cap = sum(rt > rt_axis_cap), n_trials = n()))

df_claude <- filter(df, agent == "Claude")
df_human  <- filter(df, agent == "Human")

r_claude <- cor(df_claude$trial, df_claude$rt)
r_human  <- cor(df_human$trial, df_human$rt)

shape_skip <- scale_shape_manual(values = c("FALSE" = 16, "TRUE" = 1), name = "Skipped trial")
panel_theme <- theme_minimal(base_size = 13) +
  theme(aspect.ratio = 1, panel.grid.minor = element_blank())

p_claude <- ggplot(df_claude, aes(x = trial, y = rt)) +
  geom_point(aes(shape = skipped), colour = point_colour, alpha = 0.75, size = 2) +
  geom_smooth(method = "loess", formula = y ~ x, se = TRUE, colour = line_colour,
              fill = line_colour, alpha = 0.2, linewidth = 0.8) +
  annotate("text", x = Inf, y = Inf, label = sprintf("[Pearson r = %.2f]", r_claude),
           hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
  scale_x_continuous(breaks = x_breaks) +
  scale_y_continuous(breaks = y_breaks) +
  shape_skip +
  coord_cartesian(ylim = c(0, rt_axis_cap)) +
  panel_theme +
  labs(x = "Trial (presentation order)", y = "RT (ms)", subtitle = "Claude")

p_human <- ggplot(df_human, aes(x = trial, y = rt)) +
  geom_point(aes(shape = skipped), colour = point_colour, alpha = 0.15, size = 2) +
  geom_smooth(aes(group = unit), method = "loess", formula = y ~ x, se = FALSE,
              colour = point_colour, alpha = 0.6, linewidth = 0.3) +
  geom_smooth(method = "loess", formula = y ~ x, se = FALSE, colour = line_colour, linewidth = 1) +
  annotate("text", x = Inf, y = Inf, label = sprintf("[Pearson r = %.2f]", r_human),
           hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
  scale_x_continuous(breaks = x_breaks) +
  scale_y_continuous(breaks = y_breaks) +
  shape_skip +
  coord_cartesian(ylim = c(0, rt_axis_cap)) +
  guides(shape = "none") +
  panel_theme +
  labs(x = "Trial (presentation order)", y = "RT (ms)", subtitle = "Humans (thin: sessions; rose: pooled)")

p_final <- (p_claude | p_human) +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14), legend.position = "bottom")

plot_name <- "06_rt_by_trial"

ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = p_final, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p_final, width = 10, height = 8, dpi = 300, bg = "white")
