# Consultas de resultados y controles. Importes guardados en peniques.
consultas <- list(
  mensual = "-- Una fila por mes. GBP, sólo líneas con precio positivo.
-- ventas: cantidad positiva; cancelaciones: magnitud del importe negativo.
-- neto = ventas - cancelaciones. No es ganancia ni ingreso contable auditado.
SELECT substr(l.fecha_hora,1,7) AS mes,
       COUNT(*) AS lineas,
       COUNT(DISTINCT f.factura) AS facturas,
       SUM(CASE WHEN f.cancelacion=0 THEN l.cantidad*l.precio_peniques ELSE 0 END)/100.0 AS ventas_gbp,
       -SUM(CASE WHEN f.cancelacion=1 THEN l.cantidad*l.precio_peniques ELSE 0 END)/100.0 AS cancelaciones_gbp,
       SUM(l.cantidad*l.precio_peniques)/100.0 AS neto_gbp
FROM lineas l JOIN facturas f ON l.factura=f.factura
WHERE l.analizable=1
GROUP BY substr(l.fecha_hora,1,7)
ORDER BY mes",

  paises = "-- Una fila por país del cliente informado en la factura.
-- Participación = neto del país / neto de todos los países analizados, por 100.
SELECT p.pais, COUNT(*) AS lineas, COUNT(DISTINCT f.factura) AS facturas,
       SUM(l.cantidad*l.precio_peniques)/100.0 AS neto_gbp,
       100.0*SUM(l.cantidad*l.precio_peniques)/
         (SELECT SUM(cantidad*precio_peniques) FROM lineas WHERE analizable=1) AS porcentaje_neto
FROM lineas l JOIN facturas f ON l.factura=f.factura
JOIN paises p ON f.pais_id=p.pais_id
WHERE l.analizable=1
GROUP BY p.pais_id, p.pais
ORDER BY neto_gbp DESC, p.pais",

  articulos = "-- Una fila por código de artículo o concepto. Cantidades del mismo código.
-- Unidades netas = positivas + negativas. Se ordenan todos los códigos.
-- Algunos códigos de la fuente representan cargos como envío, no objetos físicos.
SELECT a.codigo, a.descripcion, COUNT(*) AS lineas,
       SUM(CASE WHEN l.cantidad>0 THEN l.cantidad ELSE 0 END) AS unidades_positivas,
       -SUM(CASE WHEN l.cantidad<0 THEN l.cantidad ELSE 0 END) AS unidades_canceladas,
       SUM(l.cantidad) AS unidades_netas,
       SUM(l.cantidad*l.precio_peniques)/100.0 AS neto_gbp
FROM lineas l JOIN articulos a ON l.codigo=a.codigo
WHERE l.analizable=1
GROUP BY a.codigo, a.descripcion
ORDER BY unidades_netas DESC, a.codigo",

  control_joins = "-- Un control global que utiliza las cuatro tablas.
-- Filas y dinero deben coincidir con la tabla lineas sin JOIN.
SELECT COUNT(*) AS filas, COUNT(DISTINCT l.fila_excel) AS filas_distintas,
       SUM(l.cantidad*l.precio_peniques) AS importe_peniques
FROM lineas l JOIN facturas f ON l.factura=f.factura
JOIN paises p ON f.pais_id=p.pais_id
JOIN articulos a ON l.codigo=a.codigo",

  calidad = "-- Una fila de control: incluye todas las líneas, también las no analizadas.
-- Los faltantes de cliente se cuentan por renglón, no por cliente.
SELECT COUNT(*) AS filas,
       SUM(CASE WHEN f.cliente_id IS NULL THEN 1 ELSE 0 END) AS sin_cliente,
       SUM(CASE WHEN l.precio_peniques=0 THEN 1 ELSE 0 END) AS precio_cero,
       SUM(CASE WHEN l.analizable=1 THEN 1 ELSE 0 END) AS analizadas,
       COUNT(DISTINCT l.factura) AS facturas,
       COUNT(DISTINCT l.codigo) AS articulos
FROM lineas l JOIN facturas f ON l.factura=f.factura",

  caso_conocido = "-- Las dos filas de un caso concreto del Excel. Importe en peniques.
SELECT fila_excel, factura, codigo, fecha_hora, cantidad, precio_peniques,
       cantidad*precio_peniques AS importe_peniques
FROM lineas WHERE fila_excel IN (61621,61626) ORDER BY fila_excel",

  repeticiones = "-- Identidad en los ocho campos recibidos: país y cliente dependen de factura.
-- Filas extra significa copias posteriores a la primera, sin afirmar que sean errores.
-- Sensibilidad: cuánto dinero se restaría si se decidiera conservar sólo la primera.
SELECT COALESCE(SUM(n-1),0) AS filas_extra,
       COALESCE(SUM(CASE WHEN analizable=1 THEN (n-1)*importe ELSE 0 END),0)/100.0 AS diferencia_gbp
FROM (
 SELECT COUNT(*) AS n, analizable, cantidad*precio_peniques AS importe
 FROM lineas
 GROUP BY factura,codigo,descripcion_original,cantidad,fecha_hora,precio_peniques,analizable
 HAVING COUNT(*)>1
)",

  totales = "-- Totales de control. Importe firmado en peniques, sin sumar unidades de artículos distintos.
SELECT COUNT(*) AS filas, SUM(cantidad*precio_peniques) AS importe_peniques
FROM lineas"
)
texto_sql <- character()
for (nombre in names(consultas)) {
  texto_sql <- c(texto_sql, paste0("-- CONSULTA: ", nombre, "\n", consultas[[nombre]], ";\n"))
}
writeLines(texto_sql, file.path(raiz, "sql", "consultas.sql"), useBytes = TRUE)

consultar_base <- function(ruta) {
  conexion <- abrir_base(ruta)
  on.exit(dbDisconnect(conexion))
  tablas <- list()
  for (nombre in names(consultas)) {
    tablas[[nombre]] <- dbGetQuery(conexion, consultas[[nombre]])
  }
  tablas
}
resultados <- consultar_base(ruta_base)
for (nombre in names(resultados)) {
  cat("\nConsulta:", nombre, "\n")
  print(head(resultados[[nombre]], 10))
  guardar_csv(resultados[[nombre]], paste0(nombre, ".csv"))
}
