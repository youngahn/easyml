foo <- structure(list(), class = c("easy_glmnet", "gaussian"))
print(foo)
bar <- structure(list(), class = c("easy_glmnet", "binomial"))
print(bar)

#' TO BE EDITED.
#' 
#' TO BE EDITED.
#'
#' @return TO BE EDITED.
#' @export
easy_glmnet <- function(.data, dependent_variable, family = "gaussian", 
                        sampler = NULL, preprocessor = NULL, 
                        exclude_variables = NULL, categorical_variables = NULL, 
                        train_size = 0.667, survival_rate_cutoff = 0.05, 
                        n_samples = 1000, n_divisions = 1000, 
                        n_iterations = 10, out_directory = ".", 
                        random_state = NULL, progress_bar = TRUE, 
                        n_core = 1, ...) {
  # capture keyword arguments?
  kargs <- list(...)
  
  # Set sampler function
  sampler <- set_sampler(sampler, family)
  
  # Set preprocessor function
  preprocessor <- set_preprocessor(preprocessor)
  
  # Set random state
  set_random_state(random_state)
  
  # Set column names
  column_names <- colnames(.data)
  column_names <- set_column_names(column_names, dependent_variable, 
                                   preprocessor, exclude_variables, 
                                   categorical_variables)
  
  # Set categorical variables
  categorical_variables <- set_categorical_variables(column_names, 
                                                     categorical_variables)
  
  # Remove variables
  .data <- remove_variables(.data, exclude_variables)
  
  # Isolate dependent variable
  y <- isolate_dependent_variable(.data, dependent_variable)
  
  # Isolate independent variables
  X <- isolate_independent_variables(.data, dependent_variable)
  
  # Call to underlying function
  easy_glmnet_(y, X, family, sampler, preprocessor, 
               categorical_variables = NULL, 
               train_size = 0.667, survival_rate_cutoff = 0.05, 
               n_samples = 1000, n_divisions = 1000, 
               n_iterations = 10, out_directory = ".", 
               random_state = NULL, progress_bar = TRUE, 
               n_core = 1, ...)
}

#' TO BE EDITED.
#' 
#' TO BE EDITED.
#'
#' @return TO BE EDITED.
#' @export
easy_glmnet_ <- function(y, X, sampler, preprocessor, 
                         categorical_variables = NULL, 
                         train_size = 0.667, survival_rate_cutoff = 0.05, 
                         n_samples = 1000, n_divisions = 1000, 
                         n_iterations = 10, out_directory = ".", 
                         random_state = NULL, progress_bar = TRUE, 
                         n_core = 1, ...) {
  # assess family of regression
  if (family == "gaussian") {
    easy_glmnet_gaussian(y, X, family, sampler, preprocessor, 
                         categorical_variables = NULL, 
                         train_size = 0.667, survival_rate_cutoff = 0.05, 
                         n_samples = 1000, n_divisions = 1000, 
                         n_iterations = 10, out_directory = ".", 
                         random_state = NULL, progress_bar = TRUE, 
                         n_core = 1, ...)
  } else if (family == "binomial") {
    easy_glmnet_binomial(y, X, sampler, preprocessor, 
                         categorical_variables = NULL, 
                         train_size = 0.667, survival_rate_cutoff = 0.05, 
                         n_samples = 1000, n_divisions = 1000, 
                         n_iterations = 10, out_directory = ".", 
                         random_state = NULL, progress_bar = TRUE, 
                         n_core = 1, ...)
  } else {
    stop("Value error.")
  }
}

