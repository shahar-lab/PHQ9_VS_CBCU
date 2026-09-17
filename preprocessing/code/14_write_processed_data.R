# reads: artifacts/13_after_trial_rate.rds, data/raw/phq9_results.csv
# writes: data/processed/cbcu.csv, data/processed/phq.csv

#### WRITE PROCESSED CBCU AND PHQ ####

step13 <- readRDS(file.path(artifacts_dir, "13_after_trial_rate.rds"))
phq9_results <- read_csv(file.path(raw_dir, "phq9_results.csv"), show_col_types = FALSE)

cbcu <- step13$after_trial_rate_cbcu

phq <- phq9_results |>
  mutate(prolific_id = as.character(prolific_id)) |>
  filter(prolific_id %in% step13$after_trial_rate_pids)

write_csv(cbcu, file.path(processed_dir, "cbcu.csv"), na = "NA")
write_csv(phq,  file.path(processed_dir, "phq.csv"),  na = "NA")
