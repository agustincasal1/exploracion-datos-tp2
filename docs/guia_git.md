# Un recorrido por Git y GitHub

El historial tiene fechas distribuidas para la demostración de Git y GitHub.
No representan el tiempo real de elaboración. Se puede recorrer cómo se
plantearon las preguntas, se importaron los datos, se creó la base y se agregaron
consultas, verificaciones y documentación.

| Fecha y hora de Argentina | Etapa |
| --- | --- |
| 24/10/2026, 11:18 | Preguntas y elección de la fuente. |
| 24/10/2026, 18:42 | Importación y diagnóstico. |
| 25/10/2026, 10:36 | Preparación y base relacional. |
| 25/10/2026, 20:14 | Consultas, verificaciones y gráficos. |
| 26/10/2026, 18:33 | Notebook, presentación y documentación final. |

Las fechas de acceso a la fuente y las verificaciones se conservan sin cambios.
Los commits posteriores registran revisiones concretas con la fecha en que se hicieron.

```sh
git clone https://github.com/agustincasal1/exploracion-datos-tp2.git
cd exploracion-datos-tp2
git log --oneline --reverse
git log --format="%h %ad %s" --date=local
git status
```

Para ver qué contiene un commit sin cambiar los archivos:

```sh
git show --stat HASH_DEL_COMMIT
git show HASH_DEL_COMMIT -- R/01_importar.R
```

`HASH_DEL_COMMIT` se reemplaza por el código que aparece en el log. Para enseñar
una modificación se puede crear una rama y cambiar una explicación del README:

```sh
git switch -c practica-readme
git diff
git add README.md
git commit -m "Aclarar una explicación del README"
```

El notebook contiene salidas e imágenes: sus diferencias de texto pueden ser
largas. Los scripts de R y los archivos SQL permiten ver cambios de código con
más facilidad. La base SQLite es un archivo binario generado, por eso se
entrega también el código para reconstruirla.
