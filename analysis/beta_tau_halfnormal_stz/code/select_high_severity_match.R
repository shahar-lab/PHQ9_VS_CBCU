#### ADD A HIGHER-SEVERITY PATIENT WHO MATCHES ONE OF THE FIVE PROFILES ####
# reads: artifacts/profile_patients.csv (from select_profile_patients.R),
#        artifacts/participant_parameters.csv
# writes: artifacts/profile_patients.csv (one row added), output/clinical reports/profile_clusters.csv
#
# Among subjects with a time 1 PHQ-9 sum of at least min_phq9_sum (moderate or above),
# the one whose utility ranking is closest to any of the five picked patients (highest
# Spearman correlation) is added as a sixth patient, with the profile it matches. It shows
# the same symptom pattern at a higher overall severity.

min_phq9_sum <- 10

df_profile_patients <- read_csv(file.path(artifacts_dir, "profile_patients.csv"), show_col_types = FALSE) |>
  filter(is.na(matches_profile))   # rerunning replaces an earlier sixth row

df_time1 <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE) |>
  filter(time == "time1")
u_medians <- df_time1 |> select(u_1:u_15) |> as.matrix()
rownames(u_medians) <- df_time1$prolific_id

candidate_ids <- df_time1 |>
  filter(phq9_sum >= min_phq9_sum, !prolific_id %in% df_profile_patients$prolific_id) |>
  pull(prolific_id)

# Rank correlation of every candidate with every picked patient
rank_correlation <- cor(t(u_medians[candidate_ids, , drop = FALSE]),
                        t(u_medians[df_profile_patients$prolific_id, , drop = FALSE]),
                        method = "spearman")

best      <- which(rank_correlation == max(rank_correlation), arr.ind = TRUE)[1, ]
match_id  <- candidate_ids[best[1]]
match_row <- df_profile_patients[best[2], ]

df_high_severity <- tibble(
  profile                  = nrow(df_profile_patients) + 1,
  prolific_id              = match_id,
  cluster                  = match_row$cluster,
  cluster_size             = match_row$cluster_size,
  mean_distance_in_cluster = NA_real_,
  phq9_sum                 = df_time1$phq9_sum[df_time1$prolific_id == match_id],
  matches_profile          = match_row$profile,
  spearman_r_to_match      = max(rank_correlation))

cat(sprintf("%d candidates with PHQ-9 sum >= %d; best match: %s (PHQ-9 %g), r = %.2f with profile %d (PHQ-9 %g)\n",
            length(candidate_ids), min_phq9_sum, match_id, df_high_severity$phq9_sum,
            df_high_severity$spearman_r_to_match, match_row$profile, match_row$phq9_sum))

df_profile_patients <- bind_rows(df_profile_patients, df_high_severity)

write_csv(df_profile_patients, file.path(artifacts_dir, "profile_patients.csv"))
write_csv(df_profile_patients, file.path(output_clinical_dir, "profile_clusters.csv"))
