# RSMsoil: Response Surface Methodology for Soil Fertility Assessment

An R package implementing comprehensive response surface methodology (RSM) analysis for soil fertility and agronomic experiments, following the rigorous methodology of Victor Hugo Alvarez V. (2008).

## Features

- **Variable Encoding/Decoding**: Transform variables between natural and coded scales
- **Multiple Model Types**: First-order, first-order with interaction, and second-order (quadratic) models
- **Statistical Analysis**: ANOVA, significance tests, and confidence intervals
- **Canonical Analysis**: Characterization of stationary points and surface classification (maximum, minimum, saddle point)
- **Optimization**: Path of steepest ascent/descent and grid search for optimal factor levels
- **Visualization**: Static contour plots (ggplot2) and interactive 3D surfaces (plotly)
- **Model Diagnostics**: Residual analysis and model validation
- **Flexible**: Supports any number of factors (≥ 2)

## Installation

```r
# Development version from GitHub
# devtools::install_github("user/RSMsoil")

# Or install from source
install.packages("path/to/RSMsoil_0.1.0.tar.gz", repos = NULL)
```

## Quick Start

```r
library(RSMsoil)

# Create experimental data
data <- tibble::tibble(
  Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
  P = c(108, 108, 252, 252, 180, 18, 342, 108, 252),
  S = c(36, 84, 36, 84, 60, 36, 84, 6, 114)
)

# Encode variables to coded scale
levels_list <- list(
  P = c(low = 18, center = 180, high = 342),
  S = c(low = 6, center = 60, high = 114)
)

data_encoded <- encode_variables(data, factor_names = c("P", "S"), levels = levels_list)

# Fit second-order model
model <- fit_second_order(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))

# Analyze results
summary(model)
anova_result <- anova_rsm(model)
canonical <- canonical_analysis(model)

# Visualize
plot_response_surface(model)
plot_interactive_surface(model)

# Optimize
path <- steepest_path(model)
optimal <- get_optimal_factors(model, objective = "maximize")
```

## Main Functions

### Data Preparation
- `encode_variables()` - Transform variables to coded scale
- `decode_variables()` - Transform variables back to natural scale
- `generate_design()` - Create experimental designs (CCD, factorial)

### Model Fitting
- `fit_first_order()` - Fit first-order linear model
- `fit_first_order_interaction()` - Fit first-order with interaction terms
- `fit_second_order()` - Fit complete second-order quadratic model
- `fit_response_surface()` - Generic function to fit any model type

### Statistical Analysis
- `anova_rsm()` - Comprehensive ANOVA analysis
- `canonical_analysis()` - Canonical analysis and stationary point characterization
- `compare_models()` - Compare nested models

### Optimization
- `steepest_path()` - Path of steepest ascent/descent
- `get_optimal_factors()` - Grid search for optimal factor levels
- `get_stationary_point()` - Extract stationary point from canonical analysis

### Prediction and Diagnostics
- `predict_rsm()` - Make predictions at new factor combinations
- `plot_diagnostics()` - Model diagnostic plots
- `get_residuals()`, `get_fitted_values()` - Extract model components

### Visualization
- `plot_response_surface()` - Static contour plot
- `plot_isoquants()` - Isoquant (contour line) plot
- `plot_interactive_surface()` - Interactive 3D surface (plotly)
- `plot_steepest_path()` - Visualize steepest path on contours

## Methodology

The package implements the complete RSM workflow:

1. **Experimental Design**: Central Composite Design (CCD) or factorial designs
2. **Variable Encoding**: Transform to coded scale for standardization
3. **Model Selection**: Choose appropriate polynomial order
4. **Parameter Estimation**: Ordinary Least Squares (OLS) regression
5. **Statistical Testing**: ANOVA and significance tests
6. **Canonical Analysis**: Characterize the response surface
7. **Optimization**: Find optimal factor levels
8. **Validation**: Diagnostic plots and residual analysis

## Mathematical Foundation

The package follows the mathematical framework from Alvarez V. (2008):

### First-Order Model
$$Y = \beta_0 + \sum_{i=1}^{k} \beta_i X_i + \epsilon$$

### Second-Order Model
$$Y = \beta_0 + \sum_{i=1}^{k} \beta_i X_i + \sum_{i=1}^{k} \beta_{ii} X_i^2 + \sum_{i<j} \beta_{ij} X_i X_j + \epsilon$$

### Canonical Form
$$Y = Y_s + \sum_{i=1}^{k} \lambda_i W_i^2$$

Where $\lambda_i$ are eigenvalues of the Hessian matrix and $W_i$ are canonical variables.

## Requirements

- R ≥ 4.0
- dplyr, tidyr, purrr, tibble
- ggplot2, plotly
- Matrix, stats

## References

Alvarez V., V. H. (2008). **Avaliação da Fertilidade do Solo: Superfícies de Resposta - Modelos Aproximativos para Expressar a Relação Fator-Resposta**. Universidade Federal de Viçosa, Brazil.

Box, G. E. P., & Wilson, K. B. (1951). On the experimental attainment of optimum conditions. *Journal of the Royal Statistical Society*, 13, 1-45.

Myers, R. H., Montgomery, D. C., & Anderson-Cook, C. M. (2016). **Response Surface Methodology: Process and Product Optimization Using Designed Experiments** (3rd ed.). Wiley.

## License

MIT License - See LICENSE file for details

## Author

Developed by Manus AI based on the methodology of Victor Hugo Alvarez V.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Citation

If you use RSMsoil in your research, please cite:

```bibtex
@software{rsmsoil2024,
  title = {RSMsoil: Response Surface Methodology for Soil Fertility Assessment},
  author = {Manus AI},
  year = {2024},
  note = {R package version 0.1.0}
}
```
