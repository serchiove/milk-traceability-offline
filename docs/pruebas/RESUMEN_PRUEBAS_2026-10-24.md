# Avance de pruebas — Elías

Versión probada: `a59788d02c3ebf7a6e1fe443ea4e9625d94ce1aa`.

La matriz registra 22 casos aprobados y 2 parciales. La suite backend informa 31 pruebas sin fallos y la repetición crítica, 9; estas nueve pertenecen a la misma suite. Las pruebas móviles automatizadas informan 29 aprobadas, con HTTP simulado en los casos de contrato. El recorrido manual en Redmi sí usó API y PostgreSQL reales.

Las nueve tablas conservan conteos y huellas antes/después de V4, excluyendo password_hash por la corrección prevista de contraseñas demo. El segundo arranque no repite migraciones. La prueba negativa JPA detecta la columna ausente y conserva el esquema.

Pendientes: filtros combinados/búsqueda y límites de fecha en reporte/CSV (CP-15); recepción con vehículo inactivo (CP-17). También falta la aceptación del dashboard integrado, comprobar el UUID móvil en web/reporte y leer el QR con otra cámara. La versión web usada tenía datos de demostración; aquí no se verifica el estado actual de main.

## Preparación de esta entrega

Se conservaron los archivos originales de evidencia, salvo la ocultación de una contraseña temporal generada por Spring en backend-error-conexion.log y la actualización de version-probada.txt. Se añadieron las capturas de rechazo y esta matriz. Algunos textos capturados presentan caracteres mal codificados por la consola; se conservan para no reinterpretar los registros.

Subir el contenido de docs/pruebas a la rama de Elías, conservando las rutas. El ZIP no ejecuta pruebas ni modifica código, bases de datos o configuración. No contiene la carpeta .local.
