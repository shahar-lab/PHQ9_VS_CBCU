#### SUMMARY TABLE (at-a-glance page) ####

overall_summary <- tibble::tibble(
  metric = c("Starting participants", "Excluded participants", "Retained participants",
             "Final observations"),
  value = c(n_starting,
            dplyr::n_distinct(excluded_participants$prolific_pid),
            dplyr::n_distinct(cbcu_results_processed$prolific_pid),
            format(nrow(cbcu_results_processed), big.mark = ","))
)

#### WRITE MULTI-PAGE PDF (mirrors raw_data_qa_report.R's render_table_page pattern) ####

grDevices::pdf(file.path(output_dir, "raw_to_processed_report.pdf"), width = 10, height = 8, bg = "white")

render_table_page(excluded_participants, "Excluded participants and reasons")
render_table_page(per_participant_after_exclusion,
                   "Retained participants — % excluded of that session's original trial count")
render_table_page(overall_summary, "Raw-to-processed summary")

grDevices::dev.off()
