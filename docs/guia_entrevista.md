# Guía para entender y explicar el trabajo

La entrevista tiene tres preguntas en cinco minutos. Estas preguntas de práctica
no son una exposición para memorizar: conviene abrir el notebook y ubicar la
evidencia de cada respuesta.

## ¿Por qué elegiste el tema y esta fuente?

Me interesa el negocio online por mi vínculo con OnCloud. Elegí datos públicos de
otra tienda para poder compartirlos. UCI identifica autor, DOI, variables y
licencia. Eso permite revisar la procedencia. El diagnóstico igual es necesario:
la ficha dice que no hay faltantes, pero hay clientes sin identificar.

## ¿Qué representa una fila? ¿Por qué no es una venta completa?

Es un renglón de factura. Una factura puede incluir varios artículos y varias
líneas del mismo artículo. Por eso no cuento filas como si fueran facturas:
para contar facturas uso `COUNT(DISTINCT factura)`.

## ¿Por qué cuatro tablas?

Los nombres de países y los datos de factura se repetían en muchas líneas. Los
separo para guardar cada entidad una vez y relacionarla por su clave. Un país
tiene muchas facturas, una factura muchas líneas y un artículo aparece en muchas
líneas. No agregué tablas solamente para alcanzar el mínimo.

## ¿Qué es una clave foránea? ¿Qué hace JOIN?

`lineas.factura` debe apuntar a una factura que exista. Eso es una clave foránea.
Un JOIN relaciona las filas por esas claves: permite llegar del importe de una
línea al país de su factura. Compruebo que el JOIN conserve el número de filas y
el importe total para no sumar dinero varias veces por error.

## ¿Por qué guardaste la hora en cada línea?

Hay 22 números de factura con distintas horas entre sus renglones. Si eligiera
una sola hora en la cabecera, perdería ese dato. País y cliente sí son constantes
dentro de cada factura de la selección y el código lo comprueba.

## ¿Por qué no borraste las filas sin cliente?

El 29,62 % de los renglones no identifica al cliente. Igual tiene cantidad,
precio y país, por lo que sirve para estas preguntas. Dejo el cliente como NULL.
No lo reemplazo por cero porque eso crearía un cliente que no existe.

## ¿Por qué convertiste el precio a peniques?

Una libra son cien peniques. Verifiqué que todos los precios seleccionados tengan
hasta dos decimales y los multipliqué por cien. Así SQLite suma enteros. Al
mostrar el resultado divido por 100. No cambié el valor ni la moneda.

## ¿Por qué hay cantidades negativas? ¿Por qué no las eliminaste?

UCI dice que C al principio de la factura marca una cancelación. En las líneas
con precio positivo coincide con cantidad negativa. Conservo esa cantidad para
calcular el neto. Por ejemplo, una compra de 74.215 unidades y su cancelación
dieciséis minutos después suman cero. No puedo afirmar que cada cancelación sea
una devolución física ni saber si todas corresponden a compras del trimestre.

## ¿Por qué no eliminaste las repeticiones?

Hay 784 filas iguales a otra anterior en los ocho campos recibidos, pero no hay
ID comercial de renglón. No puedo demostrar que sean errores. Por eso las
conservo y calculo cuánto cambia el resultado si dejo una sola copia: el neto
bajaría 3.841,04 GBP, aproximadamente 0,22 %.

## ¿Qué hace una transacción? ¿Cómo verificaste el rollback?

Agrupa una carga: se guarda completa si pasa los controles o se revierte si
falla. La prueba agrega un país válido y después intenta una línea cuya factura
no existe. La segunda operación falla y compruebo que tampoco quedó el país.
Las filas de prueba no forman parte de los datos del análisis.

## ¿Para qué sirven stopifnot y on.exit?

`stopifnot` detiene el proceso si una condición necesaria no se cumple. Por
ejemplo, si un JOIN aumenta el número de filas. `on.exit(dbDisconnect(...))`,
dentro de una función, cierra la conexión cuando la función termina, incluso si
se produjo un error. No hay que aprender una definición aislada: conviene ubicar
un ejemplo de cada una en `R/04_base.R` y `R/06_verificar.R`.

## ¿Qué dirías de cada gráfico?

1. Marzo registra el mayor neto de los tres meses, 683.267,08 GBP. Enero tiene
   más importe cancelado. Tres meses no prueban una tendencia anual.
2. Reino Unido representa el 80,5 % del neto. El denominador es el neto de los
   31 países, no el de los ocho mostrados. Esto describe una tienda británica.
3. El artículo 85099B tiene 10.996 unidades netas. El orden por unidades no es un
   orden por ganancia. Un pack cuenta como unidad comercial del código.

## ¿Qué no podés concluir?

No sé la ganancia porque faltan costos. No sé por qué se canceló cada operación.
No puedo generalizar estos datos de 2011 a OnCloud ni al comercio online actual.
Tampoco comparo países como si sus mercados tuvieran el mismo tamaño o cobertura.

## Tres recorridos cortos de práctica

- Explicar una pregunta, su consulta SQL, el dataframe de resultado y su gráfico.
- Volver desde `lineas.fila_excel` al renglón del Excel y explicar la preparación.
- Leer la prueba de rollback y señalar qué se espera que quede en la base.
