# reads: artifacts/12_after_rt_bounds.rds, data/raw/phq9_results.csv
# writes: data/processed/cbcu.csv, data/processed/phq.csv

#### WRITE PROCESSED CBCU AND PHQ ####

step12 <- readRDS(file.path(artifacts_dir, "12_after_rt_bounds.rds"))
phq9_results <- read_csv(file.path(raw_dir, "phq9_results.csv"), show_col_types = FALSE)

cbcu <- step12$after_rt_bounds

phq <- phq9_results |>
  mutate(prolific_id = as.character(prolific_id)) |>
  filter(prolific_id %in% step12$after_window_exits_pids)

write_csv(cbcu, file.path(processed_dir, "cbcu.csv"), na = "NA")
write_csv(phq,  file.path(processed_dir, "phq.csv"),  na = "NA")
