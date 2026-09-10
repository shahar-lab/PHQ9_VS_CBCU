#### READ COLLECTED DATA ####

# One CSV per participant per wave; read every CSV present in each wave folder
# rather than a hardcoded filename, so the pipeline scales as more sessions arrive.
first_wave_files  <- list.files(file.path(collected_dir, "first_wave"),  pattern = "\\.csv$", full.names = TRUE)
second_wave_files <- list.files(file.path(collected_dir, "second_wave"), pattern = "\\.csv$", full.names = TRUE)

first_wave <- first_wave_files |>
  map(read_csv, col_types = cols(.default = "c")) |>
  list_rbind() |>
  mutate(time = "time1")

second_wave <- second_wave_files |>
  map(read_csv, col_types = cols(.default = "c")) |>
  list_rbind() |>
  mutate(time = "time2")

# ASSUMED[not stated where the prolific_pid->prolific_id rename happens]: renamed here, on
# `collected`, since every downstream build_*_raw.R and QA script reads this column via
# common_cols/direct reference and expects it already named prolific_id.
collected <- bind_rows(first_wave, second_wave) |>
  rename(prolific_id = prolific_pid)

#### READ COLLECTED DEMOGRAPHICS (Prolific export) ####

demographics_file <- list.files(collected_dir, pattern = "^prolific_demographic_export.*\\.csv$",
                                 full.names = TRUE)

demographics_collected <- demographics_file |>
  read_csv(col_types = cols(.default = "c"))
