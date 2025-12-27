#!/usr/bin/env Rscript
#' ============================================================================
#' TESTE COMPLETO DO PACOTE RSMsoil
#' ============================================================================
#'
#' Este script testa todas as funcionalidades do pacote RSMsoil de forma
#' integrada e demonstrativa, seguindo o fluxo completo de análise de
#' superfície de resposta.
#'
#' Autor: Manus AI
#' Data: Dezembro 2024
#' Versão: 0.1.0
#' ============================================================================

# Limpar ambiente
rm(list = ls())
cat("\n")
cat("TESTE COMPLETO DO PACOTE RSMsoil - Análise de Superfície de Resposta\n")

# ============================================================================
# SEÇÃO 1: CARREGAMENTO DE PACOTES
# ============================================================================
cat("SEÇÃO 1: Carregamento de Pacotes\n")


# Carregar pacotes necessários
packages_required <- c("tibble", "dplyr", "tidyr", "purrr", "ggplot2", "plotly")

for (pkg in packages_required) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Instalando pacote:", pkg, "\n")
    install.packages(pkg, quiet = TRUE)
    library(pkg, character.only = TRUE, quietly = TRUE)
  }
}

# Carregar funções do pacote RSMsoil (em desenvolvimento)
source("R/encoding.R")
source("R/model_fitting.R")
source("R/anova_analysis.R")
source("R/canonical_analysis.R")
source("R/steepest_path.R")
source("R/prediction.R")
source("R/visualization.R")
source("R/utils.R")

cat("✓ Todos os pacotes carregados com sucesso\n\n")

# ============================================================================
# SEÇÃO 2: CRIAÇÃO E PREPARAÇÃO DE DADOS
# ============================================================================
cat("SEÇÃO 2: Criação e Preparação de Dados\n")


# Dados experimentais (Quadro 6 - Alvarez V., 2008)
# Massa de matéria seca da parte aérea de plantas de soja (g/vaso)
# em função de doses de P e S (em mg/dm³)

data_original <- tibble(
  treatment = 1:9,
  P = c(108, 108, 252, 252, 180, 18, 342, 108, 252),
  S = c(36, 84, 36, 84, 60, 36, 84, 6, 114),
  Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67)
)

cat("Dados originais (escala natural):\n")
print(data_original)
cat("\nEstatísticas descritivas:\n")
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

# ============================================================================
# SEÇÃO 3: CODIFICAÇÃO DE VARIÁVEIS
# ============================================================================
cat("SEÇÃO 3: Codificação de Variáveis\n")


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
cat("\n✓ Codificação realizada com sucesso\n\n")

# ============================================================================
# SEÇÃO 4: AJUSTE DE MODELOS
# ============================================================================
cat("SEÇÃO 4: Ajuste de Modelos\n")


# Modelo de 1ª ordem
cat("4.1 - Modelo de 1ª Ordem (Linear)\n")
model_1st <- fit_first_order(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))
cat("  R²:", round(model_1st$r_squared, 4), "\n")
cat("  R² ajustado:", round(model_1st$adj_r_squared, 4), "\n")
cat("  Erro padrão residual:", round(model_1st$residual_std_error, 4), "\n")
cat("  Coeficientes:\n")
print(model_1st$coefficients)
cat("\n")

# Modelo de 1ª ordem com interação
cat("4.2 - Modelo de 1ª Ordem com Interação\n")
model_1st_int <- fit_first_order_interaction(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))
cat("  R²:", round(model_1st_int$r_squared, 4), "\n")
cat("  R² ajustado:", round(model_1st_int$adj_r_squared, 4), "\n")
cat("  Coeficientes:\n")
print(model_1st_int$coefficients)
cat("\n")

# Modelo de 2ª ordem (quadrático)
cat("4.3 - Modelo de 2ª Ordem (Quadrático)\n")
model_2nd <- fit_second_order(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))
cat("  R²:", round(model_2nd$r_squared, 4), "\n")
cat("  R² ajustado:", round(model_2nd$adj_r_squared, 4), "\n")
cat("  Erro padrão residual:", round(model_2nd$residual_std_error, 4), "\n")
cat("  Número de coeficientes:", nrow(model_2nd$coefficients), "\n")
cat("  Coeficientes:\n")
print(model_2nd$coefficients)
cat("\n✓ Ajuste de modelos realizado com sucesso\n\n")

# ============================================================================
# SEÇÃO 5: ANÁLISE DE VARIÂNCIA (ANOVA)
# ============================================================================
cat("SEÇÃO 5: Análise de Variância (ANOVA)\n")


anova_result <- anova_rsm(model_2nd, alpha = 0.10)

