#' Canonical Analysis of Response Surface
#'
#' Performs canonical analysis to characterize the stationary point and
#' determine the nature of the response surface (maximum, minimum, or saddle point).
#'
#' @param rsm_model An object of class "rsm_model" fitted with a second-order model.
#'
#' @return A list of class "canonical_analysis" containing:
#'   - `stationary_point`: Coordinates of the stationary point in coded scale
#'   - `stationary_point_natural`: Coordinates in natural scale (if encoding levels available)
#'   - `predicted_response`: Predicted response at stationary point
#'   - `hessian_matrix`: Hessian matrix (2 × B matrix)
#'   - `eigenvalues`: Eigenvalues of the Hessian matrix
#'   - `eigenvectors`: Eigenvectors (canonical axes)
#'   - `surface_type`: Classification (maximum, minimum, saddle point)
#'   - `canonical_coefficients`: Coefficients in canonical form
#'   - `factors`: Names of factors
#'
#' @details
#' The stationary point is found by solving:
#'
#' \deqn{\mathbf{b} + 2\mathbf{B}\mathbf{x}_s = 0}
#'
#' Where \eqn{\mathbf{b}} is the linear coefficient vector and \eqn{\mathbf{B}} is the
#' quadratic coefficient matrix.
#'
#' The Hessian matrix is \eqn{\mathbf{H} = 2\mathbf{B}}.
#'
#' Surface classification:
#' - All eigenvalues negative: maximum
#' - All eigenvalues positive: minimum
#' - Mixed signs: saddle point
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
#'
#' @export
canonical_analysis <- function(rsm_model) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  if (rsm_model$model_type != "second_order") {
    stop("Canonical analysis requires a second-order model")
  }

  factors <- rsm_model$factors
  n_factors <- length(factors)

  # Extract coefficients
  coef_names <- rsm_model$coefficients$term
  coef_values <- rsm_model$coefficients$estimate

  # Linear coefficients (b vector)
  b_indices <- which(coef_names %in% factors)
  b_vector <- coef_values[b_indices]
  names(b_vector) <- factors

  # Quadratic coefficients (B matrix - diagonal)
  b_diag_indices <- which(grepl("I\\(.*\\^2\\)", coef_names))
  b_diag <- coef_values[b_diag_indices]

  # Interaction coefficients (B matrix - off-diagonal)
  interaction_indices <- which(grepl(":", coef_names))
  b_interactions <- coef_values[interaction_indices]

  # Build B matrix (quadratic coefficient matrix)
  B_matrix <- matrix(0, nrow = n_factors, ncol = n_factors)
  diag(B_matrix) <- b_diag / 2 # Divide by 2 because model is Y = ... + b_ii*X_i^2

  # Fill interaction terms (symmetric matrix)
  if (length(b_interactions) > 0) {
    interaction_pairs <- combn(1:n_factors, 2)
    for (i in 1:ncol(interaction_pairs)) {
      row_idx <- interaction_pairs[1, i]
      col_idx <- interaction_pairs[2, i]
      B_matrix[row_idx, col_idx] <- b_interactions[i] / 2
      B_matrix[col_idx, row_idx] <- b_interactions[i] / 2
    }
  }

  # Calculate stationary point: x_s = -0.5 * B^-1 * b
  B_inv <- solve(B_matrix)
  x_stationary <- -0.5 * B_inv %*% b_vector

  # Hessian matrix
  H_matrix <- 2 * B_matrix

  # Eigenvalue decomposition
  eigen_decomp <- eigen(H_matrix)
  eigenvalues <- eigen_decomp$values
  eigenvectors <- eigen_decomp$vectors

  # Determine surface type
  if (all(eigenvalues < 0)) {
    surface_type <- "Maximum"
  } else if (all(eigenvalues > 0)) {
    surface_type <- "Minimum"
  } else {
    surface_type <- "Saddle Point"
  }

  # Predict response at stationary point
  intercept <- coef_values[1]
  predicted_response <- intercept +
    as.numeric(b_vector %*% x_stationary) +
    as.numeric(t(x_stationary) %*% B_matrix %*% x_stationary)

  # Try to decode stationary point to natural scale
  stationary_natural <- NULL
  encoding_levels <- attr(rsm_model$data, "encoding_levels")
  if (!is.null(encoding_levels)) {
    stationary_natural <- purrr::map_dbl(factors, function(factor) {
      lvl <- encoding_levels[[factor]]
      center <- lvl["center"]
      range <- (lvl["high"] - lvl["low"]) / 2
      center + x_stationary[factor] * range
    })
    names(stationary_natural) <- factors
  }

  # Create result object
  result <- list(
    stationary_point = as.numeric(x_stationary),
    stationary_point_natural = stationary_natural,
    predicted_response = predicted_response,
    hessian_matrix = H_matrix,
    eigenvalues = eigenvalues,
    eigenvectors = eigenvectors,
    surface_type = surface_type,
    b_vector = b_vector,
    B_matrix = B_matrix,
    factors = factors,
    intercept = intercept
  )

  names(result$stationary_point) <- factors

  class(result) <- c("canonical_analysis", "list")
  return(result)
}

#' Print Method for Canonical Analysis
#'
#' @param x An object of class "canonical_analysis".
#' @param ... Additional arguments (unused).
#'
#' @export
print.canonical_analysis <- function(x, ...) {
  cat("\n=== Canonical Analysis of Response Surface ===\n")
  cat("Surface Type:", x$surface_type, "\n\n")

  cat("Stationary Point (Coded Scale):\n")
  print(tibble::as_tibble(as.list(x$stationary_point)))

  if (!is.null(x$stationary_point_natural)) {
    cat("\nStationary Point (Natural Scale):\n")
    print(tibble::as_tibble(as.list(x$stationary_point_natural)))
  }

  cat("\nPredicted Response at Stationary Point:", round(x$predicted_response, 4), "\n")

  cat("\nEigenvalues:\n")
  print(tibble::as_tibble(
    data.frame(
      eigenvalue = x$eigenvalues,
      sign = ifelse(x$eigenvalues < 0, "Negative", "Positive")
    )
  ))

  cat("\nHessian Matrix:\n")
  print(x$hessian_matrix)

  cat("\n")
}

#' Summary Method for Canonical Analysis
#'
#' @param object An object of class "canonical_analysis".
#' @param ... Additional arguments (unused).
#'
#' @export
summary.canonical_analysis <- function(object, ...) {
  print(object)
}
