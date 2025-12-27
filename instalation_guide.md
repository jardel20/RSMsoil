# Guia de Instalação e Uso do Pacote RSMsoil

## Informações do Pacote

- **Nome**: RSMsoil
- **Versão**: 0.1.0
- **Título**: Response Surface Methodology for Soil Fertility Assessment
- **Descrição**: Implementação completa de análise de superfície de resposta seguindo a metodologia de Victor Hugo Alvarez V. (2008)
- **Licença**: MIT
- **Autor**: Manus AI

## Requisitos do Sistema

- **R**: versão 4.0 ou superior
- **Pacotes obrigatórios**:
  - dplyr
  - tidyr
  - purrr
  - tibble
  - ggplot2
  - plotly
  - Matrix
  - stats (incluído no R base)

## Instalação

### Opção 1: Instalação a partir do arquivo compactado

```r
# Instalar a partir do arquivo .tar.gz
install.packages("/caminho/para/RSMsoil_0.1.0.tar.gz", repos = NULL, type = "source")
```

### Opção 2: Instalação a partir do diretório

```r
# Instalar a partir do diretório do pacote
install.packages("/caminho/para/RSMsoil_pkg", repos = NULL, type = "source")
```

### Opção 3: Instalação usando devtools (desenvolvimento)

```r
# Instalar devtools se necessário
install.packages("devtools")

# Carregar o pacote em desenvolvimento
devtools::load_all("/caminho/para/RSMsoil_pkg")
```

## Verificação de Instalação

```r
# Carregar o pacote
library(RSMsoil)

# Verificar versão
packageVersion("RSMsoil")

# Listar funções disponíveis
ls("package:RSMsoil")

# Acessar ajuda
?RSMsoil
```

## Uso Rápido

### Exemplo Básico: Análise de Dados de Soja

```r
library(RSMsoil)
library(tibble)

# 1. Criar dados experimentais
data <- tibble(
  Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
  P = c(108, 108, 252, 252, 180, 18, 342, 108, 252),
  S = c(36, 84, 36, 84, 60, 36, 84, 6, 114)
)

# 2. Codificar variáveis para escala padronizada
levels_list <- list(
  P = c(low = 18, center = 180, high = 342),
  S = c(low = 6, center = 60, high = 114)
)

data_encoded <- encode_variables(
  data, 
  factor_names = c("P", "S"), 
  levels = levels_list
)

# 3. Ajustar modelo de 2ª ordem
model <- fit_second_order(
  data_encoded, 
  response = "Y", 
  factors = c("P_coded", "S_coded")
)

# 4. Visualizar resumo do modelo
summary(model)

# 5. Realizar ANOVA
anova_result <- anova_rsm(model, alpha = 0.10)
print(anova_result)

# 6. Análise canônica
canonical <- canonical_analysis(model)
print(canonical)

# 7. Visualizar superfície de resposta
plot_response_surface(model)

# 8. Encontrar ponto ótimo
optimal <- get_optimal_factors(model, objective = "maximize")
print(optimal$optimal_point)

# 9. Decodificar para escala natural
recommendations <- get_stationary_point(canonical)
print(recommendations)
```

## Funções Principais

### Codificação
- `encode_variables()` - Transformar para escala codificada
- `decode_variables()` - Transformar para escala natural

### Ajuste de Modelos
- `fit_first_order()` - Modelo linear (1ª ordem)
- `fit_first_order_interaction()` - Modelo linear com interações
- `fit_second_order()` - Modelo quadrático (2ª ordem)
- `fit_response_surface()` - Função genérica

### Análise Estatística
- `anova_rsm()` - ANOVA completa
- `canonical_analysis()` - Análise canônica
- `compare_models()` - Comparação de modelos

### Otimização
- `steepest_path()` - Caminho de máxima inclinação
- `get_optimal_factors()` - Busca por grid
- `get_stationary_point()` - Ponto estacionário

### Predição
- `predict_rsm()` - Predições em novos pontos

### Visualização
- `plot_response_surface()` - Contornos estáticos
- `plot_isoquants()` - Isoquantas
- `plot_interactive_surface()` - Superfície 3D interativa
- `plot_steepest_path()` - Caminho de inclinação

### Utilitários
- `plot_diagnostics()` - Gráficos de diagnóstico
- `generate_design()` - Gerar delineamentos experimentais
- `get_residuals()`, `get_fitted_values()` - Extrair componentes

## Estrutura de Dados

### Entrada (Dados Codificados)
```r
tibble(
  Y = numeric,           # Resposta
  X1_coded = numeric,    # Fator 1 (escala codificada)
  X2_coded = numeric,    # Fator 2 (escala codificada)
  ...
)
```

