# Se puede ejecutar desde la carpeta del proyecto o dentro del notebook.
paquetes <- c("DBI", "RSQLite", "readxl", "dplyr", "ggplot2")
faltan <- paquetes[!sapply(paquetes, requireNamespace, quietly = TRUE)]
if (length(faltan) > 0) {
  install.packages(faltan, repos = "https://cloud.r-project.org")
}
suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
  library(readxl)
  library(dplyr)
  library(ggplot2)
})
options(timeout = 300, width = 110, repr.plot.width = 10, repr.plot.height = 6)

# En Colab, con el notebook solo, se usa /content. Con la entrega descomprimida,
# se reconoce la carpeta sin escribir una ruta particular de mi computadora.
raiz <- "."
if (!dir.exists("R") && dir.exists("TP2_ED_CasalAgustin")) {
  raiz <- "TP2_ED_CasalAgustin"
}
originales <- file.path(raiz, "datos", "original")
resultados_dir <- file.path(raiz, "salidas", "resultados")
for (carpeta in c(originales, resultados_dir, file.path(raiz, "sql"))) {
  dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
}
guardar_csv <- function(tabla, nombre) {
  write.csv(tabla, file.path(resultados_dir, nombre), row.names = FALSE,
            na = "", fileEncoding = "UTF-8")
}

url_fuente <- "https://archive.ics.uci.edu/static/public/352/online+retail.zip"
url_copia <- paste0("https://raw.githubusercontent.com/agustincasal1/exploracion-datos-tp2/",
                    "main/datos/original/Online%20Retail.xlsx")
archivo <- file.path(originales, "Online Retail.xlsx")
url_obtencion <- "Archivo local conservado"
if (!file.exists(archivo)) {
  descarga <- tempfile(fileext = ".zip")
  options(timeout = 45)
  desde_uci <- tryCatch({
    download.file(url_fuente, descarga, mode = "wb", quiet = TRUE)
    unzip(descarga, files = "Online Retail.xlsx", exdir = originales)
    file.exists(archivo)
  }, error = function(e) {
    message("No se pudo descargar desde UCI: ", conditionMessage(e))
    FALSE
  })
  unlink(descarga)
  if (desde_uci) {
    url_obtencion <- url_fuente
  } else {
    message("Intento la copia sin editar incluida en el repositorio del TP2.")
    options(timeout = 90)
    download.file(url_copia, archivo, mode = "wb", quiet = TRUE)
    url_obtencion <- url_copia
  }
  options(timeout = 300)
}

# La huella identifica exactamente la copia usada en la entrega.
md5_original <- unname(tools::md5sum(archivo))
stopifnot(md5_original == "8f8e6d94ba88f976f4d8290cb2dea7fd")
procedencia_archivo <- file.path(raiz, "datos", "procedencia.csv")
if (!file.exists(procedencia_archivo)) {
  procedencia <- data.frame(
    responsable = "Daqing Chen / UCI Machine Learning Repository",
    url = url_fuente, url_obtencion = url_obtencion,
    doi = "10.24432/C5BW33", licencia = "CC BY 4.0",
    archivo = "datos/original/Online Retail.xlsx", md5 = md5_original,
    registrado_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    nota = "Registro de esta copia local; puede reutilizarse en ejecuciones posteriores"
  )
  write.csv(procedencia, procedencia_archivo, row.names = FALSE, fileEncoding = "UTF-8")
}
print(read.csv(procedencia_archivo))

# read_excel reconoce la fecha de Excel como fecha y hora. Los códigos se leen
# como texto, aunque algunos tengan solamente números.
ventas_original <- as.data.frame(read_excel(
  archivo, sheet = 1, trim_ws = FALSE,
  col_types = c("text", "text", "text", "numeric", "date", "numeric", "numeric", "text")
))
stopifnot(identical(names(ventas_original), c(
  "InvoiceNo", "StockCode", "Description", "Quantity", "InvoiceDate",
  "UnitPrice", "CustomerID", "Country"
)))
cat("Hojas del Excel:", excel_sheets(archivo), "\n")
cat("Archivo completo:", nrow(ventas_original), "renglones y", ncol(ventas_original), "columnas\n")
print(head(ventas_original, 3))
str(ventas_original)

# El número de fila permite volver al Excel. La fila 1 contiene los nombres.
ventas_original$fila_excel <- seq_len(nrow(ventas_original)) + 1L
inicio <- as.POSIXct("2011-01-01", tz = "UTC")
fin <- as.POSIXct("2011-04-01", tz = "UTC")
en_periodo <- !is.na(ventas_original$InvoiceDate) &
  ventas_original$InvoiceDate >= inicio & ventas_original$InvoiceDate < fin
muestra <- ventas_original[en_periodo, ]
cat("Selección:", nrow(muestra), "renglones de enero a marzo de 2011\n")

# readxl usa UTC como representación técnica. El archivo no informa zona
# horaria: no convierto estas horas a la hora argentina ni afirmo que sean UTC.
diccionario <- data.frame(
  campo = c("InvoiceNo", "StockCode", "Description", "Quantity", "InvoiceDate",
            "UnitPrice", "CustomerID", "Country", "fila_excel", "precio_peniques",
            "importe_peniques", "pais_id", "cancelacion", "fila_descripcion"),
  significado = c("Número de factura; C inicial identifica cancelación", "Código de artículo o concepto",
    "Descripción informada en ese renglón", "Cantidad firmada: negativa en cancelaciones",
    "Fecha y hora sin zona informada", "Precio por unidad", "Identificador de cliente, puede faltar",
    "País del cliente según el archivo", "Fila física en el Excel original",
    "Precio unitario en centésimos de GBP", "Cantidad por precio en peniques",
    "Clave del catálogo de países", "1 si InvoiceNo empieza con C; 0 en otro caso",
    "Fila del Excel de la que se tomó la descripción de referencia"),
  tipo = c("texto", "texto", "texto", "entero", "fecha-hora", "numérico", "texto nullable",
           "texto", "entero", "entero", "entero calculado", "entero", "entero 0/1", "entero nullable"),
  unidad = c("sin unidad", "sin unidad", "sin unidad", "unidades del artículo", "fecha-hora",
             "GBP/unidad", "sin unidad", "sin unidad", "fila", "peniques/unidad",
             "peniques", "sin unidad", "sin unidad", "fila"),
  origen = c(rep("Excel original / hoja Online Retail", 8), rep("Derivado por el código", 6)),
  uso = c("relación", "relación", "etiqueta", "estudio", "estudio", "estudio", "calidad",
          "estudio", "trazabilidad", "estudio", "estudio", "relación", "estudio", "trazabilidad")
)
write.csv(diccionario, file.path(raiz, "datos", "diccionario.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
