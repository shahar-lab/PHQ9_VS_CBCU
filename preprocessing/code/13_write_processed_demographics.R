# reads: artifacts/12_after_rt_bounds.rds, data/raw/demographics.csv
# writes: data/processed/demographics.csv

#### WRITE PROCESSED DEMOGRAPHICS (SURVIVING PARTICIPANTS ONLY) ####

# Not an exclusion criterion: processed demographics keep only the participants whose
# task data survives steps 10-12, so they match data/processed/cbcu.csv and phq.csv.
step12       <- readRDS(file.path(artifacts_dir, "12_after_rt_bounds.rds"))
demographics <- read_csv(file.path(raw_dir, "demographics.csv"), show_col_types = FALSE)

demographics_processed <- demographics |>
  filter(prolific_id %in% step12$after_window_exits_pids)

write_csv(demographics_processed, file.path(processed_dir, "demographics.csv"), na = "NA")
