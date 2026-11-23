#### SELECT FIVE PATIENTS WITH DIFFERENT SYMPTOM PROFILES (TIME 1) ####
# reads: artifacts/participant_parameters.csv
# writes: artifacts/profile_patients.csv, output/clinical reports/profile_clusters.csv
#
# Each subject's profile is the ranking of their 15 time 1 utilities (posterior medians).
# Profiles are compared with Spearman distance (1 - rank correlation) and grouped into
# n_profiles clusters with k-medoids (PAM). One subject is picked per cluster: clusters
# are taken largest first, and from each the most central subject (smallest mean distance
# to the rest of the cluster - the medoid, unless its PHQ-9 sum is already taken) whose
# time 1 PHQ-9 sum differs from every earlier pick, so the patients also differ in sum.
# (Hierarchical clustering with average linkage was tried first: it put 175 of 185
# subjects in one cluster and the rest in 1-4 subject clusters, so it was replaced.)

n_profiles <- 5

df_time1 <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE) |>
  filter(time == "time1")

u_medians <- df_time1 |>
  select(u_1:u_15) |>
  as.matrix()
rownames(u_medians) <- df_time1$prolific_id

spearman_distance <- 1 - cor(t(u_medians), method = "spearman")
profile_clusters  <- pam(as.dist(spearman_distance), k = n_profiles, diss = TRUE)
cat(sprintf("Average silhouette width of the %d clusters: %.2f\n",
            n_profiles, profile_clusters$silinfo$avg.width))

df_profiles <- df_time1 |>
  select(prolific_id, phq9_sum) |>
  mutate(cluster = profile_clusters$clustering) |>
  add_count(cluster, name = "cluster_size") |>
  group_by(cluster) |>
  mutate(mean_distance_in_cluster = map_dbl(prolific_id, \(id) {
    others <- setdiff(prolific_id, id)
    if (length(others) == 0) 0 else mean(spearman_distance[id, others])
  })) |>
  ungroup()

# Greedy pick, largest cluster first: most central subject with a PHQ-9 sum not yet used
clusters_by_size <- df_profiles |>
  distinct(cluster, cluster_size) |>
  arrange(desc(cluster_size)) |>
  pull(cluster)

picked_ids  <- character(0)
picked_sums <- numeric(0)
for (cl in clusters_by_size) {
  candidate <- df_profiles |>
    filter(cluster == cl, !is.na(phq9_sum), !phq9_sum %in% picked_sums) |>
    slice_min(mean_distance_in_cluster, n = 1, with_ties = FALSE)
  if (nrow(candidate) == 0) {
    warning(sprintf("Cluster %d has no subject with an unused PHQ-9 sum; no patient picked from it", cl))
    next
  }
  picked_ids  <- c(picked_ids, candidate$prolific_id)
  picked_sums <- c(picked_sums, candidate$phq9_sum)
}

df_profile_patients <- df_profiles |>
  filter(prolific_id %in% picked_ids) |>
  mutate(profile = match(prolific_id, picked_ids)) |>
  arrange(profile) |>
  select(profile, prolific_id, cluster, cluster_size, mean_distance_in_cluster, phq9_sum) |>
  mutate(matches_profile = NA_integer_, spearman_r_to_match = NA_real_)   # filled for the match added by select_high_severity_match.R

print(df_profile_patients)

write_csv(df_profile_patients, file.path(artifacts_dir, "profile_patients.csv"))
write_csv(df_profile_patients, file.path(output_clinical_dir, "profile_clusters.csv"))
