#' ANOVA Analysis for Response Surface Models
#'
#' Performs comprehensive ANOVA analysis including significance tests for
#' regression coefficients and model fit assessment.
#'
#' @param rsm_model An object of class "rsm_model".
#' @param alpha Significance level for hypothesis tests. Default is 0.05.
#'
#' @return A list containing:
#'   - `anova_table`: ANOVA table with sums of squares, degrees of freedom, mean squares, and F-statistics
#'   - `coefficient_tests`: Tibble with t-tests for individual coefficients
#'   - `model_significance`: F-test for overall model significance
#'   - `significant_terms`: Terms significant at alpha level
#'
#' @details
#' The ANOVA table includes:
#' - Regression Sum of Squares (SSR)
#' - Residual Sum of Squares (SSE)
#' - Total Sum of Squares (SST)
#' - Mean Squares (MS = SS / df)
#' - F-statistic = MSR / MSE
#'
#' Individual coefficients are tested using t-statistics:
#'
#' \deqn{t = \frac{\beta_i}{SE(\beta_i)}}
#'
#' @examples
#' data <- tibble::tibble(
#'   Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
#'   P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
#'   S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
#' )
#'
#' model <- fit_second_order(data, response = "Y", factors = c("P_coded", "S_coded"))
#' anova_result <- anova_rsm(model, alpha = 0.10)
#'
#' @export
anova_rsm <- function(rsm_model, alpha = 0.05) {
  if (!inherits(rsm_model, "rsm_model")) {
    stop("Input must be an object of class 'rsm_model'")
  }

  # Extract ANOVA table
  anova_table <- rsm_model$anova_table
  anova_df <- as.data.frame(anova_table)
  anova_df$term <- rownames(anova_df)

  # Calculate F-statistic for overall model significance
  n <- nrow(rsm_model$data)
  p <- length(rsm_model$model$coefficients) - 1 # Exclude intercept
  df_reg <- p
  df_res <- n - p - 1

  ss_reg <- sum(anova_df$`Sum Sq`[-nrow(anova_df)])
  ss_res <- anova_df$`Sum Sq`[nrow(anova_df)]
  ms_reg <- ss_reg / df_reg
  ms_res <- ss_res / df_res

  f_stat <- ms_reg / ms_res
  p_value_f <- 1 - stats::pf(f_stat, df_reg, df_res)

  # Test individual coefficients
  coef_tests <- rsm_model$coefficients %>%
    dplyr::mutate(
      significant = dplyr::if_else(p_value < alpha, "Yes", "No"),
      ci_lower = estimate - stats::qt(1 - alpha / 2, df_res) * std_error,
      ci_upper = estimate + stats::qt(1 - alpha / 2, df_res) * std_error
    )

  # Identify significant terms
  significant_terms <- coef_tests %>%
    dplyr::filter(significant == "Yes") %>%
    dplyr::pull(term)

  # Create result object
  result <- list(
    anova_table = anova_table,
    anova_df = anova_df,
    coefficient_tests = coef_tests,
    model_significance = list(
      f_statistic = f_stat,
      p_value = p_value_f,
      df_reg = df_reg,
      df_res = df_res,
      significant = p_value_f < alpha
    ),
    significant_terms = significant_terms,
    alpha = alpha,
    r_squared = rsm_model$r_squared,
    adj_r_squared = rsm_model$adj_r_squared
  )

  class(result) <- c("anova_rsm", "list")
  return(result)
}

#' Print Method for ANOVA RSM Results
#'
#' @param x An object of class "anova_rsm".
#' @param ... Additional arguments (unused).
#'
#' @export
print.anova_rsm <- function(x, ...) {
  cat("\n=== ANOVA Analysis for Response Surface Model ===\n")
  cat("Significance level (alpha):", x$alpha, "\n\n")

  cat("ANOVA Table:\n")
  print(x$anova_table)

  cat("\n\nOverall Model Significance:\n")
  cat("F-statistic:", round(x$model_significance$f_statistic, 4), "\n")
  cat("P-value:", round(x$model_significance$p_value, 4), "\n")
  cat("Significant:", x$model_significance$significant, "\n")

  cat("\n\nCoefficient Tests:\n")
  print(x$coefficient_tests)

  cat("\n\nSignificant Terms:", paste(x$significant_terms, collapse = ", "), "\n")
  cat("R-squared:", round(x$r_squared, 4), "\n")
  cat("Adjusted R-squared:", round(x$adj_r_squared, 4), "\n")
  cat("\n")
}

#' Summary Method for ANOVA RSM Results
#'
#' @param object An object of class "anova_rsm".
#' @param ... Additional arguments (unused).
#'
#' @export
summary.anova_rsm <- function(object, ...) {
  print(object)
}
