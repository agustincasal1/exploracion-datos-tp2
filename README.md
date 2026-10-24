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

Los commits usan sus fechas reales y registran etapas del trabajo. El historial
también sirve para mostrar el uso de Git y GitHub.

La propuesta de fuente todavía debe presentarse a la cátedra en el hito indicado
por la consigna. Las fechas de EVA y esa aprobación no están incluidas en los
archivos de la materia.

