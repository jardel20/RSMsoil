test_that("fit_first_order works correctly", {
  data <- tibble::tibble(
    Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
    P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
    S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
  )

  model <- fit_first_order(data, response = "Y", factors = c("P_coded", "S_coded"))

  expect_s3_class(model, "rsm_model")
  expect_equal(model$model_type, "first_order")
  expect_equal(model$response, "Y")
  expect_equal(model$factors, c("P_coded", "S_coded"))
  expect_true(model$r_squared > 0)
  expect_true(model$r_squared < 1)
})

test_that("fit_second_order works correctly", {
  data <- tibble::tibble(
    Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
    P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
    S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
  )

  model <- fit_second_order(data, response = "Y", factors = c("P_coded", "S_coded"))

  expect_s3_class(model, "rsm_model")
  expect_equal(model$model_type, "second_order")
  expect_true(nrow(model$coefficients) > 3)
  expect_true(model$r_squared > 0)
})

test_that("fit_response_surface generic function works", {
  data <- tibble::tibble(
    Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
    P_coded = c(-1, -1, 1, 1, 0, -1.68, 1.68, 0, 0),
    S_coded = c(-1, 1, -1, 1, 0, 0, 0, -1.68, 1.68)
  )

  model_1st <- fit_response_surface(data, response = "Y", factors = c("P_coded", "S_coded"), order = 1)
  expect_equal(model_1st$model_type, "first_order")

  model_2nd <- fit_response_surface(data, response = "Y", factors = c("P_coded", "S_coded"), order = 2)
  expect_equal(model_2nd$model_type, "second_order")
})
