#' Otimização de Uso de Insumos (DMET e DMEE)
#'
#' Calcula a Dose de Máxima Eficiência Técnica (DMET) e a Dose de Máxima Eficiência
#' Econômica (DMEE) para modelos de regressão quadrática (Y = b0 + b1*X + b2*X^2).
#'
#' @param modelo_quadratico Objeto de resultado da função `ajustar_quadratico`.
#' @param preco_insumo Preço unitário do insumo (dose).
#' @param preco_produto Preço unitário do produto (resposta).
#' @param verbose Lógico. Gera prints detalhados (padrão: TRUE).
#'
#' @return Lista contendo um data frame com os resultados de otimização e uma lista de gráficos.
#'
#' @importFrom dplyr "%>%"
#' @importFrom ggplot2 ggplot aes geom_line geom_point geom_vline labs theme_minimal
#'
#' @export
otimizacao_insumos <- function(
  modelo_quadratico,
  preco_insumo,
  preco_produto,
  verbose = TRUE
) {
  # Evitar aviso de "no visible binding"
  resposta <- parametro <- valor <- dose <- Y <- NULL

  if (
    !is.list(modelo_quadratico) || !("resultados" %in% names(modelo_quadratico))
  ) {
    stop("O objeto fornecido não é um resultado válido da função de ajuste.")
  }

  if (preco_insumo <= 0 || preco_produto <= 0) {
    stop("Os preços do insumo e do produto devem ser maiores que zero.")
  }

  df_resultados <- modelo_quadratico$resultados
  nomes_respostas <- unique(df_resultados$resposta)
  
  # Tenta recuperar os dados originais se existirem no objeto
  dados_originais <- modelo_quadratico$dados_originais

  resultados_otimizacao <- list()
  lista_graficos <- list()

  for (resp in nomes_respostas) {
    # Extrai os coeficientes do modelo quadrático
    coefs_resp <- df_resultados %>%
      dplyr::filter(resposta == resp) %>%
      tidyr::pivot_wider(names_from = parametro, values_from = valor)

    # Verifica se o modelo é quadrático (b2 existe)
    if (!("b2_quadratico" %in% names(coefs_resp))) {
      warning(sprintf(
        "A resposta '%s' não tem os coeficientes quadráticos esperados. Otimização ignorada.",
        resp
      ))
      next
    }

    b0 <- coefs_resp$b0_intercepto
    b1 <- coefs_resp$b1_linear
    b2 <- coefs_resp$b2_quadratico

    # --- 1. Dose de Máxima Eficiência Técnica (DMET) ---
    relacao_precos <- preco_insumo / preco_produto

    if (b2 >= 0) {
      DMET <- NA
      Y_max <- NA
      aviso_dmet <- "Curva convexa (b2 >= 0). DMET não calculável."
    } else {
      DMET <- -b1 / (2 * b2)
      if (DMET < 0) {
        DMET <- 0
        Y_max <- b0
        aviso_dmet <- "DMET negativa. Máximo na dose 0."
      } else {
        Y_max <- b0 + b1 * DMET + b2 * DMET^2
        aviso_dmet <- "DMET calculada com sucesso."
      }
    }

    # --- 2. Dose de Máxima Eficiência Econômica (DMEE) ---
    if (b2 >= 0) {
      DMEE <- NA
      Y_DMEE <- NA
      aviso_dmee <- "Curva convexa (b2 >= 0). DMEE não calculável."
    } else {
      DMEE <- (b1 - relacao_precos) / (-2 * b2)
      if (DMEE < 0) {
        DMEE <- 0
        Y_DMEE <- b0
        aviso_dmee <- "DMEE negativa. Máximo econômico na dose 0."
      } else {
        Y_DMEE <- b0 + b1 * DMEE + b2 * DMEE^2
        aviso_dmee <- "DMEE calculada com sucesso."
      }
    }

    # Armazenamento dos resultados numéricos
    df_resp <- data.frame(
      resposta = resp,
      DMET = DMET,
      Y_max = Y_max,
      DMEE = DMEE,
      Y_DMEE = Y_DMEE,
      Relacao_Precos = relacao_precos,
      Aviso_DMET = aviso_dmet,
      Aviso_DMEE = aviso_dmee
    )
    resultados_otimizacao[[resp]] <- df_resp

    # --- Geração do Gráfico para esta resposta ---
    # Determinar o range de doses para o gráfico
    max_dose_data <- 0
    if (!is.null(dados_originais)) {
      max_dose_data <- max(dados_originais$dose, na.rm = TRUE)
    }
    
    max_dose_plot <- max(c(max_dose_data, DMET, DMEE), na.rm = TRUE) * 1.1
    if (is.na(max_dose_plot) || max_dose_plot == 0) max_dose_plot <- 100
    
    dose_range <- seq(0, max_dose_plot, length.out = 200)
    Y_curve <- b0 + b1 * dose_range + b2 * dose_range^2
    df_curva <- data.frame(dose = dose_range, Y = Y_curve)

    p <- ggplot2::ggplot() +
      ggplot2::geom_line(data = df_curva, ggplot2::aes(x = dose, y = Y), color = "blue", linewidth = 1)
    
    # Adicionar pontos originais se disponíveis
    if (!is.null(dados_originais)) {
      df_pontos <- dados_originais %>% dplyr::filter(resposta == resp)
      if (nrow(df_pontos) > 0) {
        p <- p + ggplot2::geom_point(data = df_pontos, ggplot2::aes(x = dose, y = Y), alpha = 0.5)
      }
    }

    # Adicionar pontos de otimização
    if (!is.na(DMET)) {
      p <- p + 
        ggplot2::geom_vline(xintercept = DMET, linetype = "dashed", color = "red", alpha = 0.5) +
        ggplot2::geom_point(ggplot2::aes(x = DMET, y = Y_max), color = "red", size = 4, shape = 17)
    }
    
    if (!is.na(DMEE)) {
      p <- p + 
        ggplot2::geom_vline(xintercept = DMEE, linetype = "dotted", color = "green", alpha = 0.5) +
        ggplot2::geom_point(ggplot2::aes(x = DMEE, y = Y_DMEE), color = "green", size = 4, shape = 15)
    }

    p <- p + 
      ggplot2::labs(
        title = paste("Otimização:", resp),
        subtitle = sprintf("Relação de Preços: %.4f", relacao_precos),
        x = "Dose", y = "Resposta (Y)",
        caption = "Triângulo Vermelho = DMET | Quadrado Verde = DMEE"
      ) +
      ggplot2::theme_minimal()
    
    lista_graficos[[resp]] <- p
  }

  df_final <- do.call(rbind, resultados_otimizacao)

  # Impressão Verbosa
  if (verbose) {
    cat("\n=== Otimização de Uso de Insumos (DMET e DMEE) ===\n")
    print(df_final[, 1:6])
    for (resp in names(lista_graficos)) {
      print(lista_graficos[[resp]])
    }
  }

  return(list(
    resultados = df_final,
    graficos = lista_graficos
  ))
}
