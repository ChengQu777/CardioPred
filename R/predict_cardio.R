#' Predict Cardiovascular Disease
#'
#' @description
#' Takes a data frame containing patient features and a selected model type as input,
#' and returns a binary prediction outcome (0 or 1).
#'
#' @param new_data A data.frame. Must contain the feature columns used during training
#' (e.g., age, gender, height, weight, ap_hi, ap_lo, cholesterol, gluc, smoke, alco, active).
#' @param model_type A character string specifying the model to use. Options:
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
  model_type <- match.arg(model_type) # Ensures the input matches one of the options

  if (!is.data.frame(new_data)) {
    stop("Input 'new_data' must be a data.frame")
  }

  # 2. Ensure necessary columns exist
  # We add a dummy 'cardio' column so that model.matrix() can run the formula correctly.
  # This value does not affect the feature generation.
  if (!"cardio" %in% colnames(new_data)) {
    new_data$cardio <- 0
  }

  # 3. Branch logic based on model type

  if (model_type == "xgboost") {
    # === XGBoost Logic (Requires Matrix Alignment) ===

    # Generate the model matrix using the same formula as training
    # na.action = na.pass allows missing values (handled by XGBoost)
    X_test_matrix <- stats::model.matrix(cardio ~ . - 1, data = new_data)

    # Align column names:
    # Ensure the columns strictly match the training data (saved in train_col_names).
    # If a column is missing (e.g., a specific factor level), fill it with 0.
    required_cols <- train_col_names

    # Create a container matrix with zeros
    final_matrix <- matrix(0, nrow = nrow(X_test_matrix), ncol = length(required_cols))
    colnames(final_matrix) <- required_cols

    # Fill in the available data
    common_cols <- intersect(colnames(X_test_matrix), required_cols)
    final_matrix[, common_cols] <- X_test_matrix[, common_cols]

    # Convert to xgb.DMatrix format
    dtest <- xgboost::xgb.DMatrix(data = final_matrix)

    # Predict probabilities
    prob_preds <- predict(xgb_fit, dtest)

    # Convert probabilities to class labels (Threshold: 0.5)
    class_preds <- ifelse(prob_preds > 0.5, 1, 0)

  } else if (model_type == "glm") {
    # === GLM Logic ===

    # Predict using the Logistic Regression model
    # type="response" returns probabilities
    prob_preds <- predict(glm_fit, newdata = new_data, type = "response")
    class_preds <- ifelse(prob_preds > 0.5, 1, 0)

  } else if (model_type == "rf") {
    # === Random Forest Logic ===

    # Random Forest requires factor levels in new_data to match training data exactly.
    # Assuming the input data is correctly formatted:
    preds <- predict(rf_fit, newdata = new_data)

    # Handle output format (RF can output class or probability depending on config)
    if (is.factor(preds)) {
      # If output is factor class labels
      class_preds <- as.numeric(as.character(preds))
    } else {
      # If output is probability or numeric
      class_preds <- ifelse(preds > 0.5, 1, 0)
    }
  }

  return(as.integer(class_preds))
}