#' TO BE EDITED.
#' 
#' TO BE EDITED.
#'
#' @return TO BE EDITED.
#' @export
easy_glmnet_gaussian <- function(y, X, sampler, preprocessor, 
                                 categorical_variables = NULL, 
                                 train_size = 0.667, survival_rate_cutoff = 0.05, 
                                 n_samples = 1000, n_divisions = 1000, 
                                 n_iterations = 10, out_directory = ".", 
                                 random_state = NULL, progress_bar = TRUE, 
                                 n_core = 1, ...) {
  # Bootstrap coefficients
  coefs <- bootstrap_coefficients(glmnet_fit_model_gaussian, glmnet_extract_coefficients, 
                                  preprocessor, X, y, 
                                  categorical_variables = categorical_variables, 
                                  n_samples = n_samples, 
                                  progress_bar = progress_bar, 
                                  n_core = n_core, ...)
  
  # Process coefficients
  betas <- process_coefficients(coefs, column_names, 
                                survival_rate_cutoff = survival_rate_cutoff)
  plot_betas(betas)
  ggplot2::ggsave(file.path(out_directory, "betas.png"))
  
  # Split data
  split_data <- sampler(X, y, train_size = train_size)
  X_train <- split_data[["X_train"]]
  X_test <- split_data[["X_test"]]
  y_train <- split_data[["y_train"]]
  y_test <- split_data[["y_test"]]
  
  # Bootstrap predictions
  predictions <- bootstrap_predictions(glmnet_fit_model_gaussian, glmnet_predict_model, 
                                       preprocessor, 
                                       X_train, y_train, X_test, 
                                       categorical_variables = categorical_variables, 
                                       n_samples = n_samples, 
                                       progress_bar = progress_bar, 
                                       n_core = n_core, ...)
  y_train_predictions <- predictions[["y_train_predictions"]]
  y_test_predictions <- predictions[["y_test_predictions"]]
  
  # Take average of predictions for training and test sets
  y_train_predictions_mean <- apply(y_train_predictions, 1, mean)
  y_test_predictions_mean <- apply(y_test_predictions, 1, mean)
  
  # Plot the gaussian predictions for training
  plot_gaussian_predictions(y_train, y_train_predictions_mean)
  ggplot2::ggsave(file.path(out_directory, "train_gaussian_predictions.png"))
  
  # Plot the gaussian predictions for test
  plot_gaussian_predictions(y_test, y_test_predictions_mean)
  ggplot2::ggsave(file.path(out_directory, "test_gaussian_predictions.png"))
  
  # Bootstrap training and test MSEs
  mses <- bootstrap_mses(glmnet_fit_model_gaussian, glmnet_predict_model, 
                         sampler, preprocessor, X, y, 
                         categorical_variables = categorical_variables, 
                         n_divisions = n_divisions, 
                         n_iterations = n_iterations, 
                         progress_bar = progress_bar, n_core = n_core, ...)
  train_mses <- mses[["mean_train_metrics"]]
  test_mses <- mses[["mean_test_metrics"]]
  
  # Plot histogram of training MSEs
  plot_mse_histogram(train_mses)
  ggplot2::ggsave(file.path(out_directory, "train_mse_distribution.png"))
  
  # Plot histogram of test MSEs
  plot_mse_histogram(test_mses)
  ggplot2::ggsave(file.path(out_directory, "test_mse_distribution.png"))
}

#' TO BE EDITED.
#' 
#' TO BE EDITED.
#'
#' @return TO BE EDITED.
#' @export
easy_glmnet_binomial <- function(...) {
  # Bootstrap coefficients
  coefs <- bootstrap_coefficients(glmnet_fit_model_binomial, glmnet_extract_coefficients, 
                                  preprocessor, X, y, 
                                  categorical_variables = categorical_variables, 
                                  n_samples = n_samples, 
                                  progress_bar = progress_bar, 
                                  n_core = n_core, ...)
  
  # Process coefficients
  betas <- process_coefficients(coefs, column_names, 
                                survival_rate_cutoff = survival_rate_cutoff)
  plot_betas(betas)
  ggplot2::ggsave(file.path(out_directory, "betas.png"))
  
  # Split data
  split_data <- sampler(X, y, train_size = train_size)
  X_train <- split_data[["X_train"]]
  X_test <- split_data[["X_test"]]
  y_train <- split_data[["y_train"]]
  y_test <- split_data[["y_test"]]
  
  # Bootstrap predictions
  predictions <- bootstrap_predictions(glmnet_fit_model_binomial, glmnet_predict_model, 
                                       preprocessor, 
                                       X_train, y_train, X_test, 
                                       categorical_variables = categorical_variables, 
                                       n_samples = n_samples, 
                                       progress_bar = progress_bar, 
                                       n_core = n_core, ...)
  y_train_predictions <- predictions[["y_train_predictions"]]
  y_test_predictions <- predictions[["y_test_predictions"]]
  
  # Generate scores for training and test sets
  y_train_predictions_mean <- apply(y_train_predictions, 1, mean)
  y_test_predictions_mean <- apply(y_test_predictions, 1, mean)
  
  # Compute ROC curve and ROC area for training
  plot_roc_curve(y_train, y_train_predictions_mean)
  ggplot2::ggsave(file.path(out_directory, "train_roc_curve.png"))
  
  # Compute ROC curve and ROC area for test
  plot_roc_curve(y_test, y_test_predictions_mean)
  ggplot2::ggsave(file.path(out_directory, "test_roc_curve.png"))
  
  # Bootstrap training and test AUCs
  aucs <- bootstrap_aucs(glmnet_fit_model_binomial, glmnet_predict_model, 
                         sampler, preprocessor, X, y, 
                         categorical_variables = categorical_variables, 
                         n_divisions = n_divisions, n_iterations = n_iterations, 
                         progress_bar = progress_bar, n_core = n_core, ...)
  train_aucs <- aucs[["mean_train_metrics"]]
  test_aucs <- aucs[["mean_test_metrics"]]
  
  # Plot histogram of training AUCs
  plot_auc_histogram(train_aucs)
  ggplot2::ggsave(file.path(out_directory, "train_auc_distribution.png"))
  
  # Plot histogram of test AUCs
  plot_auc_histogram(test_aucs)
  ggplot2::ggsave(file.path(out_directory, "test_auc_distribution.png"))
}