### Saída (Predições)
```r
tibble(
  X1_coded = numeric,
  X2_coded = numeric,
  predicted_response = numeric,
  se_fit = numeric,              # (opcional)
  ci_lower = numeric,            # (opcional)
  ci_upper = numeric             # (opcional)
)
```

## Exemplos Avançados

### Múltiplos Fatores (3+ fatores)

```r
# Dados com 3 fatores
data_3f <- tibble(
  Y = rnorm(20, mean = 10, sd = 1),
  X1 = rep(c(-1, 0, 1), length.out = 20),
  X2 = rep(c(-1, 1), 10),
  X3 = rep(c(-1, 0, 1), length.out = 20)
)

# Ajustar modelo
model_3f <- fit_second_order(
  data_3f, 
  response = "Y", 
  factors = c("X1", "X2", "X3")
)

# Visualizar pares de fatores
plot_response_surface(model_3f, factor1 = "X1", factor2 = "X2")
plot_response_surface(model_3f, factor1 = "X1", factor2 = "X3")

# Fixar um fator em valor específico
plot_response_surface(
  model_3f, 
  factor1 = "X1", 
  factor2 = "X2",
  fixed_values = list(X3 = 0.5)
)
```

### Comparação de Modelos

```r
# Ajustar modelos de diferentes ordens
model_1st <- fit_first_order(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))
model_2nd <- fit_second_order(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))

# Comparar modelos
comparison <- compare_models(model_1st, model_2nd)
print(comparison)
```

### Diagnóstico de Modelo

```r
# Obter gráficos de diagnóstico
diagnostics <- plot_diagnostics(model)

# Acessar gráficos individuais
diagnostics$residuals_vs_fitted
diagnostics$qq_plot
diagnostics$scale_location
diagnostics$residuals_vs_leverage
```

### Gerar Delineamento Experimental

```r
# CCD (Central Composite Design) com 2 fatores
design_ccd <- generate_design(
  n_factors = 2, 
  design = "ccd", 
  alpha = 1.68,      # Rotatable design
  n_center = 3
)

# Delineamento fatorial 2^k
design_factorial <- generate_design(
  n_factors = 3, 
  design = "factorial"
)
```

## Testes Unitários

```r
# Executar todos os testes
devtools::test()

# Ou usar testthat diretamente
testthat::test_dir("tests")
```

## Documentação

### Acessar Ajuda

```r
# Ajuda geral do pacote
?RSMsoil

# Ajuda de funções específicas
?encode_variables
?fit_second_order
?canonical_analysis
?plot_response_surface
```

### Vinheta

```r
# Visualizar vinheta completa
vignette("getting_started", package = "RSMsoil")
```

## Troubleshooting

### Erro: "Pacote não encontrado"

```r
# Verificar se o pacote está instalado
installed.packages()["RSMsoil",]

# Reinstalar se necessário
install.packages("RSMsoil_0.1.0.tar.gz", repos = NULL, type = "source")
```

### Erro: "Objeto não encontrado"

```r
# Verificar se o pacote foi carregado
library(RSMsoil)

# Verificar funções disponíveis
ls("package:RSMsoil")
```

### Erro: "Dimensões incompatíveis"

```r
# Verificar que os nomes de fatores correspondem aos dados
names(data_encoded)

# Usar nomes corretos nas funções
fit_second_order(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))
```

## Recursos Adicionais

- **README.md**: Documentação principal do pacote
- **TECHNICAL_SUMMARY.md**: Resumo técnico detalhado
- **vignettes/getting_started.Rmd**: Guia completo com exemplos
- **tests/testthat/**: Exemplos de uso em testes

## Suporte e Contribuições

Para reportar problemas ou sugerir melhorias, consulte a documentação do pacote ou entre em contato com os desenvolvedores.

## Referências

Alvarez V., V. H. (2008). **Avaliação da Fertilidade do Solo: Superfícies de Resposta - Modelos Aproximativos para Expressar a Relação Fator-Resposta**. Universidade Federal de Viçosa, Brazil.

Box, G. E. P., & Wilson, K. B. (1951). On the experimental attainment of optimum conditions. *Journal of the Royal Statistical Society*, 13, 1-45.

Myers, R. H., Montgomery, D. C., & Anderson-Cook, C. M. (2016). **Response Surface Methodology: Process and Product Optimization Using Designed Experiments** (3rd ed.). Wiley.

---

**Última atualização**: Dezembro de 2024  
**Versão**: 0.1.0
