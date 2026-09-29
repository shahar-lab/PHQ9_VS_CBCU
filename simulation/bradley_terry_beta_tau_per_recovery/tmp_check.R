kd <- readRDS("artifacts/key_decay_recovery.rds")
df <- readRDS("artifacts/simulated_data.rds")
true_rho <- df[!duplicated(df$subject), c("subject","true_rho")]
m <- merge(kd, true_rho, by="subject")
m$abs_rho <- abs(m$true_rho)
m$abs_bias <- abs(m$recovered_value - m$true_value)
cat("cor(abs_rho, abs_bias):", cor(m$abs_rho, m$abs_bias), "\n")
m <- m[order(m$true_value),]
print(head(m, 20))
