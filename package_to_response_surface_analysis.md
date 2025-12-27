# RSMsoil: Pacote R para Análise de Superfície de Resposta

## Resumo Executivo

O pacote **RSMsoil** implementa uma metodologia completa e rigorosa de análise de superfície de resposta (RSM - Response Surface Methodology) em R, seguindo precisamente os Capítulos 1 e 4 do livro "Avaliação da Fertilidade do Solo: Superfícies de Resposta" de Victor Hugo Alvarez V. (2008).

O pacote foi desenvolvido como um conjunto modular de funções documentadas com roxygen2, seguindo as melhores práticas de desenvolvimento de pacotes R. Todas as funções são compatíveis com o tidyverse e retornam objetos `tibble` para facilitar análises subsequentes.

## Estrutura do Pacote

```
RSMsoil_pkg/
├── R/                          # Funções principais
│   ├── encoding.R              # Codificação/decodificação de variáveis
│   ├── model_fitting.R         # Ajuste de modelos (1ª e 2ª ordem)
│   ├── anova_analysis.R        # Análise de variância e testes estatísticos
│   ├── canonical_analysis.R    # Análise canônica e caracterização de pontos estacionários
│   ├── steepest_path.R         # Caminho de máxima inclinação/descida
│   ├── prediction.R            # Predição e otimização
│   ├── visualization.R         # Visualização (ggplot2 e plotly)
│   ├── utils.R                 # Funções utilitárias
│   └── RSMsoil-package.R       # Documentação do pacote
├── tests/
│   ├── testthat.R              # Configuração de testes
│   └── testthat/               # Testes unitários
│       ├── test_encoding.R
│       ├── test_model_fitting.R
│       └── test_canonical_analysis.R
├── data-raw/
│   └── soy_fertility.R         # Dados de exemplo (Quadro 6 do livro)
├── vignettes/
│   └── getting_started.Rmd     # Vinheta com guia completo de uso
├── DESCRIPTION                 # Metadados do pacote
├── NAMESPACE                   # Exportações e importações
├── README.md                   # Documentação principal
├── LICENSE                     # Licença MIT
└── .gitignore                  # Configuração Git
```

## Funções Implementadas

### 1. Codificação de Variáveis (encoding.R)

**`encode_variables(data, factor_names, levels = NULL)`**
- Transforma variáveis da escala natural para escala codificada (-1, 0, +1)
- Suporta detecção automática de níveis ou especificação manual
- Armazena níveis como atributo para decodificação posterior
- Retorna tibble com colunas originais + colunas codificadas com sufixo "_coded"

**`decode_variables(data, factor_names, levels = NULL)`**
- Transforma variáveis codificadas de volta para escala natural
- Operação inversa de `encode_variables()`
- Retorna tibble com colunas originais + colunas decodificadas com sufixo "_natural"

### 2. Ajuste de Modelos (model_fitting.R)

**`fit_first_order(data, response, factors)`**
- Ajusta modelo de 1ª ordem (linear): $Y = \beta_0 + \sum \beta_i X_i + \epsilon$
- Retorna objeto S3 de classe "rsm_model"
- Inclui coeficientes, ANOVA, R², R² ajustado e erro padrão residual

**`fit_first_order_interaction(data, response, factors)`**
- Ajusta modelo de 1ª ordem com termos de interação
- Inclui todos os termos de interação de dois fatores
- Modelo: $Y = \beta_0 + \sum \beta_i X_i + \sum_{i<j} \beta_{ij} X_i X_j + \epsilon$

**`fit_second_order(data, response, factors)`**
- Ajusta modelo completo de 2ª ordem (quadrático)
- Inclui termos lineares, quadráticos e de interação
- Modelo: $Y = \beta_0 + \sum \beta_i X_i + \sum \beta_{ii} X_i^2 + \sum_{i<j} \beta_{ij} X_i X_j + \epsilon$

**`fit_response_surface(data, response, factors, order = 2, include_interaction = FALSE)`**
- Função genérica que seleciona automaticamente o modelo apropriado
- Parâmetro `order` controla a ordem (1 ou 2)
- Parâmetro `include_interaction` adiciona termos de interação para modelos de 1ª ordem

### 3. Análise de Variância (anova_analysis.R)

**`anova_rsm(rsm_model, alpha = 0.05)`**
- Realiza ANOVA completa incluindo:
  - Tabela ANOVA com somas de quadrados, graus de liberdade e F-estatísticos
  - Teste F para significância global do modelo
  - Testes t para coeficientes individuais
  - Intervalos de confiança para coeficientes
  - Identificação de termos significativos ao nível α
- Retorna objeto S3 de classe "anova_rsm"
- Inclui R² e R² ajustado

### 4. Análise Canônica (canonical_analysis.R)

