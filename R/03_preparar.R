ventas <- muestra
names(ventas) <- c("factura", "codigo", "descripcion_original", "cantidad", "fecha_original",
                   "precio_gbp", "cliente_original", "pais", "fila_excel")

# Mantengo los renglones sin cliente: sirven para estudiar importes y artículos.
# NA significa desconocido. No lo reemplazo por el cliente 0.
ventas$cliente_id <- ifelse(is.na(ventas$cliente_original), NA_character_,
                           sprintf("%.0f", ventas$cliente_original))
ventas$fecha_hora <- format(ventas$fecha_original, "%Y-%m-%d %H:%M:%S", tz = "UTC")
ventas$cancelacion <- as.integer(grepl("^C", ventas$factura))

# Trabajar en peniques evita acumular aproximaciones al sumar dinero en SQLite.
# El diagnóstico debe confirmar antes que no se pierde precisión al convertir.
stopifnot(all(is.finite(ventas$precio_gbp)), all(is.finite(ventas$cantidad)),
          all(abs(ventas$precio_gbp * 100 - round(ventas$precio_gbp * 100)) < 1e-6),
          all(ventas$cantidad == round(ventas$cantidad)), all(ventas$precio_gbp >= 0))
ventas$precio_peniques <- as.integer(round(ventas$precio_gbp * 100))
ventas$cantidad <- as.integer(ventas$cantidad)

# Limpio sólo los textos usados para elegir una etiqueta. La descripción recibida
# queda en cada línea. Un '?' tampoco alcanza para identificar un artículo.
ventas$descripcion_etiqueta <- trimws(ventas$descripcion_original)
ventas$descripcion_etiqueta[ventas$descripcion_etiqueta %in% c("", "?")] <- NA_character_

# Precio cero no demuestra una venta gratuita: también hay ajustes sin valorar.
# Los guardo en la base y los dejo fuera de los tres resultados de ventas.
ventas$analizable <- as.integer(ventas$precio_peniques > 0 & ventas$cantidad != 0)
stopifnot(all(ventas$cancelacion[ventas$analizable == 1] ==
                as.integer(ventas$cantidad[ventas$analizable == 1] < 0)))

# Cuatro dataframes construidos con valores observados, no catálogos inventados.
paises <- data.frame(pais = sort(unique(ventas$pais)))
paises$pais_id <- seq_len(nrow(paises))
paises <- paises[c("pais_id", "pais")]

facturas <- ventas %>% distinct(factura, cliente_id, pais, cancelacion) %>%
  left_join(paises, by = "pais") %>% select(factura, cliente_id, pais_id, cancelacion) %>%
  arrange(factura) %>% as.data.frame()
stopifnot(!anyDuplicated(facturas$factura))

# Un mismo código tiene a veces varias descripciones. Elijo la primera descripción
# válida con precio positivo; si no existe, la primera válida de cualquier línea.
# Es una etiqueta de referencia. No cambia las cantidades ni combina códigos.
articulos <- ventas %>% arrange(desc(precio_peniques > 0), fila_excel) %>%
  filter(!is.na(descripcion_etiqueta)) %>% distinct(codigo, .keep_all = TRUE) %>%
  select(codigo, descripcion = descripcion_etiqueta, fila_descripcion = fila_excel)
articulos <- data.frame(codigo = sort(unique(ventas$codigo))) %>%
  left_join(articulos, by = "codigo") %>% as.data.frame()

lineas <- ventas %>% select(fila_excel, factura, codigo, fecha_hora, cantidad,
                            precio_peniques, descripcion_original, analizable) %>%
  arrange(fila_excel) %>% as.data.frame()

# Cada conteo 'afectados' corresponde a renglones de la fuente, salvo donde la
# unidad dice explícitamente artículos. Las transformaciones no borran filas.
n <- nrow(muestra)
bitacora <- data.frame(
  regla = c("seleccion_periodo", "cliente_a_texto", "cliente_ausente", "fecha_iso",
            "precio_a_peniques", "descripcion_etiqueta", "etiqueta_por_codigo",
            "precio_cero_fuera_del_analisis", "repeticiones_conservadas"),
  campo = c("InvoiceDate", "CustomerID", "CustomerID", "InvoiceDate", "UnitPrice",
            "Description", "StockCode / Description", "UnitPrice / Quantity", "ocho campos originales"),
  condicion = c("2011-01-01 <= fecha < 2011-04-01", "cliente conocido", "cliente NA",
    "fecha-hora importada", "precio con hasta dos decimales",
    "espacios en bordes, vacío o ?", "código de artículo observado",
    "precio igual a cero o cantidad igual a cero", "idéntico a una fila anterior"),
  motivo = c("Tres meses completos y un tamaño manejable", "El ID es una etiqueta, no una magnitud",
    "No perder ventas por falta de cliente", "Guardar la hora de cada renglón",
    "Sumar dinero con enteros sin perder precisión", "No usar textos vacíos como nombre",
    "Un código puede tener varias descripciones", "Separar ajustes sin valorar de los resultados de ventas",
    "No hay ID de línea que demuestre un error"),
  accion = c("seleccionar", "convertir", "conservar como NULL", "convertir a texto ISO",
    "multiplicar por 100 y convertir a entero", "normalizar etiqueta, conservar texto original",
    "elegir primera etiqueta válida y guardar su fila de origen",
    "conservar en SQLite con analizable=0", "conservar y medir sensibilidad"),
  afectados = c(sum(!en_periodo), sum(!is.na(ventas$cliente_original)),
    sum(is.na(ventas$cliente_original)), n, n,
    sum((!is.na(ventas$descripcion_original) & is.na(ventas$descripcion_etiqueta)) |
          (!is.na(ventas$descripcion_etiqueta) &
             ventas$descripcion_original != ventas$descripcion_etiqueta), na.rm = TRUE),
    nrow(articulos), sum(ventas$analizable == 0), sum(repetidas)),
  unidad = c(rep("renglones", 6), "articulos", "renglones", "renglones"),
  filas_antes = c(nrow(ventas_original), rep(n, 8)),
  filas_despues = rep(n, 9)
)
print(bitacora)
write.csv(bitacora, file.path(raiz, "salidas", "bitacora_limpieza.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

comparacion <- data.frame(
  indicador = c("renglones de la selección", "clientes desconocidos", "renglones repetidos",
                "precios cero", "renglones incluidos en resultados", "descripciones con espacios en bordes (etiqueta)"),
  antes = c(n, sum(is.na(muestra$CustomerID)), sum(repetidas), sum(muestra$UnitPrice == 0),
            n, sum(muestra$Description != trimws(muestra$Description), na.rm = TRUE)),
  despues = c(nrow(lineas), sum(is.na(ventas$cliente_id)), sum(repetidas),
              sum(lineas$precio_peniques == 0), sum(lineas$analizable == 1), 0)
)
print(comparacion)
guardar_csv(comparacion, "antes_despues.csv")
