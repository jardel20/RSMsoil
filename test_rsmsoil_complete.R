rm(list = ls())
packages_required <- c("tibble", "dplyr", "tidyr", "purrr", "ggplot2", "plotly", "RSMsoil")

for (pkg in packages_required) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Instalando pacote:", pkg, "\n")
    install.packages(pkg, quiet = TRUE)
    library(pkg, character.only = TRUE, quietly = TRUE)
  }
}

data_original <- tibble(
  treatment = 1:9,
  P = c(108, 108, 252, 252, 180, 18, 342, 108, 252),
  S = c(36, 84, 36, 84, 60, 36, 84, 6, 114),
  Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67)
)

print(data_original)
cat(
  "  P: min =", min(data_original$P), ", mean =", mean(data_original$P),
  ", max =", max(data_original$P), "\n"
)
cat(
  "  S: min =", min(data_original$S), ", mean =", mean(data_original$S),
  ", max =", max(data_original$S), "\n"
)
cat(
  "  Y: min =", round(min(data_original$Y), 4), ", mean =", round(mean(data_original$Y), 4),
  ", max =", round(max(data_original$Y), 4), "\n\n"
)

# SEÇÃO 3: CODIFICAÇÃO DE VARIÁVEIS

# Definir níveis (baixo, centro, alto)
levels_list <- list(
  P = c(low = 18, center = 180, high = 342),
  S = c(low = 6, center = 60, high = 114)
)

cat("Níveis definidos:\n")
cat(
  "  P: low =", levels_list$P["low"], ", center =", levels_list$P["center"],
  ", high =", levels_list$P["high"], "\n"
)
cat(
  "  S: low =", levels_list$S["low"], ", center =", levels_list$S["center"],
  ", high =", levels_list$S["high"], "\n\n"
)

# Codificar variáveis
data_encoded <- encode_variables(data_original, factor_names = c("P", "S"), levels = levels_list)

cat("Dados codificados (escala padronizada -1, 0, +1):\n")
print(data_encoded %>% select(treatment, P_coded, S_coded, Y))

# SEÇÃO 4: AJUSTE DE MODELOS
# Modelo de 1ª ordem
model_1st <- fit_first_order(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))
cat("  R²:", round(model_1st$r_squared, 4), "\n")
cat("  R² ajustado:", round(model_1st$adj_r_squared, 4), "\n")
cat("  Erro padrão residual:", round(model_1st$residual_std_error, 4), "\n")
print(model_1st$coefficients)

# Modelo de 1ª ordem com interação
model_1st_int <- fit_first_order_interaction(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))
cat("  R²:", round(model_1st_int$r_squared, 4), "\n")
cat("  R² ajustado:", round(model_1st_int$adj_r_squared, 4), "\n")
print(model_1st_int$coefficients)

# Modelo de 2ª ordem (quadrático)
model_2nd <- fit_second_order(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))
cat("  R²:", round(model_2nd$r_squared, 4), "\n")
cat("  R² ajustado:", round(model_2nd$adj_r_squared, 4), "\n")
cat("  Erro padrão residual:", round(model_2nd$residual_std_error, 4), "\n")
cat("  Número de coeficientes:", nrow(model_2nd$coefficients), "\n")
print(model_2nd$coefficients)

# SEÇÃO 5: ANÁLISE DE VARIÂNCIA (ANOVA)
anova_result <- anova_rsm(model_2nd, alpha = 0.10)

cat("  F-estatístico:", round(anova_result$model_significance$f_statistic, 4), "\n")
cat("  P-valor:", round(anova_result$model_significance$p_value, 4), "\n")
cat("  Significante:", anova_result$model_significance$significant, "\n\n")
cat("Coeficientes Significativos (α = 0.10):\n")

print(anova_result$coefficient_tests %>% filter(significant == "Yes"))
cat("Termos Significativos:", paste(anova_result$significant_terms, collapse = ", "), "\n")
cat("R²:", round(anova_result$r_squared, 4), "\n")
cat("R² ajustado:", round(anova_result$adj_r_squared, 4), "\n")

# SEÇÃO 6: ANÁLISE CANÔNICA
canonical <- canonical_analysis(model_2nd)
cat("Ponto Estacionário (Escala Codificada):\n")
for (i in seq_along(canonical$stationary_point)) {
  cat(
    "  ", names(canonical$stationary_point)[i], "=",
    round(canonical$stationary_point[i], 4), "\n"
  )
}

