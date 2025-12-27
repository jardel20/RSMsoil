#' Plot Response Surface (Static)
#'
#' Creates a static 2D contour plot of the response surface for a pair of factors.
#' If more than two factors are present, automatically selects the first pair.
#'
#' @param rsm_model An object of class "rsm_model" fitted with a second-order model.
#' @param factor1 Character name of first factor. If NULL, uses first factor.
#' @param factor2 Character name of second factor. If NULL, uses second factor.
#' @param fixed_values Named list with values for factors not being plotted (in coded scale).
#'   If NULL, uses 0 for all fixed factors.
#' @param n_grid Integer number of grid points per dimension. Default is 50.
#' @param show_stationary Logical. If TRUE, marks the stationary point. Default is TRUE.
#' @param show_optimal Logical. If TRUE, marks the optimal point within bounds. Default is FALSE.
#'
#' @return A ggplot2 object showing contour lines and filled regions of the response surface.
#'
#' @examples
#' data <- tibble::tibble(
#'   Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
#'   P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
#'   S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
#' )
#'
#' model <- fit_second_order(data, response = "Y", factors = c("P_coded", "S_coded"))
#' plot_response_surface(model)
#'
#' @export
plot_response_surface <- function(rsm_model, factor1 = NULL, factor2 = NULL,
                                  fixed_values = NULL, n_grid = 50,
                                  show_stationary = TRUE, show_optimal = FALSE) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  if (rsm_model$model_type != "second_order") {
    stop("Response surface plot requires a second-order model")
  }

  factors <- rsm_model$factors

  # Select factors
  if (is.null(factor1)) factor1 <- factors[1]
  if (is.null(factor2)) factor2 <- factors[2]

  if (!(factor1 %in% factors) || !(factor2 %in% factors)) {
    stop("Selected factors must be in the model")
  }

  # Set fixed values
  if (is.null(fixed_values)) {
    fixed_values <- purrr::map(factors[!(factors %in% c(factor1, factor2))], ~0)
  }

  # Create grid
  grid_f1 <- seq(-1.68, 1.68, length.out = n_grid)
  grid_f2 <- seq(-1.68, 1.68, length.out = n_grid)

  grid_data <- expand.grid(
    grid_f1,
    grid_f2
  )
  names(grid_data) <- c(factor1, factor2)


  # Add fixed values
  for (factor in names(fixed_values)) {
    grid_data[[factor]] <- fixed_values[[factor]]
  }

  # Predict
  predictions <- predict_rsm(rsm_model, new_data = grid_data)

  # Prepare data for ggplot
  plot_data <- predictions %>%
    dplyr::select(dplyr::all_of(c(factor1, factor2, "predicted_response"))) %>%
    dplyr::rename(
      x = !!factor1,
      y = !!factor2,
      response = "predicted_response"
    )

  # Create plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = x, y = y, z = response)) +
    ggplot2::geom_contour(ggplot2::aes(colour = ggplot2::after_stat(level)),
      size = 0.5
    ) +
    ggplot2::geom_contour_filled(alpha = 0.6) +
    ggplot2::scale_fill_viridis_d(option = "turbo", name = "Response") +
    ggplot2::labs(
      title = "Response Surface",
      x = factor1,
      y = factor2,
      colour = "Response"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      legend.position = "right"
    )

  # Add stationary point
  if (show_stationary) {
    tryCatch(
      {
        canonical <- canonical_analysis(rsm_model)
        stat_point <- tibble::tibble(
          x = canonical$stationary_point[factor1],
          y = canonical$stationary_point[factor2]
        )
        p <- p +
          ggplot2::geom_point(
            data = stat_point,
            ggplot2::aes(x = x, y = y),
            colour = "red",
            size = 4,
            shape = 17,
            inherit.aes = FALSE
          ) +
          ggplot2::annotate(
            "text",
            x = stat_point$x,
            y = stat_point$y + 0.15,
            label = "Stationary",
            size = 3,
            colour = "red"
          )
      },
      error = function(e) {
        message("Could not add stationary point: ", e$message)
      }
    )
  }

  return(p)
}

