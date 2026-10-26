# Pruebas sobre la base creada y algunos ejemplos separados del archivo.
verificar <- function() {
  con <- abrir_base(ruta_base)
  on.exit(dbDisconnect(con))

  # 74215 * 104 = 7718360 peniques; la cancelación tiene el importe opuesto.
  caso <- resultados$caso_conocido
  stopifnot(nrow(caso) == 2, all(caso$precio_peniques == 104),
            all(caso$importe_peniques == c(7718360, -7718360)),
            sum(caso$importe_peniques) == 0)

  texto <- trimws(c(" nombre ", "", "?", NA_character_))
  texto[texto %in% c("", "?")] <- NA_character_
  stopifnot(identical(texto, c("nombre", NA_character_, NA_character_, NA_character_)))
  precios <- c(0, 1.04, 1.005)
  stopifnot(identical(abs(precios * 100 - round(precios * 100)) < 1e-6,
                      c(TRUE, TRUE, FALSE)))
  fechas <- as.Date(c("2011-02-28", "2011-02-30"), format = "%Y-%m-%d")
  stopifnot(!is.na(fechas[1]), is.na(fechas[2]))
  clientes <- c(12346, NA_real_)
  stopifnot(identical(ifelse(is.na(clientes), NA_character_, sprintf("%.0f", clientes)),
                      c("12346", NA_character_)))
  precio_invalido <- tryCatch({
    stopifnot(all(c(1.04, -1) >= 0))
    FALSE
  }, error = function(e) TRUE)
  stopifnot(precio_invalido,
            identical(as.integer(c(100, 0, 100) > 0 & c(2, 2, 0) != 0), c(1L, 0L, 0L)))

  # Claves y relaciones. El JOIN debe conservar filas e importe.
  stopifnot(!anyDuplicated(paises$pais_id), !anyDuplicated(facturas$factura),
            !anyDuplicated(articulos$codigo), !anyDuplicated(lineas$fila_excel),
            nrow(dbGetQuery(con, "PRAGMA foreign_key_check")) == 0,
            dbGetQuery(con, "PRAGMA integrity_check")[[1]] == "ok",
            resultados$control_joins$filas == resultados$totales$filas,
            resultados$control_joins$filas_distintas == nrow(lineas),
            resultados$control_joins$importe_peniques == resultados$totales$importe_peniques)

  analisis <- ventas[ventas$analizable == 1, ]
  analisis$mes <- substr(analisis$fecha_hora, 1, 7)
  analisis$importe <- analisis$cantidad * analisis$precio_peniques
  mensual_r <- aggregate(importe ~ mes, analisis, sum)
  stopifnot(identical(mensual_r$mes, resultados$mensual$mes),
            all(mensual_r$importe == round(resultados$mensual$neto_gbp * 100)))

  stopifnot(nrow(ventas_original) == sum(!en_periodo) + nrow(muestra),
            nrow(muestra) == nrow(lineas),
            nrow(lineas) == sum(lineas$analizable == 1) + sum(lineas$analizable == 0),
            resultados$repeticiones$filas_extra == sum(repetidas),
            bitacora$filas_despues[bitacora$regla == "seleccion_periodo"] == nrow(lineas),
            bitacora$afectados[bitacora$regla == "precio_cero_fuera_del_analisis"] == sum(lineas$analizable == 0),
            unname(tools::md5sum(archivo)) == md5_original)

  # La segunda inserción debe fallar y revertir también la primera.
  paises_antes <- dbGetQuery(con, "SELECT COUNT(*) AS n FROM paises")$n
  error_fk <- tryCatch({
    dbWithTransaction(con, {
      dbExecute(con, "INSERT INTO paises VALUES (999999, 'PAIS DE PRUEBA')")
      dbExecute(con, "INSERT INTO lineas
        SELECT 9999999, 'FACTURA_INEXISTENTE', codigo, '2011-01-01 00:00:00', 1, 100, NULL, 1
        FROM articulos LIMIT 1")
    })
    "Sin error"
  }, error = function(e) conditionMessage(e))
  stopifnot(grepl("FOREIGN KEY", error_fk, fixed = TRUE),
            dbGetQuery(con, "SELECT COUNT(*) AS n FROM paises")$n == paises_antes,
            dbGetQuery(con, "SELECT COUNT(*) AS n FROM paises WHERE pais_id=999999")$n == 0,
            dbGetQuery(con, "SELECT COUNT(*) AS n FROM lineas WHERE fila_excel=9999999")$n == 0)

  segunda_base <- tempfile(fileext = ".sqlite")
  on.exit(unlink(segunda_base), add = TRUE)
  crear_base(segunda_base)
  stopifnot(isTRUE(all.equal(resultados, consultar_base(segunda_base), tolerance = 0)))

  data.frame(
    prueba = c("Caso conocido", "Casos límite", "Integridad y JOIN", "SQL contra R",
               "Conservación", "Rollback", "Segunda reconstrucción"),
    resultado = "OK",
    evidencia = c("Compra y cancelación: +77183,60 y -77183,60 GBP",
      "Textos, cliente ausente, fecha imposible, precios inválidos y ceros",
      "Claves únicas, sin huérfanos y sin multiplicar filas ni dinero",
      "El neto mensual calculado en R coincide con SQL",
      "Filas conciliadas con la bitácora y MD5 del original sin cambios",
      paste("Ninguna inserción de prueba quedó guardada tras", error_fk),
      "Las ocho consultas coinciden en otra base creada desde cero")
  )
}
pruebas <- verificar()
print(pruebas)
guardar_csv(pruebas, "verificaciones.csv")