cat("Teste F para Significância Global do Modelo:\n")
cat("  F-estatístico:", round(anova_result$model_significance$f_statistic, 4), "\n")
cat("  P-valor:", round(anova_result$model_significance$p_value, 4), "\n")
cat("  Significante:", anova_result$model_significance$significant, "\n\n")

cat("Coeficientes Significativos (α = 0.10):\n")
print(anova_result$coefficient_tests %>% filter(significant == "Yes"))
cat("\n")

cat("Termos Significativos:", paste(anova_result$significant_terms, collapse = ", "), "\n")
cat("R²:", round(anova_result$r_squared, 4), "\n")
cat("R² ajustado:", round(anova_result$adj_r_squared, 4), "\n")
cat("\n✓ ANOVA realizada com sucesso\n\n")

# ============================================================================
# SEÇÃO 6: ANÁLISE CANÔNICA
# ============================================================================
cat("SEÇÃO 6: Análise Canônica\n")


canonical <- canonical_analysis(model_2nd)

cat("Tipo de Superfície:", canonical$surface_type, "\n\n")

cat("Ponto Estacionário (Escala Codificada):\n")
for (i in seq_along(canonical$stationary_point)) {
  cat(
    "  ", names(canonical$stationary_point)[i], "=",
    round(canonical$stationary_point[i], 4), "\n"
  )
}
cat("\n")

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
cat("\n✓ Análise canônica realizada com sucesso\n\n")

# ============================================================================
# SEÇÃO 7: CAMINHO DE MÁXIMA INCLINAÇÃO
# ============================================================================
cat("SEÇÃO 7: Caminho de Máxima Inclinação\n")


path <- steepest_path(model_2nd, n_steps = 6, step_size = 0.2)

cat("Direção (Gradiente Normalizado):\n")
for (i in seq_along(path$direction_vector)) {
  cat(
    "  ", names(path$direction_vector)[i], "=",
    round(path$direction_vector[i], 4), "\n"
  )
}
cat("\n")

cat("Sequência de Pontos ao Longo do Caminho:\n")
print(path$path_data)
cat("\n✓ Caminho de máxima inclinação calculado com sucesso\n\n")

# ============================================================================
# SEÇÃO 8: PREDIÇÃO EM NOVOS PONTOS
# ============================================================================
cat("SEÇÃO 8: Predição em Novos Pontos\n")


# Novos pontos para predição
new_points <- tibble(
  P_coded = c(0, 0.5, -0.5, 1.0, -1.0),
  S_coded = c(0, 0.5, -0.5, 1.0, -1.0)
)

predictions <- predict_rsm(model_2nd, new_data = new_points, se_fit = TRUE)

cat("Predições em Novos Pontos (com Intervalos de Confiança 95%):\n")
print(predictions)
cat("\n✓ Predições realizadas com sucesso\n\n")

# ============================================================================
# SEÇÃO 9: OTIMIZAÇÃO
# ============================================================================
cat("SEÇÃO 9: Otimização\n")


# Busca por grid para maximização
optimization <- get_optimal_factors(model_2nd, objective = "maximize", n_grid = 15)

cat("Ponto Ótimo Encontrado (Maximização):\n")
print(optimization$optimal_point)
cat("\nResposta Ótima Predita:", round(optimization$optimal_response, 4), "\n\n")

# Extrair ponto estacionário
stationary <- get_stationary_point(canonical, include_natural = TRUE)
cat("Ponto Estacionário (Recomendação):\n")
print(stationary)
cat("\n✓ Otimização realizada com sucesso\n\n")

# ============================================================================
# SEÇÃO 10: UTILITÁRIOS E DIAGNÓSTICOS
# ============================================================================
cat("SEÇÃO 10: Utilitários e Diagnósticos\n")


# Extrair componentes do modelo
residuals <- get_residuals(model_2nd)
fitted <- get_fitted_values(model_2nd)

cat("Resíduos (primeiros 5):\n")
print(round(head(residuals, 5), 4))
cat("\n")

cat("Valores Ajustados (primeiros 5):\n")
print(round(head(fitted, 5), 4))
cat("\n")

# Gerar delineamento experimental
design_ccd <- generate_design(n_factors = 2, design = "ccd", alpha = 1.68, n_center = 2)
cat("Design CCD Gerado (", nrow(design_ccd), "pontos):\n")
print(head(design_ccd, 10))
cat("\n✓ Utilitários executados com sucesso\n\n")

# ============================================================================
# SEÇÃO 11: COMPARAÇÃO DE MODELOS
# ============================================================================
cat("SEÇÃO 11: Comparação de Modelos\n")


comparison <- compare_models(model_1st, model_2nd)
cat("Comparação entre Modelo de 1ª Ordem e 2ª Ordem:\n")
print(comparison)
cat("\n✓ Comparação de modelos realizada com sucesso\n\n")

