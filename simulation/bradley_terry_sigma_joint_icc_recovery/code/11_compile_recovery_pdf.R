#### COMPILE RECOVERY PDF ####
# reads:  artifacts/figure_1.rds ... figure_4.rds
# writes: output/11_recovery_figures.pdf (one figure per page, vector)

pdf(file.path(output_dir, "11_recovery_figures.pdf"), width = 12, height = 10, onefile = TRUE)
for (f in 1:4) {
  print(readRDS(file.path(artifacts_dir, sprintf("figure_%d.rds", f))))
}
dev.off()
