#### MODEL: <model_name> ####
# Generating code for the <model_name> model.
# Lives in models/<model_name>/ alongside <model_name>.stan (project_rules §2.III).
# Fitting and evaluation happen in analysis/ or simulation/ folders, never here.

generate_<model_name> <- function(n_subjects, n_trials, params) {
  # simulate data from the model
}