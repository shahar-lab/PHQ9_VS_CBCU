# reads: data/collected · writes: artifacts/collected.rds, artifacts/demographics_collected.rds

#### READ COLLECTED DATA ####

# One CSV per participant per session; read every CSV present in each session folder
# rather than a hardcoded filename, so the pipeline scales as more sessions arrive.
session_folders <- c(time1 = "session 1", time2 = "session 2")

read_session <- function(time_label) {
  list.files(file.path(collected_dir, session_folders[[time_label]]),
             pattern = "\\.csv$", full.names = TRUE) |>
    map(read_csv, col_types = cols(.default = "c")) |>
    list_rbind() |>
    mutate(time = time_label)
}

# ASSUMED[not stated where the prolific_pid->prolific_id rename happens]: renamed here, on
# `collected`, since every downstream build_*_raw.R and QA script reads this column via
# common_cols/direct reference and expects it already named prolific_id.
# session_id is NA in early files; NA means session_1, any other value is kept.
collected <- names(session_folders) |>
  map(read_session) |>
  list_rbind() |>
  rename(prolific_id = prolific_pid) |>
  mutate(session_id = if_else(is.na(session_id), "session_1", session_id))

#### READ COLLECTED DEMOGRAPHICS (Qualtrics exports) ####

# Qualtrics exports carry two extra header rows (question text, import ids) under the
# column names; both are dropped from the data. Each export is kept as its own table,
# named by its file.
demographics_files <- list.files(collected_dir, pattern = "^(demographic survey|MacArthur).*\\.csv$",
                                 full.names = TRUE)

demographics_collected <- demographics_files |>
  map(\(f) read_csv(f, col_types = cols(.default = "c")) |> slice(-(1:2))) |>
  set_names(basename(demographics_files))

saveRDS(collected, file.path(artifacts_dir, "collected.rds"))
saveRDS(demographics_collected, file.path(artifacts_dir, "demographics_collected.rds"))
