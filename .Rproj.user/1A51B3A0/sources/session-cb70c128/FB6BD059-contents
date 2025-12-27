#' Fit First-Order Response Surface Model
#'
#' Fits a first-order polynomial model (linear terms only) to response surface data
#' using ordinary least squares (OLS) regression.
#'
#' @param data A data frame or tibble containing the response and factor variables.
#' @param response Character string with the name of the response variable.
#' @param factors Character vector with names of factor variables (must be in coded scale).
#'
#' @return An object of class "rsm_model" containing:
#'   - `model`: The fitted lm object
#'   - `coefficients`: Tibble with coefficient estimates, standard errors, t-values, and p-values
#'   - `anova_table`: ANOVA table
#'   - `r_squared`: R-squared value
#'   - `adj_r_squared`: Adjusted R-squared
#'   - `residual_std_error`: Residual standard error
#'   - `model_type`: "first_order"
#'   - `factors`: Names of factors used
#'   - `response`: Name of response variable
#'
#' @examples
#' data <- tibble::tibble(
#'   Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
#'   P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
#'   S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
#' )
#'
#' model <- fit_first_order(data, response = "Y", factors = c("P_coded", "S_coded"))
#' summary(model)
#'
#' @export
fit_first_order <- function(data, response, factors) {
  data <- tibble::as_tibble(data)

  # Build formula
  formula_str <- paste(response, "~", paste(factors, collapse = " + "))
  formula_obj <- as.formula(formula_str)

  # Fit model
  lm_model <- stats::lm(formula_obj, data = data)

  # Extract statistics
  summary_lm <- summary(lm_model)
  anova_table <- stats::anova(lm_model)

  # Create coefficients tibble
  coef_matrix <- summary_lm$coefficients
  coefficients <- tibble::as_tibble(coef_matrix, rownames = "term") %>%
    dplyr::rename(
      estimate = "Estimate",
      std_error = "Std. Error",
      t_value = "t value",
      p_value = "Pr(>|t|)"
    )

  # Create result object
  result <- list(
    model = lm_model,
    coefficients = coefficients,
    anova_table = anova_table,
    r_squared = summary_lm$r.squared,
    adj_r_squared = summary_lm$adj.r.squared,
    residual_std_error = summary_lm$sigma,
    model_type = "first_order",
    factors = factors,
    response = response,
    data = data
  )

  class(result) <- c("rsm_model", "list")
  return(result)
}

#' Fit First-Order Model with Interaction
#'
#' Fits a first-order model with all two-way interaction terms.
#'
#' @param data A data frame or tibble containing the response and factor variables.
#' @param response Character string with the name of the response variable.
#' @param factors Character vector with names of factor variables (must be in coded scale).
#'
#' @return An object of class "rsm_model" containing model results.
#'
#' @examples
#' data <- tibble::tibble(
#'   Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
#'   P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
#'   S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
#' )
#'
#' model <- fit_first_order_interaction(data, response = "Y", factors = c("P_coded", "S_coded"))
#'
#' @export
fit_first_order_interaction <- function(data, response, factors) {
  data <- tibble::as_tibble(data)

  # Build formula with interactions
  formula_str <- paste(response, "~", paste(factors, collapse = " + "),
    "+ ",
    paste(
      combn(factors, 2, FUN = function(x) paste(x, collapse = ":")),
      collapse = " + "
    )
  )
  formula_obj <- as.formula(formula_str)

  # Fit model
  lm_model <- stats::lm(formula_obj, data = data)

  # Extract statistics
  summary_lm <- summary(lm_model)
  anova_table <- stats::anova(lm_model)

  # Create coefficients tibble
  coef_matrix <- summary_lm$coefficients
  coefficients <- tibble::as_tibble(coef_matrix, rownames = "term") %>%
    dplyr::rename(
      estimate = "Estimate",
      std_error = "Std. Error",
      t_value = "t value",
      p_value = "Pr(>|t|)"
    )

  # Create result object
  result <- list(
    model = lm_model,
    coefficients = coefficients,
    anova_table = anova_table,
    r_squared = summary_lm$r.squared,
    adj_r_squared = summary_lm$adj.r.squared,
    residual_std_error = summary_lm$sigma,
    model_type = "first_order_interaction",
    factors = factors,
    response = response,
    data = data
  )

  class(result) <- c("rsm_model", "list")
  return(result)
}

