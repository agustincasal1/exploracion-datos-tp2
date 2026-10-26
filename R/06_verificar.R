# Las pruebas sintéticas usan otros objetos o se revierten por completo.
# No agrego errores a los datos analíticos para después decir que los limpié.
pruebas <- data.frame(prueba = character(), resultado = character(), evidencia = character())
registrar_prueba <- function(nombre, evidencia) {
  cat(nombre, ": OK. ", evidencia, "\n", sep = "")
  data.frame(prueba = nombre, resultado = "OK", evidencia = evidencia)
}

# Caso calculado a mano: 74.215 * 104 = 7.718.360 peniques.
# La cancelación es -74.215 * 104 y entre las dos suman cero.
caso <- resultados$caso_conocido
stopifnot(nrow(caso) == 2,
          identical(as.numeric(caso$cantidad), c(74215, -74215)),
          all(caso$precio_peniques == 104),
          all(caso$importe_peniques == c(7718360, -7718360)),
          sum(caso$importe_peniques) == 0)
pruebas <- rbind(pruebas, registrar_prueba("Caso conocido", "Excel filas 61621 y 61626: importes +77183,60 y -77183,60 GBP"))

# Pruebas de las transformaciones con datos separados, incluidos sus límites.
texto_prueba <- c(" nombre ", "", "?", NA_character_)
texto_prueba <- trimws(texto_prueba)
texto_prueba[texto_prueba %in% c("", "?")] <- NA_character_
stopifnot(identical(texto_prueba, c("nombre", NA_character_, NA_character_, NA_character_)))
precio_prueba <- c(0, 1.04, 1.005)
convertible <- abs(precio_prueba * 100 - round(precio_prueba * 100)) < 1e-6
stopifnot(identical(convertible, c(TRUE, TRUE, FALSE)))
fecha_prueba <- as.Date(c("2011-02-28", "2011-02-30"), format = "%Y-%m-%d")
stopifnot(!is.na(fecha_prueba[1]), is.na(fecha_prueba[2]))
cliente_prueba <- c(12346, NA_real_)
stopifnot(identical(ifelse(is.na(cliente_prueba), NA_character_,
                         sprintf("%.0f", cliente_prueba)), c("12346", NA_character_)))
precio_no_negativo <- tryCatch({stopifnot(all(c(1.04, -1) >= 0)); FALSE}, error = function(e) TRUE)
stopifnot(precio_no_negativo)
stopifnot(identical(as.integer(c(100, 0, 100) > 0 & c(2, 2, 0) != 0), c(1L, 0L, 0L)))
pruebas <- rbind(pruebas, registrar_prueba("Casos límite separados", "Espacios, interrogación, NA, fecha imposible, precio negativo o con tres decimales, precio y cantidad cero"))

verificar_integridad <- function(ruta) {
  conexion <- abrir_base(ruta)
  on.exit(dbDisconnect(conexion))
  stopifnot(nrow(dbGetQuery(conexion, "PRAGMA foreign_key_check")) == 0,
            dbGetQuery(conexion, "PRAGMA integrity_check")[[1]] == "ok")
  claves <- c(paises = "pais_id", facturas = "factura", articulos = "codigo", lineas = "fila_excel")
  for (tabla in names(claves)) {
    control <- dbGetQuery(conexion, paste0("SELECT COUNT(*) AS n, COUNT(DISTINCT ",
      claves[[tabla]], ") AS distintos FROM ", tabla))
    stopifnot(control$n == control$distintos)
  }
  invisible(TRUE)
}
verificar_integridad(ruta_base)
stopifnot(resultados$control_joins$filas == resultados$totales$filas,
          resultados$control_joins$filas_distintas == nrow(lineas),
          resultados$control_joins$importe_peniques == resultados$totales$importe_peniques)
pruebas <- rbind(pruebas, registrar_prueba("Integridad y JOIN", "Claves únicas, foreign_key_check sin huérfanos, filas e importes sin multiplicación"))

