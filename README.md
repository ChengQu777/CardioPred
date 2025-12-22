# CardioPred: Cardiovascular Disease Prediction Tool

**CardioPred** is an R package designed to predict the presence of cardiovascular disease based on patient health metrics and demographic data. 

This package was developed to ensure reproducible research by encapsulating trained machine learning models into a portable software library. It allows researchers and clinicians to apply the same predictive logic used in the study to new datasets easily.

## Key Features

* **Multi-Model Support**: Includes three pre-trained state-of-the-art models:
    * **XGBoost** (Extreme Gradient Boosting)
    * **Random Forest**
    * **GLM** (Logistic Regression)
* **Robust Data Handling**: Automatically handles data type conversions (e.g., converting numeric inputs to factors based on training data prototypes).
* **Batch Prediction**: Supports processing single patient records or large datasets (batch mode) efficiently.
* **Reproducibility**: Eliminates environment inconsistencies by bundling the exact model objects (`xgb.Booster`, `randomForest`, `glm`) used in the analysis.

## Installation

You can install the development version of CardioPred from [GitHub](https://github.com/) with:

```r
# install.packages("remotes")
remotes::install_github("ChengQu777/CardioPred")
```

## 📊 Model Details

The package contains models trained on the Cardiovascular Disease dataset. Below is a brief summary of the models included:

| Model Type | Description | Key Hyperparameters |
| :--- | :--- | :--- |
| **XGBoost** | Gradient boosting on decision trees. Best for high performance. | `nrounds`, `eta`, `max_depth` (Optimized) |
| **Random Forest** | Ensemble of decision trees. Robust against overfitting. | `ntree=500`, `mtry` (Default) |
| **Logistic Regression** | Baseline linear classifier for interpretability. | Standard GLM |

*(Note: Actual model performance metrics such as Accuracy and AUC can be found in the associated study report.)*

## Usage Example

Here is how to use `CardioPred` to predict the health status of a single patient.

```{r example}
library(CardioPred)

# Simulate an example
test_patient <- data.frame(
  age = 55,
  gender = 1, 
  height = 160,
  weight = 65,
  ap_hi = 125,
  ap_lo = 80,
  cholesterol = 1,
  gluc = 1,
  smoke = 0,
  alco = 0,
  active = 1
)

# 1. Use XGBoost to predict
pred_xgb <- predict_cardio(test_patient, model_type = "xgboost")
print(paste("XGBoost Prediction:", pred_xgb))

# 2. Use GLM to predict
pred_glm <- predict_cardio(test_patient, model_type = "glm")
print(paste("GLM Prediction:", pred_glm))

# 3. Use RandomForest to predict
pred_rf <- predict_cardio(test_patient, model_type = "rf")
print(paste("RF Prediction:", pred_rf))
```

### Batch Prediction Example

You can also input a data frame with multiple rows to get predictions for multiple patients at once.

```{r batch-example}
# Create a dataset with 3 different patients
# Patient 1: Young, healthy stats (Low Risk)
# Patient 2: Older, high BP, smoker (High Risk)
# Patient 3: Middle-aged, borderline stats
batch_data <- data.frame(
  age = c(30, 65, 50),
  gender = c(1, 2, 1),
  height = c(170, 175, 160),
  weight = c(60, 95, 75),
  ap_hi = c(110, 160, 135),
  ap_lo = c(70, 100, 85),
  cholesterol = c(1, 3, 2),
  gluc = c(1, 3, 1),
  smoke = c(0, 1, 0),
  alco = c(0, 1, 0),
  active = c(1, 0, 1)
)

# --- Scenario 1: XGBoost Predictions ---
batch_data$xgb_result <- predict_cardio(batch_data, model_type = "xgboost")

# --- Scenario 2: Random Forest Predictions ---
batch_data$rf_result <- predict_cardio(batch_data, model_type = "rf")

# --- Scenario 3: Logistic Regression Predictions ---
batch_data$glm_result <- predict_cardio(batch_data, model_type = "glm")

# Display the results side-by-side
print(batch_data[, c("age", "ap_hi", "smoke", "xgb_result", 
                     "rf_result", "glm_result")])
```


## Dependencies

This package relies on the following R libraries:
* `xgboost`
* `randomForest`
* `stats`
