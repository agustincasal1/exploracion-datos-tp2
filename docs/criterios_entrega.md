# Revisión de la consigna y la rúbrica

Referencia: consigna 333 y rúbrica 444 provistas por la cátedra.

| Paso | Evidencia que debe quedar en la entrega |
| --- | --- |
| 1. Problema y fuente | Tres preguntas, selección justificada, enlace, licencia, fecha de acceso, originales y diccionario. |
| 2. Diagnóstico | Dimensiones, estructura, ejemplos, cobertura, faltantes con proporciones, repeticiones, resúmenes y problemas antes de preparar. |
| 3. Modelo | Al menos cuatro tablas necesarias, dataframes identificados, diagrama, claves, cardinalidades, CREATE TABLE y foreign_keys activadas. |
| 4. Preparación | Al menos tres reglas justificadas, cantidades afectadas, comparación antes/después, bitácora exportada y carga transaccional. |
| 5. Resultados | Al menos cinco consultas SQL, dos con JOIN, uso de cuatro tablas, control de multiplicación de filas y tres gráficos ggplot2 interpretados. |
| 6. Verificaciones | Caso conocido, caso inválido separado, integridad, conciliación, rollback real, segunda reconstrucción y cierre de conexiones. |
| 7. Entrega | Notebook R con salidas, ejecución en Colab, README, paquetes y versiones, SQL, SQLite, originales, bitácora y presentación PDF. |

## Dónde revisar la evidencia

| Criterio | Ubicación en esta entrega |
| --- | --- |
| Problema, elección y filtros | Introducción y sección 1 del notebook, README, `docs/propuesta.md` y `datos/procedencia.csv`. |
| Diccionario y diagnóstico inicial | `datos/diccionario.csv`, sección 2 y `salidas/resultados/diagnostico_inicial.csv`, `problemas_iniciales.csv` y `diagnostico_facturas.csv`. |
| Entidades y relaciones | Sección 4, `docs/modelo_relacional.md`, diagrama SVG/PNG y `sql/esquema.sql`. Cuatro tablas con uso efectivo. |
| Reglas y comparación | Sección 3, `salidas/bitacora_limpieza.csv` y `salidas/resultados/antes_despues.csv`. Nueve reglas documentadas. |
| SQL y resultados | Sección 5 y `sql/consultas.sql`. Ocho consultas; JOIN en varias y control con las cuatro tablas. |
| Tres gráficos e interpretación | Sección 7, los tres PNG en `salidas/resultados/` y diapositivas 11, 12 y 13. |
| Pruebas y reproducibilidad | Sección 6, `R/06_verificar.R`, `salidas/resultados/verificaciones.csv` y `salidas/verificacion_entrega.txt`. |
| Dependencias, instrucciones y entrevista | `paquetes_R.txt`, `salidas/sessionInfo.txt`, versiones de paquetes, README y `docs/guia_entrevista.md`. |

Se verificaron la ejecución en R local, el notebook completo y su ejecución
autónoma desde una carpeta sin archivos auxiliares. Se comprobó la alternativa
de descarga cuando UCI no respondió. La ejecución autónoma obtuvo las mismas
tablas y resultados que la entrega. Esto no equivale a afirmar que se haya
ejecutado dentro del servicio Google Colab.

La presentación debe tener como máximo 20 diapositivas. Las tres últimas deben
ser los tres gráficos principales, uno por diapositiva, con mensaje y límites.
La entrevista individual dura cinco minutos y tiene tres preguntas. No se pide
volver a exponer todo ni programar en vivo.

