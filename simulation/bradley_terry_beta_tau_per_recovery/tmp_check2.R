df <- readRDS("artifacts/simulated_data.rds")
s1 <- df[df$subject == 37, c("trial","offer_A","offer_B","choice")]
head(s1, 15)

# fraction of trials where the option chosen on trial t appears again (in either slot) on trial t+1
frac_repeat <- sapply(unique(df$subject), function(s) {
  sub <- df[df$subject == s, ]
  sub <- sub[order(sub$trial), ]
  n <- nrow(sub)
  chosen_option <- ifelse(sub$choice == "A", sub$offer_A, ifelse(sub$choice == "B", sub$offer_B, NA))
  next_has_it <- sapply(1:(n-1), function(i) {
    if (is.na(chosen_option[i])) return(NA)
    chosen_option[i] %in% c(sub$offer_A[i+1], sub$offer_B[i+1])
  })
  mean(next_has_it, na.rm = TRUE)
})
cat("mean fraction of trials where previously-chosen option reappears next trial:", mean(frac_repeat), "\n")
cat("N_options = 15, so random chance with 2 draws out of remaining 14 ~= 2/14 =", 2/14, "\n")
