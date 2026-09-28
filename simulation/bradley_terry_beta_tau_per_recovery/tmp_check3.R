df <- readRDS("artifacts/simulated_data.rds")

# magnitude of key_value terms relative to beta*u term
df$beta_u1 <- NA  # not stored directly, but key_value_A/B/None are stored
cat("summary |key_value_A|:\n"); print(summary(abs(df$key_value_A)))
cat("summary |key_value_B|:\n"); print(summary(abs(df$key_value_B)))
cat("summary |key_value_None|:\n"); print(summary(abs(df$key_value_None)))

true_params <- df[!duplicated(df$subject), c("subject","true_beta","true_tau","true_key_decay","true_rho")]
cat("\ntrue_rho summary:\n"); print(summary(abs(true_params$true_rho)))
cat("\nbeta*u magnitude (u is standardized sd=1):\n")
print(summary(abs(true_params$true_beta)))  # beta scales u which has sd 1, so beta*u ~ sd(beta)

# does key_decay predict how much key_value varies within subject (a measure of whether decay is visible)?
library(dplyr)
per_subj <- df |>
  group_by(subject) |>
  summarise(sd_keyA = sd(key_value_A), sd_keyNone = sd(key_value_None), .groups="drop") |>
  left_join(true_params, by="subject")

cat("\ncor(true_key_decay, sd_keyA):", cor(per_subj$true_key_decay, per_subj$sd_keyA), "\n")
cat("cor(true_rho, sd_keyA):", cor(abs(per_subj$true_rho), per_subj$sd_keyA), "\n")
cat("\nrange of sd_keyA:\n"); print(summary(per_subj$sd_keyA))