#' Plot Isoquants (Contour Lines)
#'
#' Creates a detailed contour plot showing isoquants (lines of constant response)
#' for two factors.
#'
#' @param rsm_model An object of class "rsm_model".
#' @param factor1 Character name of first factor.
#' @param factor2 Character name of second factor.
#' @param fixed_values Named list with values for other factors.
#' @param n_grid Integer number of grid points. Default is 100.
#' @param n_levels Integer number of contour levels. Default is 10.
#'
#' @return A ggplot2 object with isoquants.
#'
#' @export
plot_isoquants <- function(rsm_model, factor1 = NULL, factor2 = NULL,
                           fixed_values = NULL, n_grid = 100, n_levels = 10) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  factors <- rsm_model$factors

  if (is.null(factor1)) factor1 <- factors[1]
  if (is.null(factor2)) factor2 <- factors[2]

  if (is.null(fixed_values)) {
    fixed_values <- purrr::map(factors[!(factors %in% c(factor1, factor2))], ~0)
  }

  # Create grid
  grid_f1 <- seq(-1.68, 1.68, length.out = n_grid)
  grid_f2 <- seq(-1.68, 1.68, length.out = n_grid)

  grid_data <- expand.grid(
    grid_f1,
    grid_f2
  )

  names(grid_data) <- c(factor1, factor2)


  for (factor in names(fixed_values)) {
    grid_data[[factor]] <- fixed_values[[factor]]
  }

  predictions <- predict_rsm(rsm_model, new_data = grid_data)

  plot_data <- predictions %>%
    dplyr::select(dplyr::all_of(c(factor1, factor2, "predicted_response"))) %>%
    dplyr::rename(
      x = !!factor1,
      y = !!factor2,
      response = "predicted_response"
    )

  # Create isoquant plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = x, y = y, z = response)) +
    ggplot2::geom_contour(
      ggplot2::aes(colour = ggplot2::after_stat(level)),
      size = 1,
      bins = n_levels
    ) +
    ggplot2::scale_colour_viridis_c(name = "Response") +
    ggplot2::labs(
      title = "Isoquants (Response Surface Contours)",
      x = factor1,
      y = factor2
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      panel.grid = ggplot2::element_line(colour = "grey90")
    )

  return(p)
}

#' Plot Interactive 3D Response Surface
#'
#' Creates an interactive 3D surface plot using plotly for exploring
#' the response surface dynamically.
#'
#' @param rsm_model An object of class "rsm_model".
#' @param factor1 Character name of first factor.
#' @param factor2 Character name of second factor.
#' @param fixed_values Named list with values for other factors.
#' @param n_grid Integer number of grid points. Default is 30.
#'
#' @return A plotly object with an interactive 3D surface.
#'
#' @examples
#' data <- tibble::tibble(
#'   Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
#'   P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
#'   S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
#' )
#'
#' model <- fit_second_order(data, response = "Y", factors = c("P_coded", "S_coded"))
#' plot_interactive_surface(model)
#'
#' @export
plot_interactive_surface <- function(rsm_model, factor1 = NULL, factor2 = NULL,
                                     fixed_values = NULL, n_grid = 30) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  factors <- rsm_model$factors

  if (is.null(factor1)) factor1 <- factors[1]
  if (is.null(factor2)) factor2 <- factors[2]

  if (is.null(fixed_values)) {
    fixed_values <- purrr::map(factors[!(factors %in% c(factor1, factor2))], ~0)
  }

  # Create grid
  grid_f1 <- seq(-1.68, 1.68, length.out = n_grid)
  grid_f2 <- seq(-1.68, 1.68, length.out = n_grid)

  grid_data <- expand.grid(
    grid_f1,
    grid_f2
  )

  names(grid_data) <- c(factor1, factor2)


  for (factor in names(fixed_values)) {
    grid_data[[factor]] <- fixed_values[[factor]]
  }

  predictions <- predict_rsm(rsm_model, new_data = grid_data)

  # Reshape for surface plot
  z_matrix <- matrix(
    predictions$predicted_response,
    nrow = n_grid,
    ncol = n_grid,
    byrow = TRUE
  )

  # Create interactive plot
  p <- plotly::plot_ly(
    x = ~grid_f1,
    y = ~grid_f2,
    z = ~z_matrix,
    type = "surface",
    colorscale = "Viridis"
  ) %>%
    plotly::layout(
      title = "Interactive Response Surface",
      scene = list(
        xaxis = list(title = factor1),
        yaxis = list(title = factor2),
        zaxis = list(title = rsm_model$response)
      )
    )

  return(p)
}

#' Plot Steepest Path
#'
#' Visualizes the path of steepest ascent/descent on a contour plot.
#'
#' @param steepest_path_obj An object of class "steepest_path".
#' @param rsm_model The original RSM model (for background contours).
#' @param factor1 Character name of first factor.
#' @param factor2 Character name of second factor.
#'
#' @return A ggplot2 object with contours and the steepest path.
#'
#' @export
plot_steepest_path <- function(steepest_path_obj, rsm_model, factor1 = NULL, factor2 = NULL) {
  if (!inherits(steepest_path_obj, "steepest_path")) {
    stop("First argument must be an object of class 'steepest_path'")
  }

  factors <- steepest_path_obj$factors

  if (is.null(factor1)) factor1 <- factors[1]
  if (is.null(factor2)) factor2 <- factors[2]

  # Get path data
  path_data <- steepest_path_obj$path_data %>%
    dplyr::select(dplyr::all_of(c(factor1, factor2, "predicted_response"))) %>%
    dplyr::rename(
      x = !!factor1,
      y = !!factor2,
      response = "predicted_response"
    )

  # Create background contours
  p <- plot_response_surface(rsm_model, factor1, factor2, show_stationary = FALSE)

  # Add path
  p <- p +
    ggplot2::geom_path(
      data = path_data,
      ggplot2::aes(x = x, y = y),
      colour = "red",
      size = 1.2,
      arrow = ggplot2::arrow(length = ggplot2::unit(0.3, "cm")),
      inherit.aes = FALSE
    ) +
    ggplot2::geom_point(
      data = path_data,
      ggplot2::aes(x = x, y = y),
      colour = "red",
      size = 2,
      inherit.aes = FALSE
    )

  return(p)
}
