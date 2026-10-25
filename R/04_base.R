# El SQL queda también como archivo para poder leer el modelo por separado.
esquema <- c(
  "CREATE TABLE paises (
     pais_id INTEGER PRIMARY KEY,
     pais TEXT NOT NULL UNIQUE CHECK(length(trim(pais)) > 0)
   )",
  "CREATE TABLE facturas (
     factura TEXT PRIMARY KEY NOT NULL CHECK(length(factura) > 0),
     cliente_id TEXT,
     pais_id INTEGER NOT NULL REFERENCES paises(pais_id),
     cancelacion INTEGER NOT NULL CHECK(cancelacion IN (0,1)),
     CHECK(cancelacion = CASE WHEN substr(factura,1,1) = 'C' THEN 1 ELSE 0 END)
   )",
  "CREATE TABLE articulos (
     codigo TEXT PRIMARY KEY NOT NULL CHECK(length(codigo) > 0),
     descripcion TEXT,
     fila_descripcion INTEGER CHECK(fila_descripcion >= 2),
     CHECK((descripcion IS NULL AND fila_descripcion IS NULL) OR
           (descripcion IS NOT NULL AND fila_descripcion IS NOT NULL))
   )",
  "CREATE TABLE lineas (
     fila_excel INTEGER PRIMARY KEY CHECK(fila_excel >= 2),
     factura TEXT NOT NULL REFERENCES facturas(factura),
     codigo TEXT NOT NULL REFERENCES articulos(codigo),
     fecha_hora TEXT NOT NULL CHECK(length(fecha_hora) = 19
       AND strftime('%Y-%m-%d %H:%M:%S', fecha_hora) IS NOT NULL),
     cantidad INTEGER NOT NULL CHECK(typeof(cantidad) = 'integer'),
     precio_peniques INTEGER NOT NULL CHECK(precio_peniques >= 0 AND typeof(precio_peniques) = 'integer'),
     descripcion_original TEXT,
     analizable INTEGER NOT NULL CHECK(analizable IN (0,1)),
     CHECK(analizable = CASE WHEN precio_peniques > 0 AND cantidad != 0 THEN 1 ELSE 0 END)
   )"
)
writeLines(paste0(esquema, ";"), file.path(raiz, "sql", "esquema.sql"), useBytes = TRUE)

abrir_base <- function(ruta) {
  conexion <- dbConnect(SQLite(), ruta)
  tryCatch({
    dbExecute(conexion, "PRAGMA foreign_keys = ON")
    stopifnot(dbGetQuery(conexion, "PRAGMA foreign_keys")[[1]] == 1)
    conexion
  }, error = function(e) {
    dbDisconnect(conexion)
    stop(e)
  })
}

crear_base <- function(ruta) {
  # Sólo se reemplaza la base generada. Nunca se modifica el Excel original.
  if (file.exists(ruta)) stopifnot(file.remove(ruta))
  conexion <- abrir_base(ruta)
  on.exit(dbDisconnect(conexion))
  dbWithTransaction(conexion, {
    for (sentencia in esquema) dbExecute(conexion, sentencia)
    dbAppendTable(conexion, "paises", paises)
    dbAppendTable(conexion, "facturas", facturas)
    dbAppendTable(conexion, "articulos", articulos)
    dbAppendTable(conexion, "lineas", lineas)
    # La transacción se confirma sólo si la carga pasa estos controles.
    stopifnot(nrow(dbGetQuery(conexion, "PRAGMA foreign_key_check")) == 0,
      dbGetQuery(conexion, "SELECT COUNT(*) AS n FROM lineas")$n == nrow(lineas),
      dbGetQuery(conexion, "PRAGMA integrity_check")[[1]] == "ok")
  })
  invisible(ruta)
}
ruta_base <- file.path(raiz, "salidas", "proyecto.sqlite")
crear_base(ruta_base)
cat("Base creada con cuatro tablas relacionadas. La conexión de carga quedó cerrada.\n")
