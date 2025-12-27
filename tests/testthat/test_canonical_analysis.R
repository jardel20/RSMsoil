test_that("canonical_analysis works correctly", {
  data <- tibble::tibble(
    Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
    P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
    S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
  )

  model <- fit_second_order(data, response = "Y", factors = c("P_coded", "S_coded"))
  canonical <- canonical_analysis(model)

  expect_s3_class(canonical, "canonical_analysis")
  expect_true(length(canonical$stationary_point) == 2)
  expect_true(length(canonical$eigenvalues) == 2)
  expect_true(canonical$surface_type %in% c("Maximum", "Minimum", "Saddle Point"))
})

test_that("canonical_analysis requires second-order model", {
  data <- tibble::tibble(
    Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
    P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
    S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
  )

  model <- fit_first_order(data, response = "Y", factors = c("P_coded", "S_coded"))

  expect_error(canonical_analysis(model), "second-order model")
})
