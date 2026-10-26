theme_set(theme_minimal(base_size = 16) + theme(plot.margin = margin(10, 35, 10, 10)))
numero <- function(x, decimales = 0) {
  formatC(x, format = "f", digits = decimales, big.mark = ".", decimal.mark = ",")
}

# Los tres gráficos parten de dataframes obtenidos con dbGetQuery, no del Excel.
mensual <- resultados$mensual
mensual_grafico <- rbind(
  data.frame(mes = mensual$mes, tipo = "Ventas", importe = mensual$ventas_gbp),
  data.frame(mes = mensual$mes, tipo = "Cancelaciones", importe = mensual$cancelaciones_gbp),
  data.frame(mes = mensual$mes, tipo = "Neto", importe = mensual$neto_gbp)
)
mensual_grafico$tipo <- factor(mensual_grafico$tipo, levels = c("Ventas", "Cancelaciones", "Neto"))
g1 <- ggplot(mensual_grafico, aes(mes, importe, fill = tipo)) +
  geom_col(position = "dodge", width = 0.75) +
  scale_fill_manual(values = c("Ventas" = "#397CA5", "Cancelaciones" = "#CB7651", "Neto" = "#31755B")) +
  scale_y_continuous(labels = numero, expand = expansion(mult = c(0, 0.06))) +
  labs(title = "Ventas y cancelaciones en los tres meses",
    subtitle = "Enero a marzo de 2011\nLas cancelaciones se muestran como importe positivo",
    x = "Mes", y = "Importe registrado (GBP)", fill = NULL,
    caption = "Neto = ventas menos cancelaciones. Líneas con precio positivo.\nFuente: UCI Online Retail.") +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"))
print(g1)
ggsave(file.path(resultados_dir, "grafico_1_meses.png"), g1, width = 10, height = 5.6, dpi = 160)

principales_paises <- head(resultados$paises, 8)
g2 <- ggplot(principales_paises, aes(reorder(pais, neto_gbp), neto_gbp)) +
  geom_col(fill = "#397CA5", width = 0.65) +
  geom_text(aes(label = paste0(numero(porcentaje_neto, 1), "%")), hjust = -0.15, size = 3.8) +
  coord_flip() +
  scale_y_continuous(labels = numero, expand = expansion(mult = c(0, 0.15))) +
  labs(title = "El importe neto se concentra en pocos países",
    subtitle = "Ocho países con mayor importe neto\nLos porcentajes usan el total de todos los países",
    x = NULL, y = "Importe neto registrado (GBP)",
    caption = "País del cliente informado en la factura. Incluye clientes sin ID.\nFuente: UCI Online Retail.") +
  theme(plot.title = element_text(face = "bold"))
print(g2)
ggsave(file.path(resultados_dir, "grafico_2_paises.png"), g2, width = 10, height = 5.6, dpi = 160)

principales_articulos <- head(resultados$articulos, 8)
principales_articulos$etiqueta <- paste(principales_articulos$codigo, principales_articulos$descripcion, sep = " - ")
g3 <- ggplot(principales_articulos, aes(reorder(etiqueta, unidades_netas), unidades_netas)) +
  geom_col(fill = "#31755B", width = 0.65) +
  geom_text(aes(label = numero(unidades_netas)), hjust = -0.1, size = 3.6) +
  coord_flip() +
  scale_y_continuous(labels = numero, expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Artículos con más unidades netas registradas",
    subtitle = "Ocho primeros códigos\nUnidades netas = positivas menos canceladas",
    x = NULL, y = "Unidades netas del artículo",
    caption = "Sólo líneas con precio positivo. Las unidades no miden ganancia.\nFuente: UCI Online Retail.") +
  theme(plot.title = element_text(face = "bold"), axis.text.y = element_text(size = 12))
print(g3)
ggsave(file.path(resultados_dir, "grafico_3_articulos.png"), g3, width = 12, height = 5.6, dpi = 160)

mejor_mes <- mensual$mes[which.max(mensual$neto_gbp)]
peor_mes <- mensual$mes[which.min(mensual$neto_gbp)]
participacion_uk <- resultados$paises$porcentaje_neto[resultados$paises$pais == "United Kingdom"]
hallazgos <- c(
  paste0("La selección tiene ", numero(nrow(lineas)), " renglones; ",
         numero(sum(lineas$analizable == 1)), " tienen precio positivo y entran en los resultados."),
  paste0("El mayor neto mensual corresponde a ", mejor_mes, " y el menor a ", peor_mes,
         ". Comparo tres meses completos; esto no prueba una tendencia anual."),
  paste0("United Kingdom concentra el ", numero(participacion_uk, 1),
         "% del neto total del trimestre. Describe esta tienda británica, no el mercado de cada país."),
  paste0("El código ", principales_articulos$codigo[1], " encabeza las unidades netas con ",
         numero(principales_articulos$unidades_netas[1]), ". Cantidad vendida no equivale a rentabilidad."),
  paste0("Si se conservara sólo la primera fila de cada repetición exacta, el neto cambiaría en ",
         numero(-resultados$repeticiones$diferencia_gbp, 2),
         " GBP. Mantengo las filas porque no puedo demostrar que sean errores."),
  "Las cancelaciones pueden corresponder a operaciones de otros períodos. No calculo una tasa de devolución por compra.",
  "Los importes son cantidad por precio registrado. Faltan costos, impuestos y detalle contable para hablar de ganancias.",
  "Algunos códigos son cargos o ajustes. El ranking describe los códigos del archivo; no demuestra demanda futura."
)
cat(paste(hallazgos, collapse = "\n\n"), "\n")
writeLines(hallazgos, file.path(raiz, "salidas", "hallazgos.txt"), useBytes = TRUE)
capture.output(sessionInfo(), file = file.path(raiz, "salidas", "sessionInfo.txt"))
versiones <- data.frame(paquete = paquetes,
  version = sapply(paquetes, function(x) as.character(packageVersion(x))))
guardar_csv(versiones, "versiones_paquetes.csv")
stopifnot(unname(tools::md5sum(archivo)) == md5_original)
cat("Proceso completo. El original sigue intacto y las conexiones quedaron cerradas.\n")
