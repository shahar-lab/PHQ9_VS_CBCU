#### JOIN PHQ9 AND WRITE PARTICIPANT TABLE ####
# writes: artifacts/participant_parameters.csv (one row per subject)

# The model has one set of parameters per subject, so PHQ9 is also one value per subject:
# the sum score and each item are averaged over the sessions the subject has.
df_phq9 <- read_csv(file.path(data_path, "phq.csv"), show_col_types = FALSE) |>
  group_by(prolific_id) |>
  summarise(n_phq9_sessions = n(),
            across(c(phq9_sum, phq9_1:phq9_9), \(x) mean(x, na.rm = TRUE)),
            .groups = "drop")

# ASSUMED[no join-type given]: left_join with the CBCU-based Bradley-Terry table
# as the primary row population - a prolific_id present in phq.csv but
# absent from the CBCU table is not added as a new row.
df_participant_parameters <- df_bt_params |>
  left_join(df_phq9, by = "prolific_id")

write_csv(df_participant_parameters, file.path(artifacts_dir, "participant_parameters.csv"), na = "NA")
