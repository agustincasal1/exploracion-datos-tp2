# Modelo relacional

Un renglón del archivo original se convierte en una fila de `lineas`.
La separación no agrega ventas ni cambia la cantidad de registros recibidos.

```mermaid
erDiagram
    paises ||--o{ facturas : tiene
    facturas ||--|{ lineas : contiene
    articulos ||--|{ lineas : aparece
    paises {
        INTEGER pais_id PK
        TEXT pais UK
    }
    facturas {
        TEXT factura PK
        TEXT cliente_id "puede ser NULL"
        INTEGER pais_id FK
        INTEGER cancelacion "0 o 1"
    }
    articulos {
        TEXT codigo PK
        TEXT descripcion "puede ser NULL"
        INTEGER fila_descripcion "fila del Excel, puede ser NULL"
    }
    lineas {
        INTEGER fila_excel PK
        TEXT factura FK
        TEXT codigo FK
        TEXT fecha_hora
        INTEGER cantidad
        INTEGER precio_peniques
        TEXT descripcion_original "puede ser NULL"
        INTEGER analizable "0 o 1"
    }
```

| Tabla | Una fila representa | Clave y motivo |
| --- | --- | --- |
| paises | Un nombre de país recibido. | `pais_id`: se asigna después de ordenar los nombres; `pais` es único. |
| facturas | Un número de factura recibido, de venta o cancelación. | `factura`: sus renglones coinciden en país y cliente. La hora puede variar entre líneas. |
| articulos | Un código de artículo o concepto recibido. | `codigo`: la descripción puede cambiar. La etiqueta elegida guarda su fila de procedencia. |
| lineas | Un renglón físico del Excel dentro del trimestre. | `fila_excel`: permite volver al original y conservar repeticiones sin inventar un ID comercial. |

`PK` es clave primaria: identifica una fila de la tabla. `FK` es clave foránea:
apunta a una fila de otra tabla. `UK` marca un valor único. Un país tiene muchas
facturas, una factura tiene muchas líneas y un artículo aparece en muchas líneas.
Cada línea pertenece a una sola factura y a un solo código.

Los cuatro dataframes salen del Excel. El código define el período, los nombres
de tablas, las reglas y las claves de países, pero no inventa países, facturas,
artículos ni precios. `procedencia.csv` describe la copia del archivo y no cuenta
como una quinta entidad del análisis.

El cliente se conserva como atributo opcional de la factura. El proyecto no
analiza clientes individuales ni necesita un catálogo que sólo repita ese ID.
Un valor NULL significa cliente desconocido y no es una referencia huérfana.

El catálogo de artículos usa la primera descripción válida con precio positivo,
o la primera válida si no hay otra. No afirma que sea un nombre oficial actual.
La descripción recibida en cada renglón se conserva en `lineas`, y
`fila_descripcion` permite revisar qué fila eligió el código.

Algunas descripciones nombran packs. Las cantidades son unidades comerciales
del código, no el número de piezas individuales que contiene cada pack.

