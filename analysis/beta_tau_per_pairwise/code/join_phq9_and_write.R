#### JOIN PHQ9 AND WRITE PARTICIPANT TABLE ####

df_phq9 <- read_csv(file.path(data_path, "phq9_results.csv"), show_col_types = FALSE) |>
  select(prolific_id, time, phq9_sum, phq9_1:phq9_9)

# ASSUMED[no join-type given]: left_join with the CBCU-based Bradley-Terry table
# as the primary row population - a prolific_id present in phq9_results.csv but
# absent from the CBCU table is not added as a new row.
df_participant_parameters <- df_bt_params |>
  left_join(df_phq9, by = c("prolific_id", "time"))

write_csv(df_participant_parameters, file.path(artifacts_dir, "participant_parameters.csv"), na = "NA")
