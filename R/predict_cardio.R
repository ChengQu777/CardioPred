#' Predict Cardiovascular Disease
#'
#' @description
#' Takes a data frame containing patient features and a selected model type as input,
#' and returns a binary prediction outcome (0 or 1).
#'
#' @param new_data A data.frame. Must contain the feature columns used during training
#' @param model_type A character string specifying the model to use. Options:
#' @import randomForest
#' @importFrom stats predict
#' \itemize{
#'   \item "xgboost" (default) - Extreme Gradient Boosting
#'   \item "glm" - Logistic Regression
#'   \item "rf" - Random Forest
#' }
#'
#' @return An integer vector: 0 indicates no disease, 1 indicates disease.
#' @export
#'
#' @examples
#' # Example Data
#' patient <- data.frame(
#'   age = 50, gender = factor(1), height = 165, weight = 70,
#'   ap_hi = 120, ap_lo = 80, cholesterol = factor(1), gluc = factor(1),
#'   smoke = 0, alco = 0, active = 1
#' )
#'
#' # Predict using XGBoost
#' predict_cardio(patient, model_type = "xgboost")
#'
#' # Predict using GLM
#' predict_cardio(patient, model_type = "glm")
predict_cardio <- function(new_data, model_type = c("xgboost", "glm", "rf")) {

  # 1. Validate arguments
  model_type <- match.arg(model_type)

  if (!is.data.frame(new_data)) {
    stop("Input 'new_data' must be a data.frame")
  }

  # === CRITICAL FIX: Enforce Data Types and Factor Levels ===
  # We loop through the training prototype columns to ensure new_data matches exactly.
  # This fixes the "contrasts" error and "type mismatch" error.

  # Ensure 'cardio' column exists for model.matrix formula (dummy value)
  if (!"cardio" %in% colnames(new_data)) {
    new_data$cardio <- 0
  }

  # Align types with training data
  for (col_name in colnames(train_prototype)) {
    # Only process if this column exists in input (skip 'cardio' if user didn't provide it)
    if (col_name %in% colnames(new_data)) {

      target_class <- class(train_prototype[[col_name]])[1] # get primary class

      # If training data was Factor, force input to be Factor with SAME levels
      if ("factor" %in% target_class) {
        new_data[[col_name]] <- factor(new_data[[col_name]],
                                       levels = levels(train_prototype[[col_name]]))
      }
      # If training data was Numeric/Integer, force input to be numeric
      else if ("numeric" %in% target_class || "integer" %in% target_class) {
        new_data[[col_name]] <- as.numeric(new_data[[col_name]])
      }
    }
  }

  # ==========================================================

  # 3. Branch logic based on model type

  if (model_type == "xgboost") {

    # Generate model matrix
    # Now that factors are fixed with correct levels, model.matrix works correctly
    X_test_matrix <- stats::model.matrix(cardio ~ . - 1, data = new_data)

    # Align column names for XGBoost
    required_cols <- train_col_xgb_names
    final_matrix <- matrix(0, nrow = nrow(X_test_matrix), ncol = length(required_cols))
    colnames(final_matrix) <- required_cols

    common_cols <- intersect(colnames(X_test_matrix), required_cols)
    final_matrix[, common_cols] <- X_test_matrix[, common_cols]

    dtest <- xgboost::xgb.DMatrix(final_matrix, label=new_data$cardio)

    prob_preds <- predict(xgb_fit, dtest)
    class_preds <- ifelse(prob_preds > 0.5, 1, 0)

  } else if (model_type == "glm") {

    # Now valid because we fixed factor types above
    prob_preds <- predict(glm_fit, newdata = new_data, type = "response")
    class_preds <- ifelse(prob_preds > 0.5, 1, 0)

  } else if (model_type == "rf") {

    # Now valid because factor levels match perfectly
    preds <- predict(rf_fit, newdata = new_data)

    if (is.factor(preds)) {
      class_preds <- as.numeric(as.character(preds))
    } else {
      class_preds <- ifelse(preds > 0.5, 1, 0)
    }
  }

  return(as.integer(class_preds))
}
