Job Card
JOB
Pick 5 patients with heterogeneous utility rankings and show a pilot-style clinical report for each (time 1 fit)
FOLDER
analysis/beta_tau_halfnormal_stz/ (existing)
ROUTED READS
- visualization/standards/COLOR_STANDARD.md
- visualization/standards/EXPORT_STANDARD.md
- visualization/standards/PANEL_TAGGING_STANDARD.md
CHECKS
—
SPECIFICATION
- Reference: PHQ9_pairwise_pilot/analysis/beta_tau_pairwise/code (prep_clinical_report.R, prep_burden_threshold.R, prep_consistency.R, plot_clinical_report.R)
- Fit: time 1 only (artifacts/fit_time1.rds)
- Selection: Spearman distance (1 - rank correlation) between subjects' time 1 posterior-median utility vectors; hierarchical clustering, average linkage, 5 clusters; clusters taken largest first; from each, the most central subject (smallest mean distance to its cluster) whose time 1 PHQ-9 sum differs from every earlier pick (5 distinct sums)
- Eligibility: no filter (all 185 subjects)
- Ladder: utility posterior median and 90% HDI; tiers where adjacent items differ with probability >= 0.90; strip = time 1 PHQ-9 answer (0-3) of the PHQ-9 item each CBCU item maps to
- Burden threshold: tau (None beats an item when u < tau); count of items with u > tau per draw (median, 90% interval); verdicts >= 13 permissive, 8-12 balanced, 4-7 selective, < 4 highly selective; never chose None -> lower bound only
- Severity: time 1 PHQ-9 sum, 0-27 bar, bands Minimal 0-4, Mild 5-9, Moderate 10-14, Moderately severe 15-19, Severe 20-27; sum score shown in header and on the bar; no uncertainty shading
- Consistency: time 1 P(higher-utility option | not None) from artifacts/p_higher_option.csv (median, 95% interval); verdicts < 0.70 low, 0.70-0.85 moderate, >= 0.85 high
- Outputs: output/clinical reports/clinical_report.pdf (5 pages), clinical_report_<id>.png per patient, profile_clusters.csv
