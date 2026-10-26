# Diagnóstico de la selección antes de prepararla.
campos <- names(muestra)[1:8]
diagnostico <- data.frame(
  campo = campos,
  tipo = sapply(muestra[campos], function(x) paste(class(x), collapse = "/")),
  faltantes = sapply(muestra[campos], function(x) sum(is.na(x))),
  vacios = sapply(muestra[campos], function(x) {
    if (is.character(x)) sum(trimws(x) == "", na.rm = TRUE) else 0L
  }),
  codigo_interrogacion = sapply(muestra[campos], function(x) {
    if (is.character(x)) sum(trimws(x) == "?", na.rm = TRUE) else 0L
  }),
  distintos_sin_na = sapply(muestra[campos], function(x) length(unique(x[!is.na(x)])))
)
diagnostico$porcentaje_na <- round(100 * diagnostico$faltantes / nrow(muestra), 2)
diagnostico$porcentaje_vacios <- round(100 * diagnostico$vacios / nrow(muestra), 2)
diagnostico$porcentaje_interrogacion <- round(100 * diagnostico$codigo_interrogacion / nrow(muestra), 2)
print(diagnostico)
guardar_csv(diagnostico, "diagnostico_inicial.csv")
print(summary(muestra[c("Quantity", "UnitPrice", "InvoiceDate")]))
print(sort(table(muestra$Country), decreasing = TRUE))

repetidas <- duplicated(muestra[campos])
cat("Renglones idénticos a otro anterior:", sum(repetidas), "\n")
guardar_csv(muestra[repetidas, ], "repeticiones_para_revisar.csv")

control_facturas <- muestra %>% group_by(InvoiceNo) %>% summarise(
  horas_distintas = n_distinct(InvoiceDate), clientes_distintos = n_distinct(CustomerID),
  paises_distintos = n_distinct(Country), .groups = "drop")
print(control_facturas %>% filter(horas_distintas > 1))
guardar_csv(control_facturas, "diagnostico_facturas.csv")
stopifnot(all(control_facturas$clientes_distintos == 1),
          all(control_facturas$paises_distintos == 1))

variantes <- muestra %>% group_by(StockCode) %>% summarise(
  descripciones = n_distinct(Description, na.rm = TRUE), .groups = "drop")
cat("Códigos con más de una descripción:", sum(variantes$descripciones > 1), "\n")
guardar_csv(variantes, "variantes_descripcion.csv")

problemas <- data.frame(
  indicador = c("precio_cero", "precio_negativo", "cantidad_cero", "cantidad_negativa",
                "negativa_sin_C_y_con_precio", "C_con_cantidad_no_negativa",
                "precio_con_mas_de_dos_decimales", "facturas_con_distintas_horas",
                "renglones_repetidos", "descripcion_con_espacios_en_bordes"),
  cantidad = c(sum(muestra$UnitPrice == 0), sum(muestra$UnitPrice < 0),
    sum(muestra$Quantity == 0), sum(muestra$Quantity < 0),
    sum(muestra$Quantity < 0 & !grepl("^C", muestra$InvoiceNo) & muestra$UnitPrice > 0),
    sum(grepl("^C", muestra$InvoiceNo) & muestra$Quantity >= 0),
    sum(abs(muestra$UnitPrice * 100 - round(muestra$UnitPrice * 100)) > 1e-6),
    sum(control_facturas$horas_distintas > 1), sum(repetidas),
    sum(muestra$Description != trimws(muestra$Description), na.rm = TRUE))
)
print(problemas)
guardar_csv(problemas, "problemas_iniciales.csv")
print(muestra[abs(muestra$Quantity) > 10000, ])
