# Una tienda online: ventas, países y cancelaciones

TP2 de Exploración de Datos. Licenciatura en Ciencia de Datos, UCA Rosario.
**Autor: Agustín Casal.** Trabajo individual.

Elegí este tema por mi interés en el negocio online a través de OnCloud.
Analizo los registros públicos de una tienda británica de regalos para responder:

1. ¿Cómo cambian las ventas y cancelaciones entre enero y marzo de 2011?
2. ¿Qué países concentran el importe neto del trimestre?
3. ¿Qué artículos tienen más unidades netas registradas?

## Fuente y selección

Chen, D. (2015). *Online Retail*, UCI Machine Learning Repository.
[Ficha del conjunto](https://archive.ics.uci.edu/dataset/352/online+retail).
[DOI 10.24432/C5BW33](https://doi.org/10.24432/C5BW33).
Licencia: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Acceso: 26/10/2026; registro y huella en `datos/procedencia.csv`.

UCI identifica al autor, explica las variables y ofrece el Excel sin credenciales.
El archivo tiene 541.909 renglones y ocho columnas. Sus números de factura y
códigos de artículo permiten armar las relaciones. La ficha indica que no hay
faltantes, pero al leerlo aparecen clientes sin identificar.

Conservo el Excel completo sin editar y selecciono enero, febrero y marzo de
2011, con todos los países y columnas. Son 99.602 renglones, 4.852 facturas,
3.067 códigos y 31 países. Quedan fuera los demás meses; la selección no es al azar.
Cada renglón corresponde a una línea de factura.

## Ejecutar

[Abrir el notebook en Colab](https://colab.research.google.com/github/agustincasal1/exploracion-datos-tp2/blob/main/TP2_ED_CasalAgustin.ipynb).
Usar **kernel R** y ejecutar todas las celdas en orden. También se puede crear una
sesión desde <https://colab.research.google.com/#create=true&language=r> y subirlo.
El notebook contiene el proceso completo e instala los paquetes faltantes.

Si falta el Excel, intenta descargarlo de UCI y luego de la copia del repositorio.
Comprueba su MD5 antes de leerlo. Para usar los originales incluidos, subir el ZIP
de la entrega a Colab y ejecutar primero en una celda de R:

```r
unzip("/content/TP2_ED_CasalAgustin.zip", exdir = "/content")
```

Para ejecutar los scripts con R local, abrir una terminal en esta carpeta:

```sh
Rscript R/ejecutar.R
```

Cada ejecución reconstruye la base y reemplaza las salidas. Con el Excel y los
paquetes disponibles se puede trabajar sin conexión. `paquetes_R.txt` lista las
dependencias; `salidas/sessionInfo.txt` y `salidas/resultados/versiones_paquetes.csv`
guardan las versiones usadas. Se probó el proceso en R local y el notebook desde
una carpeta vacía. Está preparado para Colab R; falta comprobarlo en ese servicio.

## Organización de los datos

`ventas_original` conserva la lectura del Excel, `muestra` contiene el trimestre
y `ventas` es la copia de trabajo. El período y las reglas se definen en el código.
Los cuatro dataframes de la base salen de los valores del archivo:

| Tabla | Qué representa una fila | Clave |
| --- | --- | --- |
| paises | Un país informado. | pais_id, asignado al ordenar los nombres. |
| facturas | Un número de factura, con país y cliente opcional. | factura |
| articulos | Un código y su descripción de referencia. | codigo |
| lineas | Un renglón del Excel, con cantidad, precio y fecha. | fila_excel |

Un país tiene muchas facturas, una factura muchas líneas y un artículo aparece
en muchas líneas. La hora va en cada línea porque 22 facturas tienen horas
diferentes entre sus renglones. El [modelo](docs/modelo_relacional.md) muestra
atributos y relaciones. El diccionario está en `datos/diccionario.csv`.

## Preparación

| Campo o situación | Decisión |
| --- | --- |
| Cliente ausente | Conservar el renglón y guardar NULL en la factura. |
| Fecha | Escribir fecha y hora por línea en formato ISO. La zona horaria no está informada. |
| Precio | Pasar de GBP a peniques enteros después de comprobar los decimales. |
| Descripción | Quitar espacios de las etiquetas y tratar vacío o `?` como ausente. Conservar el texto original. |
| Varias descripciones por código | Elegir la primera válida con precio positivo, o la primera válida disponible. Guardar su fila de origen. |
| Precio cero | Conservar los 513 renglones en SQLite y separarlos de los resultados de ventas. |
| Repeticiones exactas | Mantener las 784 copias posteriores y calcular cuánto cambiaría el neto si se quitaran. |

La bitácora registra condición, motivo, acción, afectados y conteos antes/después.
La base conserva los 99.602 renglones; los gráficos usan los 99.089 con precio
positivo. Los 29.505 renglones sin cliente (29,62 %) siguen incluidos.

## Consultas y resultados

`sql/consultas.sql` contiene ocho consultas: por mes, país y artículo; controles
de JOIN y calidad; un caso conocido; repeticiones y totales. Los comentarios
indican qué representa cada fila y sus unidades. El control de JOIN usa las cuatro
tablas y compara cantidad de líneas e importe contra los datos sin enlazar.

El importe de una línea es cantidad por precio. Las cancelaciones tienen factura
con C y cantidad negativa. Neto significa ventas positivas menos cancelaciones.

| Mes | Ventas (GBP) | Cancelaciones, en valor absoluto (GBP) | Neto (GBP) |
| --- | ---: | ---: | ---: |
| Enero | 691.364,56 | 131.364,30 | 560.000,26 |
| Febrero | 523.631,89 | 25.569,24 | 498.062,65 |
| Marzo | 717.639,36 | 34.372,28 | 683.267,08 |

El neto del trimestre es **1.741.329,99 GBP**. Reino Unido concentra el **80,5 %**.
El código 85099B, JUMBO BAG RED RETROSPOT, encabeza las unidades netas con **10.996**.
Los tres gráficos salen de consultas SQLite y están interpretados en el notebook.

## Pruebas y límites

Se verifican un caso calculado a mano, ejemplos inválidos separados, claves y
referencias, el neto mensual SQL contra R, conteos y bitácora. También se prueba
un rollback: una inserción válida se revierte cuando falla la siguiente. Otra
SQLite reconstruida debe devolver las ocho consultas iguales. Las funciones
cierran las conexiones al terminar, incluso ante errores.

Los resultados describen esta tienda en tres meses de 2011. Hay compradores
mayoristas y códigos que representan cargos. Las cantidades de packs son unidades
comerciales. Faltan costos para calcular ganancias y motivos para explicar las
cancelaciones. Algunas pueden corresponder a compras de otro período. Si se
quitaran las copias posteriores de filas idénticas, el neto bajaría 3.841,04 GBP
(aproximadamente 0,22 %). Estos datos no representan las ventas de OnCloud.

## Archivos de entrega

- `TP2_ED_CasalAgustin.ipynb`: código, explicaciones y salidas.
- `R/`: scripts del mismo proceso; `sql/`: esquema y consultas.
- `datos/`: original, diccionario y procedencia.
- `salidas/`: SQLite, bitácora, resultados, gráficos y versiones.
- `presentacion.pdf`: 13 diapositivas, con los tres gráficos al final.
- `docs/`: propuesta, modelo y guías para la entrevista y GitHub.

La [propuesta](docs/propuesta.md) queda para presentar a la cátedra según los hitos
de EVA. La [guía de entrevista](docs/guia_entrevista.md) ayuda a repasar el trabajo;
la [guía de Git](docs/guia_git.md) explica el historial preparado para la demostración.
