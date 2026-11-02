# reads: data/processed/cbcu.csv · writes: artifacts/rt_selected.rds

#### PREPARE SELECTED PARTICIPANTS ####

# ASSUMED[raw vs processed]: read from data/processed because analyses only read processed
# data. The selected participants lost no trials in processing (105 per session, no
# missing RT), so this equals their raw trials.
df <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE) |>
  filter(prolific_id %in% selected_ids) |>
  mutate(rt_sec = rt / 1000,
         time   = factor(time, levels = c("time1", "time2")))

stopifnot(setequal(unique(df$prolific_id), selected_ids))

saveRDS(df, file.path(artifacts_dir, "rt_selected.rds"))
