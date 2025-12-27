#' Predict Response Using RSM Model
#'
#' Generates predictions from a fitted response surface model at specified
#' factor combinations.
#'
#' @param rsm_model An object of class "rsm_model".
#' @param new_data A data frame or tibble with new factor values in coded scale.
#'   If NULL, predictions are made for the original data.
#' @param se_fit Logical. If TRUE, returns standard errors of predictions. Default is FALSE.
#'
#' @return A tibble with columns:
#'   - Factor columns (from new_data)
#'   - `predicted_response`: Predicted response values
#'   - `se_fit` (if se_fit=TRUE): Standard error of predictions
#'   - `ci_lower`, `ci_upper` (if se_fit=TRUE): 95% confidence intervals
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
#' new_points <- tibble::tibble(P_coded = c(0, 0.5), S_coded = c(0, 0.5))
#' predictions <- predict_rsm(model, new_data = new_points, se_fit = TRUE)
#'
#' @export
predict_rsm <- function(rsm_model, new_data = NULL, se_fit = FALSE) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  if (is.null(new_data)) {
    new_data <- rsm_model$data[, rsm_model$factors]
  } else {
    new_data <- tibble::as_tibble(new_data)
  }

  # Use stats::predict for lm object
  if (se_fit) {
    pred_obj <- stats::predict(rsm_model$model,
      newdata = new_data,
      se.fit = TRUE,
      interval = "confidence",
      level = 0.95
    )

    result <- new_data %>%
      dplyr::mutate(
        predicted_response = pred_obj$fit[, "fit"],
        se_fit = pred_obj$se.fit,
        ci_lower = pred_obj$fit[, "lwr"],
        ci_upper = pred_obj$fit[, "upr"]
      )
  } else {
    pred_values <- stats::predict(rsm_model$model, newdata = new_data)

    result <- new_data %>%
      dplyr::mutate(predicted_response = pred_values)
  }

  return(result)
}

#' Get Stationary Point and Recommended Doses
#'
#' Extracts the stationary point from canonical analysis and provides
#' recommendations for optimal factor levels.
#'
#' @param canonical_result An object of class "canonical_analysis".
#' @param include_natural Logical. If TRUE, includes natural scale coordinates. Default is TRUE.
#'
#' @return A tibble with:
#'   - Factor names
#'   - Stationary point coordinates (coded scale)
#'   - Stationary point coordinates (natural scale, if available)
#'   - Predicted response at stationary point
#'   - Surface type classification
#'
#' @examples
#' data <- tibble::tibble(
#'   Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
#'   P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
#'   S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
#' )
#'
#' model <- fit_second_order(data, response = "Y", factors = c("P_coded", "S_coded"))
#' canonical <- canonical_analysis(model)
#' recommendations <- get_stationary_point(canonical)
#'
#' @export
get_stationary_point <- function(canonical_result, include_natural = TRUE) {
  if (!inherits(canonical_result, "canonical_analysis")) {
    stop("Input must be an object of class 'canonical_analysis'")
  }

  result <- tibble::tibble(
    factor = canonical_result$factors,
    coded_value = canonical_result$stationary_point
  )

  if (include_natural && !is.null(canonical_result$stationary_point_natural)) {
    result <- result %>%
      dplyr::mutate(
        natural_value = canonical_result$stationary_point_natural
      )
  }

  result <- result %>%
    dplyr::mutate(
      predicted_response = canonical_result$predicted_response,
      surface_type = canonical_result$surface_type,
      .after = dplyr::everything()
    )

  return(result)
}

#' Find Optimal Factor Levels
#'
#' Searches for optimal factor levels that maximize or minimize the response
#' within specified bounds.
#'
#' @param rsm_model An object of class "rsm_model".
#' @param objective Character: "maximize" or "minimize". Default is "maximize".
#' @param bounds A list with named numeric vectors specifying lower and upper bounds
#'   for each factor in coded scale. If NULL, uses \eqn{[-1.68, 1.68]} for all factors.
#' @param n_grid Integer number of grid points per dimension. Default is 20.
#'
#' @return A list containing:
#'   - `optimal_point`: Tibble with optimal factor levels
#'   - `optimal_response`: Predicted response at optimal point
#'   - `grid_search_results`: Tibble with all evaluated points and responses
#'
#' @examples
#' data <- tibble::tibble(
#'   Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
#'   P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
#'   S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
#' )
#'
#' model <- fit_second_order(data, response = "Y", factors = c("P_coded", "S_coded"))
#' optimization <- get_optimal_factors(model, objective = "maximize", n_grid = 15)
#'
#' @export
get_optimal_factors <- function(rsm_model, objective = "maximize", bounds = NULL, n_grid = 20) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  factors <- rsm_model$factors
  n_factors <- length(factors)

  # Set default bounds
  if (is.null(bounds)) {
    bounds <- purrr::map(factors, ~ c(-1.68, 1.68))
    names(bounds) <- factors
  }

  # Create grid
  grid_lists <- purrr::map(factors, function(factor) {
    seq(bounds[[factor]][1], bounds[[factor]][2], length.out = n_grid)
  })
  names(grid_lists) <- factors

  grid_data <- expand.grid(grid_lists, KEEP.OUT.ATTRS = FALSE)
  grid_data <- tibble::as_tibble(grid_data)

  # Predict for all grid points
  predictions <- predict_rsm(rsm_model, new_data = grid_data)

  # Find optimal point
  if (objective == "maximize") {
    optimal_idx <- which.max(predictions$predicted_response)
  } else if (objective == "minimize") {
    optimal_idx <- which.min(predictions$predicted_response)
  } else {
    stop("Objective must be 'maximize' or 'minimize'")
  }

  optimal_point <- predictions[optimal_idx, ]

  result <- list(
    optimal_point = optimal_point,
    optimal_response = optimal_point$predicted_response,
    grid_search_results = predictions
  )

  class(result) <- c("optimization_result", "list")
  return(result)
}

#' Print Method for Optimization Results
#'
#' @param x An object of class "optimization_result".
#' @param ... Additional arguments (unused).
#'
#' @export
print.optimization_result <- function(x, ...) {
  cat("\n=== Optimization Results ===\n")
  cat("Optimal Factor Levels:\n")
  print(x$optimal_point)
  cat("\nOptimal Response:", round(x$optimal_response, 4), "\n\n")
}
