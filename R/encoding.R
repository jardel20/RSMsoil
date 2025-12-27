#' Encode Variables to Coded Scale
#'
#' Transforms variables from their natural scale to a coded scale (-1, 0, +1) or
#' (-1.68, 0, +1.68) for rotatable designs. This is essential for response surface
#' methodology as it standardizes the experimental space.
#'
#' @param data A data frame or tibble containing the variables to encode.
#' @param factor_names Character vector with names of factors to encode.
#' @param levels A list with named numeric vectors. Each element should contain
#'   the low, center, and high levels for each factor. If NULL, levels are
#'   automatically detected from data (min, mean, max).
#'
#' @return A tibble with encoded variables (coded scale) added as new columns
#'   with suffix "_coded".
#'
#' @details
#' The encoding formula is:
#'
#' \deqn{X_i = \frac{x_i - x_{center}}{(x_{high} - x_{low}) / 2}}
#'
#' Where:
#' - \eqn{x_i} is the natural value
#' - \eqn{x_{center}} is the center point
#' - \eqn{x_{high}} and \eqn{x_{low}} are the high and low levels
#'
#' @examples
#' data <- tibble::tibble(
#'   P = c(18, 108, 180, 252, 342),
#'   S = c(6, 36, 60, 84, 114)
#' )
#'
#' # Automatic level detection
#' encoded <- encode_variables(data, factor_names = c("P", "S"))
#'
#' # Manual level specification
#' levels_list <- list(
#'   P = c(low = 18, center = 180, high = 342),
#'   S = c(low = 6, center = 60, high = 114)
#' )
#' encoded <- encode_variables(data, factor_names = c("P", "S"), levels = levels_list)
#'
#' @export
encode_variables <- function(data, factor_names, levels = NULL) {
  data <- tibble::as_tibble(data)

  if (is.null(levels)) {
    # Automatically detect levels from data
    levels <- purrr::map(factor_names, function(factor) {
      values <- data[[factor]]
      c(
        low = min(values, na.rm = TRUE),
        center = mean(values, na.rm = TRUE),
        high = max(values, na.rm = TRUE)
      )
    })
    names(levels) <- factor_names
  }

  # Encode each factor
  encoded_data <- data %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(factor_names),
        ~ {
          factor_name <- dplyr::cur_column()
          lvl <- levels[[factor_name]]
          center <- lvl["center"]
          range <- (lvl["high"] - lvl["low"]) / 2
          (. - center) / range
        },
        .names = "{.col}_coded"
      )
    )

  # Store levels as attribute for later decoding
  attr(encoded_data, "encoding_levels") <- levels

  return(encoded_data)
}

#' Decode Variables from Coded Scale
#'
#' Transforms variables from coded scale back to their natural scale.
#' This is the inverse operation of `encode_variables()`.
#'
#' @param data A data frame or tibble containing coded variables.
#' @param factor_names Character vector with names of coded factors (without "_coded" suffix).
#' @param levels A list with named numeric vectors containing the low, center,
#'   and high levels for each factor. If NULL, attempts to retrieve from data attributes.
#'
#' @return A tibble with decoded variables added as new columns with suffix "_natural".
#'
#' @details
#' The decoding formula is:
#'
#' \deqn{x_i = x_{center} + X_i \times \frac{(x_{high} - x_{low})}{2}}
#'
#' @examples
#' data <- tibble::tibble(P_coded = c(-1, 0, 1), S_coded = c(-1, 0, 1))
#'
#' levels_list <- list(
#'   P = c(low = 18, center = 180, high = 342),
#'   S = c(low = 6, center = 60, high = 114)
#' )
#'
#' decoded <- decode_variables(data, factor_names = c("P", "S"), levels = levels_list)
#'
#' @export
decode_variables <- function(data, factor_names, levels = NULL) {
  data <- tibble::as_tibble(data)

  if (is.null(levels)) {
    levels <- attr(data, "encoding_levels")
    if (is.null(levels)) {
      stop("Levels not provided and not found in data attributes.")
    }
  }

  # Decode each factor
  decoded_data <- data %>%
    dplyr::mutate(
      dplyr::across(
        paste0(factor_names, "_coded"),
        ~ {
          factor_name <- sub("_coded$", "", dplyr::cur_column())
          lvl <- levels[[factor_name]]
          center <- lvl["center"]
          range <- (lvl["high"] - lvl["low"]) / 2
          center + . * range
        },
        .names = "{sub('_coded$', '', .col)}_natural"
      )
    )

  return(decoded_data)
}
