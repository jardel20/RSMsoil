#' Extract Model Matrix
#'
#' Extracts the design matrix (X matrix) from an RSM model.
#'
#' @param rsm_model An object of class "rsm_model".
#'
#' @return A matrix with the design matrix used in the model.
#'
#' @export
get_design_matrix <- function(rsm_model) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  return(stats::model.matrix(rsm_model$model))
}

#' Extract Residuals
#'
#' Extracts residuals from a fitted RSM model.
#'
#' @param rsm_model An object of class "rsm_model".
#'
#' @return A numeric vector with residuals.
#'
#' @export
get_residuals <- function(rsm_model) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  return(stats::residuals(rsm_model$model))
}

#' Extract Fitted Values
#'
#' Extracts fitted values from a fitted RSM model.
#'
#' @param rsm_model An object of class "rsm_model".
#'
#' @return A numeric vector with fitted values.
#'
#' @export
get_fitted_values <- function(rsm_model) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  return(stats::fitted(rsm_model$model))
}

#' Model Diagnostics
#'
#' Produces diagnostic plots for model validation.
#'
#' @param rsm_model An object of class "rsm_model".
#'
#' @return A list of ggplot2 objects with diagnostic plots:
#'   - Residuals vs Fitted
#'   - Q-Q plot
#'   - Scale-Location plot
#'   - Residuals vs Leverage
#'
#' @export
plot_diagnostics <- function(rsm_model) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  residuals <- get_residuals(rsm_model)
  fitted <- get_fitted_values(rsm_model)
  standardized_residuals <- residuals / sd(residuals)

  # Residuals vs Fitted
  p1 <- ggplot2::ggplot(
    tibble::tibble(fitted = fitted, residuals = residuals),
    ggplot2::aes(x = fitted, y = residuals)
  ) +
    ggplot2::geom_point() +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "red") +
    ggplot2::labs(title = "Residuals vs Fitted", x = "Fitted values", y = "Residuals") +
    ggplot2::theme_minimal()

  # Q-Q plot
  theoretical_quantiles <- stats::qnorm(ppoints(length(standardized_residuals)))
  p2 <- ggplot2::ggplot(
    tibble::tibble(
      theoretical = theoretical_quantiles,
      sample = sort(standardized_residuals)
    ),
    ggplot2::aes(x = theoretical, y = sample)
  ) +
    ggplot2::geom_point() +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "red") +
    ggplot2::labs(title = "Normal Q-Q Plot", x = "Theoretical Quantiles", y = "Sample Quantiles") +
    ggplot2::theme_minimal()

  # Scale-Location
  sqrt_abs_residuals <- sqrt(abs(standardized_residuals))
  p3 <- ggplot2::ggplot(
    tibble::tibble(fitted = fitted, sqrt_abs_residuals = sqrt_abs_residuals),
    ggplot2::aes(x = fitted, y = sqrt_abs_residuals)
  ) +
    ggplot2::geom_point() +
    ggplot2::labs(
      title = "Scale-Location",
      x = "Fitted values",
      y = expression(sqrt("|Standardized residuals|"))
    ) +
    ggplot2::theme_minimal()

  # Residuals vs Leverage
  leverage <- stats::hatvalues(rsm_model$model)
  p4 <- ggplot2::ggplot(
    tibble::tibble(leverage = leverage, standardized_residuals = standardized_residuals),
    ggplot2::aes(x = leverage, y = standardized_residuals)
  ) +
    ggplot2::geom_point() +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "red") +
    ggplot2::labs(
      title = "Residuals vs Leverage",
      x = "Leverage",
      y = "Standardized residuals"
    ) +
    ggplot2::theme_minimal()

  return(list(
    residuals_vs_fitted = p1,
    qq_plot = p2,
    scale_location = p3,
    residuals_vs_leverage = p4
  ))
}

#' Compare Models
#'
#' Compares two RSM models using ANOVA F-test.
#'
#' @param model1 An object of class "rsm_model".
#' @param model2 An object of class "rsm_model".
#'
#' @return A tibble with comparison results including F-statistic and p-value.
#'
#' @export
compare_models <- function(model1, model2) {
  if (!inherits(model1, "rsm_model") || !inherits(model2, "rsm_model")) {
    stop("Both inputs must be objects of class 'rsm_model'")
  }

  # Use anova to compare nested models
  comparison <- stats::anova(model1$model, model2$model)

  result <- tibble::as_tibble(comparison, rownames = "model") %>%
    dplyr::mutate(
      model = c(model1$model_type, model2$model_type),
      .before = 1
    )

  return(result)
}

#' Generate Experimental Design
#'
#' Creates a central composite design (CCD) or similar experimental matrix.
#'
#' @param n_factors Integer number of factors.
#' @param design Character: "ccd" (central composite), "factorial" (2^k), or "custom".
#' @param alpha Numeric value for star points in CCD. Default is 1.68 (rotatable).
#' @param n_center Integer number of center points. Default is 3.
#'
#' @return A tibble with the experimental design in coded scale.
#'
#' @export
generate_design <- function(n_factors, design = "ccd", alpha = 1.68, n_center = 3) {
  factor_names <- paste0("X", 1:n_factors)

  if (design == "ccd") {
    # Factorial points (2^k)
    factorial_points <- expand.grid(
      purrr::map(1:n_factors, ~ c(-1, 1))
    )
    names(factorial_points) <- factor_names

    # Star points (axial)
    star_points <- matrix(0, nrow = 2 * n_factors, ncol = n_factors)
    for (i in 1:n_factors) {
      star_points[2 * i - 1, i] <- alpha
      star_points[2 * i, i] <- -alpha
    }
    star_points <- tibble::as_tibble(star_points)
    names(star_points) <- factor_names

    # Center points
    center_points <- tibble::as_tibble(
      matrix(0, nrow = n_center, ncol = n_factors)
    )
    names(center_points) <- factor_names

    design_matrix <- dplyr::bind_rows(factorial_points, star_points, center_points)
  } else if (design == "factorial") {
    design_matrix <- expand.grid(
      purrr::map(1:n_factors, ~ c(-1, 1))
    )
    names(design_matrix) <- factor_names
    design_matrix <- tibble::as_tibble(design_matrix)
  } else {
    stop("Design must be 'ccd' or 'factorial'")
  }

  return(design_matrix)
}