# Comparación independiente de los tres resultados SQL contra R.
analisis_r <- ventas[ventas$analizable == 1, ]
analisis_r$importe <- analisis_r$cantidad * analisis_r$precio_peniques
r_mensual <- aggregate(importe ~ mes, transform(analisis_r, mes = substr(fecha_hora, 1, 7)), sum)
r_paises <- aggregate(importe ~ pais, analisis_r, sum)
r_articulos <- aggregate(cantidad ~ codigo, analisis_r, sum)
stopifnot(all(r_mensual$importe == round(resultados$mensual$neto_gbp[match(r_mensual$mes, resultados$mensual$mes)] * 100)),
          all(r_paises$importe == round(resultados$paises$neto_gbp[match(r_paises$pais, resultados$paises$pais)] * 100)),
          all(r_articulos$cantidad == resultados$articulos$unidades_netas[match(r_articulos$codigo, resultados$articulos$codigo)]))
pruebas <- rbind(pruebas, registrar_prueba("SQL contra R", "Importes por mes y país, y cantidades por artículo coinciden"))

stopifnot(nrow(ventas_original) == sum(!en_periodo) + nrow(muestra),
          nrow(muestra) == nrow(lineas),
          nrow(lineas) == sum(lineas$analizable == 1) + sum(lineas$analizable == 0),
          resultados$repeticiones$filas_extra == sum(repetidas),
          bitacora$filas_despues[bitacora$regla == "seleccion_periodo"] == nrow(lineas),
          bitacora$afectados[bitacora$regla == "precio_cero_fuera_del_analisis"] == sum(lineas$analizable == 0),
          unname(tools::md5sum(archivo)) == md5_original)
pruebas <- rbind(pruebas, registrar_prueba("Conservación", "Entradas = fuera del período + selección; selección = analizadas + separadas; original intacto"))

probar_rollback <- function(ruta) {
  conexion <- abrir_base(ruta)
  on.exit(dbDisconnect(conexion))
  antes <- dbGetQuery(conexion, "SELECT COUNT(*) AS n FROM paises")$n
  mensaje <- tryCatch({
    dbWithTransaction(conexion, {
      dbExecute(conexion, "INSERT INTO paises VALUES (999999, 'PAIS DE PRUEBA')")
      dbExecute(conexion, "INSERT INTO lineas
        SELECT 9999999, 'FACTURA_INEXISTENTE', codigo, '2011-01-01 00:00:00', 1, 100, NULL, 1
        FROM articulos LIMIT 1")
    })
    "SIN ERROR"
  }, error = function(e) conditionMessage(e))
  stopifnot(grepl("FOREIGN KEY", mensaje, fixed = TRUE),
    dbGetQuery(conexion, "SELECT COUNT(*) AS n FROM paises")$n == antes,
    dbGetQuery(conexion, "SELECT COUNT(*) AS n FROM paises WHERE pais_id=999999")$n == 0,
    dbGetQuery(conexion, "SELECT COUNT(*) AS n FROM lineas WHERE fila_excel=9999999")$n == 0,
    nrow(dbGetQuery(conexion, "PRAGMA foreign_key_check")) == 0)
  mensaje
}
error_esperado <- probar_rollback(ruta_base)
pruebas <- rbind(pruebas, registrar_prueba("Rollback", paste("Una inserción válida se revirtió tras el error esperado:", error_esperado)))

# Reconstrucción independiente: mismo origen y misma preparación, otra SQLite.
# Se comparan todos los resultados, no solamente el número de filas.
probar_reconstruccion <- function() {
  segunda <- tempfile(fileext = ".sqlite")
  on.exit(unlink(segunda))
  crear_base(segunda)
  verificar_integridad(segunda)
  repetido <- consultar_base(segunda)
  stopifnot(isTRUE(all.equal(resultados, repetido, tolerance = 0)))
}
probar_reconstruccion()
pruebas <- rbind(pruebas, registrar_prueba("Segunda reconstrucción", "Las ocho consultas dan exactamente los mismos resultados en una base nueva"))
guardar_csv(pruebas, "verificaciones.csv")
cat("Todas las conexiones de consulta y prueba quedaron cerradas.\n")
