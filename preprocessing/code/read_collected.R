#### READ COLLECTED DATA ####

# One CSV per participant per wave; read every CSV present in each wave folder
# rather than a hardcoded filename, so the pipeline scales as more sessions arrive.
first_wave_files  <- list.files(file.path(collected_dir, "first_wave"),  pattern = "\\.csv$", full.names = TRUE)
second_wave_files <- list.files(file.path(collected_dir, "second_wave"), pattern = "\\.csv$", full.names = TRUE)

first_wave <- first_wave_files |>
  purrr::map(readr::read_csv, col_types = readr::cols(.default = "c")) |>
  purrr::list_rbind() |>
  dplyr::mutate(study_session = "session_1")

# second_wave's raw column is named session_id in the same position/meaning as
# first_wave's prolific_session_id — rename so both waves combine under one name.
second_wave <- second_wave_files |>
  purrr::map(readr::read_csv, col_types = readr::cols(.default = "c")) |>
  purrr::list_rbind() |>
  dplyr::rename(prolific_session_id = session_id) |>
  dplyr::mutate(study_session = "session_2")

collected <- dplyr::bind_rows(first_wave, second_wave)
