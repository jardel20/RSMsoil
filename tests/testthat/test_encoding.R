test_that("encode_variables works correctly", {
  data <- tibble::tibble(
    P = c(18, 108, 180, 252, 342),
    S = c(6, 36, 60, 84, 114)
  )

  # Test automatic level detection
  encoded <- encode_variables(data, factor_names = c("P", "S"))

  expect_true("P_coded" %in% names(encoded))
  expect_true("S_coded" %in% names(encoded))

  # Check that center point is 0
  expect_equal(encoded$P_coded[3], 0, tolerance = 1e-10)
  expect_equal(encoded$S_coded[3], 0, tolerance = 1e-10)

  # Check that extreme points are ±1
  expect_equal(encoded$P_coded[1], -1, tolerance = 1e-10)
  expect_equal(encoded$P_coded[5], 1, tolerance = 1e-10)
})

test_that("decode_variables reverses encoding", {
  data <- tibble::tibble(
    P = c(18, 180, 342),
    S = c(6, 60, 114)
  )

  levels_list <- list(
    P = c(low = 18, center = 180, high = 342),
    S = c(low = 6, center = 60, high = 114)
  )

  encoded <- encode_variables(data, factor_names = c("P", "S"), levels = levels_list)
  decoded <- decode_variables(encoded, factor_names = c("P", "S"), levels = levels_list)

  expect_equal(decoded$P_natural, data$P, tolerance = 1e-10)
  expect_equal(decoded$S_natural, data$S, tolerance = 1e-10)
})