**`canonical_analysis(rsm_model)`**
- Realiza análise canônica completa (requer modelo de 2ª ordem)
- Calcula ponto estacionário resolvendo: $\mathbf{b} + 2\mathbf{B}\mathbf{x}_s = 0$
- Computa matriz Hessiana: $\mathbf{H} = 2\mathbf{B}$
- Realiza decomposição em autovalores/autovetores
- Classifica superfície como:
  - **Máximo**: todos os autovalores negativos
  - **Mínimo**: todos os autovalores positivos
  - **Ponto de sela**: autovalores com sinais mistos
- Retorna ponto estacionário em escala codificada e natural (se disponível)
- Retorna objeto S3 de classe "canonical_analysis"

### 5. Caminho de Máxima Inclinação (steepest_path.R)

**`steepest_path(rsm_model, start_point = NULL, direction = "ascent", n_steps = 10, step_size = 0.1)`**
- Calcula caminho de máxima inclinação (ascensão) ou descida
- Gradiente: $\nabla Y = \mathbf{b} + 2\mathbf{B}\mathbf{X}$
- Normaliza gradiente para obter direção unitária
- Gera sequência de pontos ao longo do caminho
- Prediz resposta em cada ponto
- Retorna objeto S3 de classe "steepest_path"
- Útil para exploração inicial do espaço experimental

### 6. Predição e Otimização (prediction.R)

**`predict_rsm(rsm_model, new_data = NULL, se_fit = FALSE)`**
- Realiza predições em novos pontos
- Opcionalmente retorna erros padrão e intervalos de confiança (95%)
- Retorna tibble com predições e intervalos

**`get_stationary_point(canonical_result, include_natural = TRUE)`**
- Extrai ponto estacionário da análise canônica
- Retorna tibble com coordenadas codificadas e naturais
- Inclui resposta predita e classificação da superfície

**`get_optimal_factors(rsm_model, objective = "maximize", bounds = NULL, n_grid = 20)`**
- Busca por grid para encontrar fatores ótimos
- Suporta maximização ou minimização
- Permite especificar limites para busca
- Retorna ponto ótimo e resposta predita
- Retorna objeto S3 de classe "optimization_result"

### 7. Visualização (visualization.R)

**`plot_response_surface(rsm_model, factor1 = NULL, factor2 = NULL, fixed_values = NULL, n_grid = 50, show_stationary = TRUE, show_optimal = FALSE)`**
- Cria gráfico estático de contornos da superfície de resposta
- Usa ggplot2 com preenchimento de cores (escala viridis)
- Opcionalmente marca ponto estacionário
- Retorna objeto ggplot2

**`plot_isoquants(rsm_model, factor1 = NULL, factor2 = NULL, fixed_values = NULL, n_grid = 100, n_levels = 10)`**
- Cria gráfico de isoquantas (linhas de resposta constante)
- Visualização detalhada com múltiplos níveis de contorno
- Retorna objeto ggplot2

**`plot_interactive_surface(rsm_model, factor1 = NULL, factor2 = NULL, fixed_values = NULL, n_grid = 30)`**
- Cria superfície 3D interativa com plotly
- Permite rotação, zoom e exploração dinâmica
- Retorna objeto plotly

**`plot_steepest_path(steepest_path_obj, rsm_model, factor1 = NULL, factor2 = NULL)`**
- Visualiza caminho de máxima inclinação sobre contornos
- Sobrepõe caminho em vermelho com seta indicando direção
- Retorna objeto ggplot2

### 8. Funções Utilitárias (utils.R)

**`get_design_matrix(rsm_model)`** - Extrai matriz de delineamento X
**`get_residuals(rsm_model)`** - Extrai resíduos do modelo
**`get_fitted_values(rsm_model)`** - Extrai valores ajustados
**`plot_diagnostics(rsm_model)`** - Cria 4 gráficos de diagnóstico (resíduos vs ajustados, Q-Q, escala-localização, resíduos vs alavancagem)
**`compare_models(model1, model2)`** - Compara modelos aninhados com teste F
**`generate_design(n_factors, design = "ccd", alpha = 1.68, n_center = 3)`** - Gera delineamentos experimentais (CCD ou fatorial)

## Metodologia Implementada

### Fluxo de Análise Completo

1. **Preparação de Dados**
   - Codificação de variáveis para escala padronizada
   - Armazenamento de níveis para decodificação posterior

2. **Seleção e Ajuste de Modelo**
   - Escolha entre modelos de 1ª ou 2ª ordem
   - Ajuste por mínimos quadrados ordinários (OLS)

3. **Análise Estatística**
   - ANOVA completa com testes de significância
   - Testes t para coeficientes individuais
   - Cálculo de intervalos de confiança

4. **Caracterização da Superfície** (para modelos de 2ª ordem)
   - Análise canônica
   - Identificação do ponto estacionário
   - Classificação do tipo de superfície

5. **Otimização**
   - Caminho de máxima inclinação para exploração
   - Busca por grid para otimização local
   - Decodificação para escala natural

6. **Visualização e Validação**
   - Gráficos de superfície e isoquantas
   - Gráficos de diagnóstico para validação de pressupostos
   - Análise de resíduos

