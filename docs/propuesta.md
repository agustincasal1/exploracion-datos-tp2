# Propuesta de TP2

Autor: Agustín Casal. Exploración de Datos, UCA Rosario.

## Problema e interés

Quiero entender cómo se reparten las ventas de una tienda online y cuánto cambian
los resultados al considerar sus cancelaciones. Me interesa este tema por mi
vínculo con el negocio online a través de OnCloud. Uso datos públicos de otra
empresa para que el trabajo se pueda compartir y revisar.

Las preguntas son: cómo cambian los importes por mes, qué países concentran el
importe neto y qué artículos registran más unidades netas. Esto podría servirle a
alguien que organiza las ventas de una tienda para identificar dónde mirar con
más detalle. No alcanza para recomendar compras de stock o explicar causas.

## Elección de la fuente

Elegí Online Retail de Daqing Chen, publicado por UCI:
https://archive.ics.uci.edu/dataset/352/online+retail

Antes consideré seguir el ejemplo de NASA POWER que aparece en el material de
clase. Para este proyecto prefiero ventas: se relaciona con mi interés y los
datos ya tienen entidades que se pueden separar sin forzar el modelo.

La ficha tiene responsable, documentación, DOI y licencia CC BY 4.0. El archivo
se descarga sin credenciales. Es una fuente académica identificable, aunque eso
no significa que todos los registros estén completos o libres de errores.

Se conserva el Excel completo sin editar. Para trabajar selecciono enero, febrero
y marzo de 2011, todos los países y todas las columnas. Es un período acotado,
con tres meses completos. Se excluyen de la selección los demás meses, no se
elige una muestra al azar. La tienda vendía regalos y tenía compradores
mayoristas, por lo que no se generaliza a cualquier tienda.

## Variables y organización inicial

Estudio cantidad de unidades, precio por unidad en GBP, fecha y país informado.
La multiplicación de cantidad por precio da el importe firmado del renglón.
Un número de factura que empieza con C indica una cancelación según UCI.
La fuente no permite asegurar que cada cancelación sea una devolución física.

Modelo inicial de cuatro tablas:

- `paises`: un país informado por fila.
- `facturas`: un número de factura, su país, cliente si está informado y tipo.
- `articulos`: un código de artículo y una descripción de referencia.
- `lineas`: un renglón del Excel, con factura, artículo, fecha, cantidad y precio.

Las relaciones son países 1 a N facturas, facturas 1 a N líneas y artículos 1 a
N líneas. Las fechas se conservan en las líneas porque el diagnóstico detectó
facturas cuyos renglones tienen horas diferentes.

Estado: propuesta preparada. Su aceptación y las fechas de entrega se consultan
en EVA o con la cátedra.

