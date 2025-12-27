#' RSMsoil: Response Surface Methodology for Soil Fertility Assessment
#'
#' A comprehensive R package for response surface methodology (RSM) analysis
#' following the methodology of Victor Hugo Alvarez V. (2008). The package
#' implements first and second-order polynomial models, canonical analysis,
#' path of steepest ascent/descent, and interactive visualization of response
#' surfaces for soil fertility and agronomic experiments.
#'
#' @section Main Features:
#' - **Variable Encoding/Decoding**: Transform variables between natural and coded scales
#' - **Model Fitting**: First-order, first-order with interaction, and second-order models
#' - **ANOVA Analysis**: Comprehensive statistical tests and significance assessment
#' - **Canonical Analysis**: Characterization of stationary points and surface classification
#' - **Steepest Path**: Path of maximum ascent/descent for optimization
#' - **Visualization**: Static (ggplot2) and interactive (plotly) 3D surface plots
#' - **Optimization**: Grid search for optimal factor levels
#' - **Diagnostics**: Model validation and residual analysis
#'
#' @section Workflow:
#' 1. Encode variables to coded scale using `encode_variables()`
#' 2. Fit appropriate model: `fit_first_order()`, `fit_second_order()`, etc.
#' 3. Analyze results with `anova_rsm()` and `canonical_analysis()`
#' 4. Visualize with `plot_response_surface()` or `plot_interactive_surface()`
#' 5. Optimize with `steepest_path()` or `get_optimal_factors()`
#'
#' @section References:
#' Alvarez V., V. H. (2008). Avaliação da Fertilidade do Solo: Superfícies de
#' Resposta - Modelos Aproximativos para Expressar a Relação Fator-Resposta.
#' Universidade Federal de Viçosa, Brazil.
#'
#' @docType package
#' @name RSMsoil
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