## Características Principais

### Flexibilidade
- Suporta **qualquer número de fatores** (≥ 2)
- Seleção automática de pares de fatores para visualização
- Fixação de fatores adicionais em valores específicos

### Compatibilidade com Tidyverse
- Todas as funções retornam objetos `tibble`
- Integração com pipes (`%>%`)
- Uso de `dplyr`, `tidyr` e `purrr` internamente

### Documentação Completa
- Documentação roxygen2 para todas as funções
- Vinheta com exemplo completo de uso
- Exemplos em cada função
- README com guia rápido

### Testes Unitários
- Testes com `testthat` para funções principais
- Validação de entrada e saída
- Testes de casos extremos

### Modularidade
- Cada arquivo R contém funções relacionadas
- Separação clara de responsabilidades
- Fácil manutenção e extensão

## Dados de Exemplo

O pacote inclui dados do Quadro 6 do livro de Alvarez V. (2008):
- **Experimento**: Massa de matéria seca da parte aérea de plantas de soja
- **Fatores**: Fósforo (P) e Enxofre (S)
- **Níveis**: 
  - P: 18, 108, 180, 252, 342 mg/dm³
  - S: 6, 36, 60, 84, 114 mg/dm³
- **Resposta**: Massa seca (g/vaso)

## Requisitos e Dependências

### Dependências Obrigatórias
- `dplyr` - Manipulação de dados
- `tidyr` - Reorganização de dados
- `purrr` - Programação funcional
- `tibble` - Data frames modernos
- `ggplot2` - Visualização estática
- `plotly` - Visualização interativa
- `Matrix` - Operações matriciais
- `stats` - Funções estatísticas base

### Dependências de Desenvolvimento
- `testthat` - Framework de testes
- `roxygen2` - Documentação
- `knitr` - Processamento de vinhetas
- `rmarkdown` - Documentos dinâmicos

## Exemplo de Uso Completo

```r
library(RSMsoil)
library(tibble)

# 1. Criar dados
data <- tibble(
  Y = c(6.66, 6.30, 6.32, 5.92, 6.09, 6.22, 5.29, 6.67, 5.67),
  P = c(108, 108, 252, 252, 180, 18, 342, 108, 252),
  S = c(36, 84, 36, 84, 60, 36, 84, 6, 114)
)

# 2. Codificar variáveis
levels_list <- list(
  P = c(low = 18, center = 180, high = 342),
  S = c(low = 6, center = 60, high = 114)
)
data_encoded <- encode_variables(data, factor_names = c("P", "S"), levels = levels_list)

# 3. Ajustar modelo de 2ª ordem
model <- fit_second_order(data_encoded, response = "Y", factors = c("P_coded", "S_coded"))

# 4. ANOVA
anova_result <- anova_rsm(model, alpha = 0.10)
print(anova_result)

# 5. Análise canônica
canonical <- canonical_analysis(model)
print(canonical)

# 6. Visualizar
plot_response_surface(model)
plot_interactive_surface(model)

# 7. Otimizar
path <- steepest_path(model)
optimal <- get_optimal_factors(model, objective = "maximize")

# 8. Decodificar para escala natural
recommendations <- get_stationary_point(canonical)
print(recommendations)
```

## Validação e Testes

O pacote inclui testes unitários para:
- Codificação/decodificação de variáveis
- Ajuste de modelos (1ª e 2ª ordem)
- Análise canônica
- Predição e otimização

Todos os testes podem ser executados com:
```r
devtools::test()
# ou
testthat::test_dir("tests")
```

## Licença

MIT License - Uso livre em projetos acadêmicos e comerciais

## Referências

Alvarez V., V. H. (2008). **Avaliação da Fertilidade do Solo: Superfícies de Resposta - Modelos Aproximativos para Expressar a Relação Fator-Resposta**. Universidade Federal de Viçosa, Brazil.

Box, G. E. P., & Wilson, K. B. (1951). On the experimental attainment of optimum conditions. *Journal of the Royal Statistical Society*, 13, 1-45.

Myers, R. H., Montgomery, D. C., & Anderson-Cook, C. M. (2016). **Response Surface Methodology: Process and Product Optimization Using Designed Experiments** (3rd ed.). Wiley.

## Próximos Passos para Desenvolvimento

1. **Testes adicionais**: Expandir cobertura de testes para todas as funções
2. **Documentação roxygen2**: Gerar arquivos .Rd automaticamente
3. **Dados adicionais**: Incluir mais exemplos do livro de Alvarez V.
4. **Vinhetas extras**: Criar vinhetas para casos específicos (3+ fatores, delineamentos especiais)
5. **Otimizações**: Implementar algoritmos mais eficientes para busca de ótimos
6. **Extensões**: Adicionar suporte para modelos com restrições, superfícies desejabilidade múltipla

---

**Desenvolvido por**: Manus AI  
**Data**: Dezembro de 2024  
**Versão**: 0.1.0  
**Status**: Pronto para uso e desenvolvimento