#' Fit Second-Order (Quadratic) Response Surface Model
#'
#' Fits a complete second-order polynomial model including linear, quadratic,
#' and interaction terms.
#'
#' @param data A data frame or tibble containing the response and factor variables.
#' @param response Character string with the name of the response variable.
#' @param factors Character vector with names of factor variables (must be in coded scale).
#'
#' @return An object of class "rsm_model" containing model results.
#'
#' @details
#' The model fitted is:
#'
#' \deqn{Y = \beta_0 + \sum \beta_i X_i + \sum \beta_{ii} X_i^2 + \sum_{i<j} \beta_{ij} X_i X_j + \epsilon}
#'
#' @examples
#' data <- tibble::tibble(
#'   Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
#'   P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
#'   S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
#' )
#'
#' model <- fit_second_order(data, response = "Y", factors = c("P_coded", "S_coded"))
#'
#' @export
fit_second_order <- function(data, response, factors) {
  data <- tibble::as_tibble(data)

  # Build formula with quadratic and interaction terms
  linear_terms <- paste(factors, collapse = " + ")
  quadratic_terms <- paste(paste0("I(", factors, "^2)"), collapse = " + ")

  # Interaction terms
  interaction_pairs <- combn(factors, 2, FUN = function(x) paste(x, collapse = ":"))
  interaction_terms <- paste(interaction_pairs, collapse = " + ")

  formula_str <- paste(
    response, "~",
    linear_terms, "+",
    quadratic_terms, "+",
    interaction_terms
  )
  formula_obj <- as.formula(formula_str)

  # Fit model
  lm_model <- stats::lm(formula_obj, data = data)

  # Extract statistics
  summary_lm <- summary(lm_model)
  anova_table <- stats::anova(lm_model)

  # Create coefficients tibble
  coef_matrix <- summary_lm$coefficients
  coefficients <- tibble::as_tibble(coef_matrix, rownames = "term") %>%
    dplyr::rename(
      estimate = "Estimate",
      std_error = "Std. Error",
      t_value = "t value",
      p_value = "Pr(>|t|)"
    )

  # Create result object
  result <- list(
    model = lm_model,
    coefficients = coefficients,
    anova_table = anova_table,
    r_squared = summary_lm$r.squared,
    adj_r_squared = summary_lm$adj.r.squared,
    residual_std_error = summary_lm$sigma,
    model_type = "second_order",
    factors = factors,
    response = response,
    data = data
  )

  class(result) <- c("rsm_model", "list")
  return(result)
}

#' Generic Fit Function for Response Surface Models
#'
#' Automatically selects and fits the appropriate response surface model
#' based on the specified order.
#'
#' @param data A data frame or tibble containing the response and factor variables.
#' @param response Character string with the name of the response variable.
#' @param factors Character vector with names of factor variables.
#' @param order Integer (1 or 2) specifying the model order. Default is 2.
#' @param include_interaction Logical. If TRUE (default for order=1), includes interaction terms.
#'
#' @return An object of class "rsm_model".
#'
#' @export
fit_response_surface <- function(data, response, factors, order = 2, include_interaction = FALSE) {
  if (order == 1) {
    if (include_interaction) {
      return(fit_first_order_interaction(data, response, factors))
    } else {
      return(fit_first_order(data, response, factors))
    }
  } else if (order == 2) {
    return(fit_second_order(data, response, factors))
  } else {
    stop("Order must be 1 or 2.")
  }
}

#' Summary Method for RSM Models
#'
#' @param object An object of class "rsm_model".
#' @param ... Additional arguments (unused).
#'
#' @export
summary.rsm_model <- function(object, ...) {
  cat("\n=== Response Surface Model Summary ===\n")
  cat("Model Type:", object$model_type, "\n")
  cat("Response:", object$response, "\n")
  cat("Factors:", paste(object$factors, collapse = ", "), "\n")
  cat("\nR-squared:", round(object$r_squared, 4), "\n")
  cat("Adjusted R-squared:", round(object$adj_r_squared, 4), "\n")
  cat("Residual Std. Error:", round(object$residual_std_error, 4), "\n")
  cat("\nCoefficients:\n")
  print(object$coefficients)
  cat("\n")
}

#' Print Method for RSM Models
#'
#' @param x An object of class "rsm_model".
#' @param ... Additional arguments (unused).
#'
#' @export
print.rsm_model <- function(x, ...) {
  summary(x)
}