if (!is.null(canonical$stationary_point_natural)) {
  cat("Ponto Estacionário (Escala Natural):\n")
  for (i in seq_along(canonical$stationary_point_natural)) {
    cat(
      "  ", names(canonical$stationary_point_natural)[i], "=",
      round(canonical$stationary_point_natural[i], 2), "\n"
    )
  }
  cat("\n")
}

cat("Resposta Predita no Ponto Estacionário:", round(canonical$predicted_response, 4), "\n\n")

cat("Autovalores da Matriz Hessiana:\n")
for (i in seq_along(canonical$eigenvalues)) {
  cat("  λ", i, "=", round(canonical$eigenvalues[i], 6), "\n")
}

# SEÇÃO 7: CAMINHO DE MÁXIMA INCLINAÇÃO
path <- steepest_path(model_2nd, n_steps = 6, step_size = 0.2)
cat("Direção (Gradiente Normalizado):\n")
for (i in seq_along(path$direction_vector)) {
  cat(
    "  ", names(path$direction_vector)[i], "=",
    round(path$direction_vector[i], 4), "\n"
  )
}
cat("Sequência de Pontos ao Longo do Caminho:\n")
print(path$path_data)

# SEÇÃO 8: PREDIÇÃO EM NOVOS PONTOS
# Novos pontos para predição
new_points <- tibble(
  P_coded = c(0, 0.5, -0.5, 1.0, -1.0),
  S_coded = c(0, 0.5, -0.5, 1.0, -1.0)
)

predictions <- predict_rsm(model_2nd, new_data = new_points, se_fit = TRUE)

cat("Predições em Novos Pontos (com Intervalos de Confiança 95%):\n")
print(predictions)

# SEÇÃO 9: OTIMIZAÇÃO
# Busca por grid para maximização
optimization <- get_optimal_factors(model_2nd, objective = "maximize", n_grid = 15)

cat("Ponto Ótimo Encontrado (Maximização):\n")
print(optimization$optimal_point)
cat("\nResposta Ótima Predita:", round(optimization$optimal_response, 4), "\n\n")

# Extrair ponto estacionário
stationary <- get_stationary_point(canonical, include_natural = TRUE)
cat("Ponto Estacionário (Recomendação):\n")
print(stationary)

# SEÇÃO 10: UTILITÁRIOS E DIAGNÓSTICOS
# Extrair componentes do modelo
residuals <- get_residuals(model_2nd)
fitted <- get_fitted_values(model_2nd)

cat("Resíduos (primeiros 5):\n")
print(round(head(residuals, 5), 4))

cat("Valores Ajustados (primeiros 5):\n")
print(round(head(fitted, 5), 4))

# Gerar delineamento experimental
design_ccd <- generate_design(n_factors = 2, design = "ccd", alpha = 1.68, n_center = 2)
cat("Design CCD Gerado (", nrow(design_ccd), "pontos):\n")
print(head(design_ccd, 10))

# SEÇÃO 11: COMPARAÇÃO DE MODELOS
comparison <- compare_models(model_1st, model_2nd)
cat("Comparação entre Modelo de 1ª Ordem e 2ª Ordem:\n")
print(comparison)

# SEÇÃO 12: VISUALIZAÇÕES
# Gráfico 1: Superfície de Resposta
p1 <- plot_response_surface(model_2nd, show_stationary = TRUE)
p1

# Gráfico 2: Isoquantas
p2 <- plot_isoquants(model_2nd, n_grid = 100, n_levels = 12)
p2

# Gráfico 3: Caminho de Máxima Inclinação
p3 <- plot_steepest_path(path, model_2nd)
p3

# Gráfico 4: Plot insterativo
p4 <- plot_interactive_surface(rsm_model = model_1st)
p4
p5 <- plot_interactive_surface(rsm_model = model_1st_int)
p5
p6 <- plot_interactive_surface(rsm_model = model_2nd)
p6

# Gráfico 5: Diagnósticos
cat("12.4 - Gráficos de Diagnóstico\n")
diagnostics <- plot_diagnostics(model_2nd)
cat("  - Resíduos vs Ajustados\n")
print(diagnostics$residuals_vs_fitted)
cat("  - Q-Q Plot\n")
print(diagnostics$qq_plot)
cat("  - Scale-Location\n")
print(diagnostics$scale_location)
cat("  - Resíduos vs Alavancagem\n")
print(diagnostics$residuals_vs_leverage)
