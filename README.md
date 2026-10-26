# Una tienda online: ventas, países y cancelaciones

Trabajo Práctico 2 de Exploración de Datos. Licenciatura en Ciencia de Datos,
Universidad Católica Argentina, sede Rosario.

**Autor:** Agustín Casal. **Modalidad:** individual.

Me interesa el negocio online por mi empresa, OnCloud. Para este trabajo elegí
analizar datos públicos de una tienda online: qué importes registra, en qué países
y qué pasa cuando aparecen cancelaciones. Los datos pertenecen a una tienda
británica y no son datos de OnCloud.

## Las preguntas

1. ¿Cómo cambian los importes de ventas y cancelaciones entre enero y marzo de 2011?
2. ¿Qué países concentran el importe neto registrado en esos tres meses?
3. ¿Qué artículos tienen más unidades netas registradas?

La selección incluye el primer trimestre de 2011 y todos los países del archivo.
Cada fila original representa un renglón de una factura. Una factura puede tener
muchos renglones y un artículo puede aparecer en muchas facturas.

## La fuente

Chen, D. (2015). *Online Retail*. UCI Machine Learning Repository.
[Ficha y documentación](https://archive.ics.uci.edu/dataset/352/online+retail).
DOI: [10.24432/C5BW33](https://doi.org/10.24432/C5BW33).
Licencia de los datos: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

El archivo original tiene 541.909 renglones y ocho columnas. UCI identifica al
responsable, describe las variables y permite descargar el archivo sin una
cuenta. Esto permite revisar de dónde salen los datos y conservar una copia.
El negocio está anonimizado. La ficha no resuelve todas las dudas del archivo:
por ejemplo, informa que no hay faltantes, pero el diagnóstico encuentra clientes
sin identificar. Por eso reviso el contenido antes de tomar decisiones.

El dinero está expresado en libras esterlinas (GBP). Los resultados describen
registros históricos de una sola tienda, con clientes mayoristas entre sus
compradores. No representan el comercio online actual ni las ventas de OnCloud.

## Uso de IA e historial de Git

El proyecto se preparó con ayuda de inteligencia artificial para organizar el
análisis, escribir código y revisar la entrega. Las cifras deben salir de la
ejecución sobre los datos originales. El notebook explica las decisiones y las
pruebas para que se pueda revisar y entender el trabajo.

Los commits registran etapas del trabajo. Sus fechas se distribuyeron entre el
24, 25 y 26 de octubre de 2026 para la demostración de Git y GitHub; no representan
el tiempo real de elaboración. Las fechas de procedencia de los datos y de las
verificaciones conservan sus valores reales.

La propuesta de fuente todavía debe presentarse a la cátedra en el hito indicado
por la consigna. Las fechas de EVA y esa aprobación no están incluidas en los
archivos de la materia.

## Ejecutar en Google Colab

[Abrir el notebook en Colab](https://colab.research.google.com/github/agustincasal1/exploracion-datos-tp2/blob/main/TP2_ED_CasalAgustin.ipynb).

1. Comprobar que el entorno sea **R**. Si hace falta, crear uno desde
   <https://colab.research.google.com/#create=true&language=r> y subir el notebook.
2. Ejecutar todas las celdas en orden. La primera instala sólo los paquetes que
   faltan. El notebook contiene todo el código necesario, incluidos el esquema y
   las consultas: puede ejecutarse sin descargar los scripts auxiliares.
3. Si no encuentra el Excel, intenta descargarlo desde UCI. Son unos 23 MB.
   Si UCI no responde, intenta la copia sin editar del repositorio. En ambos casos
   verifica la huella MD5. Si ya está disponible, lo reutiliza.
4. Las salidas quedan en `salidas/` dentro de la carpeta de trabajo. Descargar los
   archivos que se quieran conservar antes de cerrar la sesión de Colab.

Para trabajar sin depender de UCI, subir el ZIP de la entrega a Colab y ejecutar
esta línea en una celda de R **antes** del resto:

```r
unzip("/content/TP2_ED_CasalAgustin.zip", exdir = "/content")
```

El código reconoce la carpeta `TP2_ED_CasalAgustin` y utiliza el Excel incluido.
Se necesita Internet para instalar paquetes faltantes. Con los paquetes y el
original disponibles, el análisis no requiere una conexión a la fuente.

## Ejecutar localmente

Con R instalado, abrir una terminal en la raíz del proyecto:

```sh
Rscript R/ejecutar.R
```

También se puede abrir `TP2_ED_CasalAgustin.ipynb` con un kernel R. El proceso
se validó ejecutándolo de principio a fin con R local. El diseño es compatible
con Colab R; no se presenta esa validación local como una ejecución en Colab.
Los paquetes están en `paquetes_R.txt`; sus versiones efectivamente usadas y la
versión de R quedan guardadas en `salidas/`.

Cada ejecución reconstruye `salidas/proyecto.sqlite` desde cero y vuelve a generar
las tablas de resultados. No acumula filas. El Excel se conserva sin editar.
Si UCI cambia el archivo y no coincide su MD5, el proceso se detiene: se puede
usar el original incluido para reproducir esta entrega.

## Qué contiene el proyecto

```text
TP2_ED_CasalAgustin.ipynb     Código, explicaciones y salidas ejecutadas
README.md                    Contexto e instrucciones
paquetes_R.txt               Paquetes para el análisis
presentacion.pdf             13 diapositivas, con los tres gráficos al final
datos/original/              Excel original sin editar
datos/diccionario.csv        Variables, tipos, unidades y origen
datos/procedencia.csv        URL, licencia, huella y registro de acceso
R/                           Pasos del proceso y script de ejecución
sql/esquema.sql              CREATE TABLE y restricciones
sql/consultas.sql            Ocho consultas con comentarios
salidas/proyecto.sqlite      Base generada
salidas/bitacora_limpieza.csv Reglas, decisiones y cantidades
salidas/resultados/          Diagnóstico, tablas SQL, pruebas y gráficos
docs/                        Modelo, propuesta y guías de apoyo
presentacion/                Código opcional para regenerar el PDF
```

Los scripts de `R/` y el notebook realizan el mismo proceso. El notebook integra
el código para poder usarlo solo en Colab. La herramienta Python de
`presentacion/` arma el PDF a partir de salidas ya calculadas en R; no participa
del análisis. Para usarla se necesitan `reportlab` y `pymupdf`.

## Del Excel a las cuatro tablas

La estructura original es una hoja plana con datos de factura, artículo y
renglón repetidos en las mismas filas. `ventas_original` conserva la lectura
recibida; `muestra` selecciona el trimestre y `ventas` es la copia preparada.

Los dataframes `paises`, `facturas`, `articulos` y `lineas` se construyen con
valores del Excel. No hay entidades inventadas. El período y las reglas sí son
decisiones del código. La procedencia del archivo se documenta aparte.

El [diagrama y la explicación del modelo](docs/modelo_relacional.md) detallan
atributos, claves y cardinalidades. Las relaciones son país 1 a N facturas,
factura 1 a N líneas y artículo 1 a N líneas. `fila_excel` conserva el vínculo
de cada renglón con el original. La hora va en las líneas porque 22 facturas
tienen más de una hora informada.

## Decisiones de preparación

- Conservar el cliente desconocido como NULL. No eliminar ventas ni inventar ID.
- Convertir el precio a peniques enteros, tras verificar que tenga hasta dos
  decimales. Los importes se calculan con cantidad firmada por precio, y al
  mostrarlos se dividen por 100 para volver a GBP.
- Guardar fecha y hora en formato ISO por renglón. La fuente no informa zona
  horaria. UTC en la importación es una representación técnica, no una conversión.
- Normalizar espacios de las etiquetas y tratar `?` como etiqueta ausente.
  Conservar la descripción original y elegir una descripción de referencia por
  código, dejando registrada su fila de origen.
- Mantener los 513 renglones con precio cero en SQLite y excluirlos de los tres
  resultados de ventas. No se puede afirmar que sean regalos o ventas gratuitas.
- Conservar las 784 repeticiones exactas: no hay un identificador de renglón que
  permita probar que sean errores. Medir también el resultado si se quitaran.

El diagnóstico informa antes de limpiar faltantes, vacíos, interrogaciones,
valores distintos, repeticiones, frecuencias, rangos y conflictos de factura o
descripción. La bitácora registra nueve reglas y diferencia renglones de
artículos. La comparación antes/después está en `salidas/resultados/antes_despues.csv`.

## Consultas y resultados esperados

| Consulta | Una fila representa | Uso |
| --- | --- | --- |
| mensual | Un mes del trimestre. | Ventas, cancelaciones y neto, en GBP. Gráfico 1. |
| paises | Un país del cliente. | Neto y participación en el neto de todos los países. Gráfico 2. |
| articulos | Un código de artículo o concepto. | Unidades positivas, canceladas y netas. Gráfico 3. |
| control_joins | El conjunto de líneas unido a las otras tres tablas. | Comprobar que no se multipliquen renglones ni importes. |
| calidad | El conjunto seleccionado. | Contar clientes ausentes, precio cero y líneas analizadas. |
| caso_conocido | Una de dos líneas concretas del Excel. | Verificar una compra y una cancelación a mano. |
| repeticiones | Un resumen de repeticiones exactas. | Cuantificar la sensibilidad a conservar una sola copia. |
| totales | El conjunto de líneas sin JOIN. | Comparar conteos e importes con el control de relaciones. |

La selección tiene **99.602 renglones, 4.852 facturas, 3.067 códigos y 31 países**.
Entran en los resultados **99.089 renglones**. No se perdieron filas al crear la
base. Los 29.505 renglones sin cliente identificado se mantienen.

| Mes | Ventas positivas (GBP) | Cancelaciones, en valor absoluto (GBP) | Neto (GBP) |
| --- | ---: | ---: | ---: |
| Enero de 2011 | 691.364,56 | 131.364,30 | 560.000,26 |
| Febrero de 2011 | 523.631,89 | 25.569,24 | 498.062,65 |
| Marzo de 2011 | 717.639,36 | 34.372,28 | 683.267,08 |

El neto del trimestre es **1.741.329,99 GBP**. Reino Unido concentra el **80,5 %**.
El código `85099B`, JUMBO BAG RED RETROSPOT, encabeza las unidades netas con
**10.996**. Las tres lecturas se explican con sus límites en el notebook y en
las últimas tres diapositivas. Los resultados no permiten afirmar causalidad.

## Verificaciones

El proceso comprueba con `stopifnot` un caso calculado a mano, casos inválidos o
límite separados, claves únicas, `PRAGMA foreign_key_check`, conservación de
filas y del original, equivalencia SQL/R y ausencia de multiplicaciones en JOIN.
Activa las claves foráneas en cada conexión y cierra las conexiones también al
manejar errores.

La carga usa `dbWithTransaction`: si falla, se revierte. Una prueba inserta un
país válido y después intenta una línea con una factura inexistente. Se verifica
que **ninguna** inserción quede guardada. Otra reconstruye una segunda SQLite y
compara exactamente las ocho consultas. Los resultados de las siete
comprobaciones están en `salidas/resultados/verificaciones.csv`.

## Límites

Estos registros no miden ganancia ni ventas auditadas. No informan costos,
impuestos o motivos de cancelación. Algunas cancelaciones pueden corresponder a
compras fuera del trimestre, por lo que no calculo una tasa de devolución por
compra. Algunos códigos representan cargos o ajustes, y las cantidades de packs
son unidades comerciales, no sus piezas individuales.

Eliminar las copias posteriores de los renglones repetidos bajaría el neto en
3.841,04 GBP, alrededor del 0,22 %. Se conservan y se informa esa sensibilidad.
La diferencia entre meses describe esos meses. La comparación entre países
describe la clientela informada de esta tienda, no el tamaño de sus mercados.
Los importes históricos no se convierten a moneda actual.

La presentación sirve de referencia para la entrevista individual de cinco
minutos y tres preguntas. La [guía de entrevista](docs/guia_entrevista.md)
ayuda a repasar qué hace el código y por qué se tomaron las decisiones.

