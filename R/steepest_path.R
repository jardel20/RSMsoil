#' Calculate Path of Steepest Ascent/Descent
#'
#' Computes the path of steepest ascent (for maximization) or descent (for minimization)
#' from a reference point (usually the center of the experimental region).
#'
#' @param rsm_model An object of class "rsm_model" fitted with a first or second-order model.
#' @param start_point Numeric vector with starting point coordinates in coded scale.
#'   If NULL, uses the origin (0, 0, ...).
#' @param direction Character: "ascent" (default) for maximization or "descent" for minimization.
#' @param n_steps Integer number of steps along the path. Default is 10.
#' @param step_size Numeric step size in coded scale. Default is 0.1.
#'
#' @return A list of class "steepest_path" containing:
#'   - `path_data`: Tibble with coordinates and predicted responses along the path
#'   - `gradient`: Direction vector (normalized gradient)
#'   - `start_point`: Starting point coordinates
#'   - `direction`: Direction of search
#'   - `factors`: Names of factors
#'
#' @details
#' The steepest ascent path is determined by the gradient of the response surface:
#'
#' \deqn{\nabla Y = \frac{\partial Y}{\partial \mathbf{X}} = \mathbf{b} + 2\mathbf{B}\mathbf{X}}
#'
#' At the starting point, the gradient direction is:
#'
#' \deqn{\mathbf{d} = \frac{\nabla Y}{||\nabla Y||}}{(normalized)}
#'
#' The path is then:
#'
#' \deqn{\mathbf{X}(t) = \mathbf{X}_0 + t \cdot \mathbf{d}}
#'
#' @examples
#' data <- tibble::tibble(
#'   Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
#'   P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
#'   S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
#' )
#'
#' model <- fit_first_order(data, response = "Y", factors = c("P_coded", "S_coded"))
#' path <- steepest_path(model, n_steps = 5)
#'
#' @export
steepest_path <- function(rsm_model, start_point = NULL, direction = "ascent",
                          n_steps = 10, step_size = 0.1) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  factors <- rsm_model$factors
  n_factors <- length(factors)

  # Set default start point
  if (is.null(start_point)) {
    start_point <- rep(0, n_factors)
    names(start_point) <- factors
  }

  # Extract coefficients
  coef_names <- rsm_model$coefficients$term
  coef_values <- rsm_model$coefficients$estimate

  # Linear coefficients (gradient at any point)
  b_indices <- which(coef_names %in% factors)
  b_vector <- coef_values[b_indices]
  names(b_vector) <- factors

  # If second-order model, extract B matrix
  B_matrix <- NULL
  if (rsm_model$model_type == "second_order") {
    b_diag_indices <- which(grepl("I\\(.*\\^2\\)", coef_names))
    b_diag <- coef_values[b_diag_indices]

    interaction_indices <- which(grepl(":", coef_names))
    b_interactions <- coef_values[interaction_indices]

    B_matrix <- matrix(0, nrow = n_factors, ncol = n_factors)
    diag(B_matrix) <- b_diag / 2

    if (length(b_interactions) > 0) {
      interaction_pairs <- combn(1:n_factors, 2)
      for (i in 1:ncol(interaction_pairs)) {
        row_idx <- interaction_pairs[1, i]
        col_idx <- interaction_pairs[2, i]
        B_matrix[row_idx, col_idx] <- b_interactions[i] / 2
        B_matrix[col_idx, row_idx] <- b_interactions[i] / 2
      }
    }
  }

  # Calculate gradient at start point
  gradient <- b_vector
  if (!is.null(B_matrix)) {
    gradient <- gradient + 2 * B_matrix %*% start_point
  }

  # Normalize gradient
  gradient_norm <- sqrt(sum(gradient^2))
  direction_vector <- gradient / gradient_norm

  # Reverse direction if descent
  if (direction == "descent") {
    direction_vector <- -direction_vector
  }

  # Generate path
  path_coords <- matrix(0, nrow = n_steps, ncol = n_factors)
  predicted_responses <- numeric(n_steps)

  intercept <- coef_values[1]

  for (i in 1:n_steps) {
    t <- (i - 1) * step_size
    x_current <- start_point + t * direction_vector

    # Predict response
    y_pred <- intercept + sum(b_vector * x_current)
    if (!is.null(B_matrix)) {
      y_pred <- y_pred + as.numeric(t(x_current) %*% B_matrix %*% x_current)
    }

    path_coords[i, ] <- x_current
    predicted_responses[i] <- y_pred
  }

  # Create tibble with path data
  path_data <- tibble::as_tibble(path_coords)
  names(path_data) <- factors
  path_data <- path_data %>%
    dplyr::mutate(
      step = 0:(n_steps - 1),
      distance = step * step_size,
      predicted_response = predicted_responses,
      .before = 1
    )

  # Create result object
  result <- list(
    path_data = path_data,
    gradient = gradient,
    direction_vector = direction_vector,
    start_point = start_point,
    direction = direction,
    factors = factors,
    step_size = step_size
  )

  class(result) <- c("steepest_path", "list")
  return(result)
}

#' Print Method for Steepest Path
#'
#' @param x An object of class "steepest_path".
#' @param ... Additional arguments (unused).
#'
#' @export
print.steepest_path <- function(x, ...) {
  cat("\n=== Path of Steepest", toupper(x$direction), "===\n")
  cat("Starting Point:\n")
  print(tibble::as_tibble(as.list(x$start_point)))

  cat("\nDirection Vector (normalized gradient):\n")
  print(tibble::as_tibble(as.list(x$direction_vector)))

  cat("\nPath Data:\n")
  print(x$path_data)
  cat("\n")
}

#' Summary Method for Steepest Path
#'
#' @param object An object of class "steepest_path".
#' @param ... Additional arguments (unused).
#'
#' @export
summary.steepest_path <- function(object, ...) {
  print(object)
}