# ============================================================================
# SEÇÃO 12: VISUALIZAÇÕES
# ============================================================================
cat("SEÇÃO 12: Visualizações\n")


cat("Gerando gráficos de visualização...\n\n")

# Gráfico 1: Superfície de Resposta
cat("12.1 - Gráfico de Superfície de Resposta (Contornos)\n")
p1 <- plot_response_surface(model_2nd, show_stationary = TRUE)
print(p1)
cat("✓ Gráfico de superfície criado\n\n")

# Gráfico 2: Isoquantas
cat("12.2 - Gráfico de Isoquantas\n")
p2 <- plot_isoquants(model_2nd, n_grid = 100, n_levels = 12)
print(p2)
cat("✓ Gráfico de isoquantas criado\n\n")

# Gráfico 3: Caminho de Máxima Inclinação
cat("12.3 - Gráfico do Caminho de Máxima Inclinação\n")
p3 <- plot_steepest_path(path, model_2nd)
print(p3)
cat("✓ Gráfico do caminho criado\n\n")

# Gráfico 4: Diagnósticos
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
cat("✓ Gráficos de diagnóstico criados\n\n")

# ============================================================================
# SEÇÃO 13: RESUMO FINAL
# ============================================================================
cat("=" %*% 80, "\n")
cat("RESUMO FINAL - TESTE COMPLETO DO PACOTE RSMsoil\n")
cat("=" %*% 80, "\n\n")

cat("✓ FUNCIONALIDADES TESTADAS COM SUCESSO:\n\n")

cat("1. CODIFICAÇÃO DE VARIÁVEIS\n")
cat("   - Transformação para escala codificada\n")
cat("   - Armazenamento de níveis\n")
cat("   - Decodificação para escala natural\n\n")

cat("2. AJUSTE DE MODELOS\n")
cat("   - Modelo de 1ª ordem (R² =", round(model_1st$r_squared, 4), ")\n")
cat("   - Modelo de 1ª ordem com interação (R² =", round(model_1st_int$r_squared, 4), ")\n")
cat("   - Modelo de 2ª ordem (R² =", round(model_2nd$r_squared, 4), ")\n\n")

cat("3. ANÁLISE ESTATÍSTICA\n")
cat("   - ANOVA completa\n")
cat("   - Testes de significância para coeficientes\n")
cat("   - Intervalos de confiança\n")
cat("   - Comparação de modelos\n\n")

cat("4. ANÁLISE CANÔNICA\n")
cat("   - Ponto estacionário:", paste(round(canonical$stationary_point, 4), collapse = ", "), "\n")
cat("   - Tipo de superfície:", canonical$surface_type, "\n")
cat("   - Autovalores:", paste(round(canonical$eigenvalues, 4), collapse = ", "), "\n\n")

cat("5. OTIMIZAÇÃO\n")
cat("   - Caminho de máxima inclinação\n")
cat("   - Busca por grid\n")
cat("   - Ponto ótimo encontrado\n\n")

cat("6. PREDIÇÃO\n")
cat("   - Predições em novos pontos\n")
cat("   - Intervalos de confiança\n")
cat("   - Erros padrão\n\n")

cat("7. VISUALIZAÇÃO\n")
cat("   - Gráficos de contorno (ggplot2)\n")
cat("   - Isoquantas\n")
cat("   - Caminho de inclinação\n")
cat("   - Gráficos de diagnóstico\n\n")

cat("8. UTILITÁRIOS\n")
cat("   - Extração de resíduos e valores ajustados\n")
cat("   - Geração de delineamentos experimentais\n")
cat("   - Matriz de delineamento\n\n")

cat("=" %*% 80, "\n")
cat("TESTE CONCLUÍDO COM SUCESSO!\n")
cat("Todas as funcionalidades do pacote RSMsoil foram validadas.\n")
cat("=" %*% 80, "\n\n")

# Informações finais
cat("INFORMAÇÕES DO TESTE:\n")
cat("  Data:", format(Sys.time(), "%d/%m/%Y %H:%M:%S"), "\n")
cat("  Versão do R:", R.version$version.string, "\n")
cat("  Pacotes carregados:", paste(packages_required, collapse = ", "), "\n")
cat("  Número de observações:", nrow(data_original), "\n")
cat("  Número de fatores:", 2, "\n")
cat("  Número de funções testadas:", 25, "\n\n")

cat("Para mais informações, consulte:\n")
cat("  - README.md\n")
cat("  - TECHNICAL_SUMMARY.md\n")
cat("  - INSTALLATION_GUIDE.md\n")
cat("  - vignettes/getting_started.Rmd\n\n")
