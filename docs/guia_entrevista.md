# Repaso para la entrevista

La entrevista dura cinco minutos y tiene tres preguntas. Conviene practicar
siguiendo una pregunta del trabajo hasta su consulta y su gráfico.

## Tema y fuente

Elegí las ventas online por mi interés en OnCloud. UCI tiene autor, documentación,
licencia y un archivo descargable. Los datos corresponden a otra tienda, de 2011.
El diagnóstico importa: la ficha dice que no hay faltantes, pero el Excel sí tiene.

## Filas y tablas

Cada fila es una línea de factura. Para contar facturas uso
`COUNT(DISTINCT factura)`. Separo países, facturas, artículos y líneas porque esos
datos se repiten. La PK identifica una fila y la FK apunta a otra tabla.
El JOIN permite llegar del importe de una línea al país de su factura.

Hay 22 facturas con más de una hora entre sus renglones. Por eso conservo la hora
en cada línea. País y cliente son constantes dentro de cada factura seleccionada.

## Decisiones de preparación

- El cliente desconocido queda como NULL. El renglón todavía sirve para estudiar
  cantidad, precio y país.
- Una libra son cien peniques. Verifico los decimales y multiplico el precio por
  cien para sumar enteros en SQLite; al mostrar el resultado vuelvo a GBP.
- Las cantidades negativas con precio positivo corresponden a facturas C.
  Una compra de 74.215 unidades y su cancelación suman cero en el caso revisado.
- Mantengo las repeticiones porque falta un ID comercial de línea que permita
  demostrar un error. Quitar las copias posteriores bajaría el neto 3.841,04 GBP.

## Transacciones y pruebas

Una transacción guarda juntas las operaciones o las revierte si falla alguna.
La prueba agrega un país válido y después intenta una línea con factura
inexistente. La segunda debe fallar y las dos deben revertirse.

`stopifnot` detiene el proceso cuando una condición falla. `on.exit` cierra la
conexión al salir de la función. La reconstrucción crea otra base y compara las
ocho consultas completas con la primera.

## Mensaje de los gráficos

1. Marzo tiene el mayor neto: 683.267,08 GBP. Enero concentra más cancelaciones.
2. Reino Unido reúne el 80,5 % del neto de los 31 países, aunque se muestren ocho.
3. El código 85099B tiene 10.996 unidades netas. Son unidades comerciales del código.

Los resultados describen el trimestre de esta tienda. Faltan costos para hablar
de ganancias y algunas cancelaciones pueden corresponder a compras anteriores.
