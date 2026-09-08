#### READ COLLECTED DATA ####

# One CSV per participant per wave; read every CSV present in each wave folder
# rather than a hardcoded filename, so the pipeline scales as more sessions arrive.
first_wave_files  <- list.files(file.path(collected_dir, "first_wave"),  pattern = "\\.csv$", full.names = TRUE)
second_wave_files <- list.files(file.path(collected_dir, "second_wave"), pattern = "\\.csv$", full.names = TRUE)

# Both waves' raw column is named session_id; one early first_wave pilot file
# additionally has its own prolific_session_id — coalesce so every session ends
# up under the one name the rest of the pipeline expects.
first_wave <- first_wave_files |>
  map(read_csv, col_types = cols(.default = "c")) |>
  list_rbind() |>
  mutate(
    prolific_session_id = coalesce(prolific_session_id, session_id),
    study_session        = "session_1"
  ) |>
  select(-session_id)

second_wave <- second_wave_files |>
  map(read_csv, col_types = cols(.default = "c")) |>
  list_rbind() |>
  rename(prolific_session_id = session_id) |>
  mutate(study_session = "session_2")

collected <- bind_rows(first_wave, second_wave)

#### READ COLLECTED DEMOGRAPHICS (Prolific export) ####

demographics_file <- list.files(collected_dir, pattern = "^prolific_demographic_export.*\\.csv$",
                                 full.names = TRUE)

demographics_collected <- demographics_file |>
  read_csv(col_types = cols(.default = "c"))
