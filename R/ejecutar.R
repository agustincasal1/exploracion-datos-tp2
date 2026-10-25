# Ejecutar desde la carpeta raíz del proyecto: Rscript R/ejecutar.R
invisible(pdf(NULL))
for (archivo_r in c("01_importar.R", "02_diagnostico.R", "03_preparar.R", "04_base.R",
                    "05_consultas.R", "06_verificar.R", "07_graficos.R")) {
  source(file.path("R", archivo_r), encoding = "UTF-8")
}
invisible(dev.off())
