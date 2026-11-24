#### COMPARE WITH THE BETA MODEL (beta_tau_halfnormal_stz) ####
# reads: artifacts/participant_parameters.csv (this model),
#        analysis/beta_tau_halfnormal_stz/artifacts/participant_parameters.csv (beta model)
# writes: output/comparison with beta model/{sigma_vs_beta,sigma_vs_implied_sigma,tau_vs_beta_model,
#         utility_vs_beta_model}.png, artifacts/comparison_with_beta_model.csv
#
# Same participants, same data, two models. Per participant x time (posterior medians):
#   sigma vs beta                 : does the new consistency parameter order people like beta?
#   sigma vs implied sigma        : implied sigma = SD of beta * [u_1..u_15, tau] in the beta
#                                   model (same definition as sigma: SD of the 16 logits,
#                                   marginal-SD scaling sqrt(16/15)); the two should agree
#                                   if the models tell the same story
#   tau, u on the logit scale     : beta model's beta * tau and beta * u vs this model's tau and u
#                                   (centred within participant over the 16 logits, since the
#                                   two models fix the location differently)
# Skipped with a message if the beta-model table is not there.

beta_model_path <- file.path(project_root, "analysis", "beta_tau_halfnormal_stz", "artifacts",
                             "participant_parameters.csv")

if (!file.exists(beta_model_path)) {
  message("compare_with_beta_model.R: ", beta_model_path, " not found, comparison skipped")
} else {

  output_compare_dir <- file.path(output_dir, "comparison with beta model")
  dir.create(output_compare_dir, showWarnings = FALSE, recursive = TRUE)

  u_cols <- paste0("u_", 1:15)

  # Both models on the logit scale, centred within participant x time over the 16 logits
  to_centred_logits <- function(df, scale_col = NULL) {
    m <- as.matrix(df[, c(u_cols, "tau")])
    if (!is.null(scale_col)) m <- m * df[[scale_col]]
    m <- m - rowMeans(m)
    colnames(m) <- c(u_cols, "tau")
    as_tibble(m)
  }

  df_sigma_model <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)
  df_beta_model  <- read_csv(beta_model_path, show_col_types = FALSE)

  df_beta_logits <- df_beta_model |>
    select(prolific_id, time, beta) |>
    bind_cols(to_centred_logits(df_beta_model, "beta")) |>
    rowwise() |>
    mutate(implied_sigma = sqrt(mean(c_across(all_of(c(u_cols, "tau")))^2) * 16 / 15)) |>
    ungroup()

  df_sigma_logits <- df_sigma_model |>
    select(prolific_id, time, sigma) |>
    bind_cols(to_centred_logits(df_sigma_model))

  df_compare <- inner_join(df_sigma_logits, df_beta_logits, by = c("prolific_id", "time"),
                           suffix = c("_sigma_model", "_beta_model"))

  cat(sprintf("Comparison with beta model: %d participant x time rows\n", nrow(df_compare)))

  write_csv(df_compare, file.path(artifacts_dir, "comparison_with_beta_model.csv"))

  # One panel per time. same_units = TRUE: identity line and equal, shared axes
  plot_compare <- function(df_long, x_label, y_label, plot_name, xlim, ylim = xlim, same_units = TRUE) {
    df_r <- df_long |> group_by(time) |> summarise(r = cor(x, y), .groups = "drop")
    p <- ggplot(df_long, aes(x = x, y = y)) +
      {if (same_units) geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60")} +
      geom_point(colour = "#4477AA", alpha = 0.6, size = 1.8) +
      geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
      geom_text(data = df_r, aes(x = Inf, y = -Inf, label = sprintf("[Pearson r = %.2f]", r)),
                inherit.aes = FALSE, hjust = 1.05, vjust = -0.8, size = 3.5, colour = "grey30") +
      facet_wrap(~time, labeller = as_labeller(c(time1 = "Time 1", time2 = "Time 2"))) +
      {if (same_units) coord_equal(xlim = xlim, ylim = ylim) else coord_cartesian(xlim = xlim, ylim = ylim)} +
      theme_minimal(base_size = 13) +
      theme(panel.grid.minor = element_blank()) +
      labs(x = x_label, y = y_label)
    ggsave(file.path(output_compare_dir, paste0(plot_name, ".png")),
           plot = p, width = 12, height = 6.5, dpi = 300, bg = "white")
    p
  }

  positive_limits  <- \(v) c(0, max(v) + 0.20 * diff(range(v)))
  symmetric_limits <- \(v) c(-1, 1) * 1.05 * max(abs(v))

  # sigma vs beta: different units, so no identity line; both axes start at 0
  df_sb <- transmute(df_compare, time, x = beta, y = sigma)
  p_sigma_vs_beta <- plot_compare(df_sb, "beta (beta model)", "sigma (sigma model)", "sigma_vs_beta",
                                  xlim = positive_limits(df_sb$x), ylim = positive_limits(df_sb$y),
                                  same_units = FALSE)

  df_si <- transmute(df_compare, time, x = implied_sigma, y = sigma)
  p_sigma_vs_implied <- plot_compare(df_si, "implied sigma (beta model: SD of beta * [u, tau])",
                                     "sigma (sigma model)", "sigma_vs_implied_sigma",
                                     xlim = positive_limits(c(df_si$x, df_si$y)))

  df_tau <- transmute(df_compare, time, x = tau_beta_model, y = tau_sigma_model)
  p_tau <- plot_compare(df_tau, "beta * tau (beta model, centred logit)", "tau (sigma model, centred logit)",
                        "tau_vs_beta_model", xlim = symmetric_limits(c(df_tau$x, df_tau$y)))

  df_u <- df_compare |>
    select(time, prolific_id, paste0(u_cols, "_sigma_model"), paste0(u_cols, "_beta_model")) |>
    pivot_longer(-c(time, prolific_id), names_to = c("item", "model"),
                 names_pattern = "^(u_\\d+)_(sigma|beta)_model$") |>
    pivot_wider(names_from = model, values_from = value) |>
    transmute(time, x = beta, y = sigma)
  p_u <- plot_compare(df_u, "beta * u (beta model, centred logit)", "u (sigma model, centred logit)",
                      "utility_vs_beta_model", xlim = symmetric_limits(c(df_u$x, df_u$y)))
}
