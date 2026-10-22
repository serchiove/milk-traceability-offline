# Matriz de casos de prueba

**Responsable:** Elías

**Módulo:** Base de datos y pruebas

**Proyecto:** Sistema de Acopio y Trazabilidad Láctea

## Indicaciones de ejecución

- Ejecutar con datos ficticios y registrar el commit probado.
- Usar `acopio_test` para pruebas automáticas o destructivas.
- En pruebas móviles mantener Metro disponible y detener únicamente el backend para simular falta de conexión.
- El envío de un registro pendiente es manual.
- No marcar un caso como aprobado sin resultado y evidencia.
- No guardar contraseñas, tokens ni secretos en capturas o archivos.

## Casos preparados

| ID | Tipo | Caso y entrada principal | Acción | Resultado esperado | Resultado obtenido | Evidencia | Fecha / commit | Estado |
|---|---|---|---|---|---|---|---|---|
| CP-01 | Integración | Cuenta OPERARIO activa y contraseña válida | Iniciar sesión | Respuesta 200, token y datos del usuario/centro; la contraseña no aparece en la respuesta | El contrato móvil de login fue aprobado con HTTP simulado; falta comprobar el backend real | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-02 | Integración | Cuenta activa y contraseña incorrecta | Iniciar sesión | Respuesta 401 sin crear sesión | El rechazo de credenciales incorrectas fue aprobado con HTTP simulado; falta comprobar el backend real | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-03 | Seguridad | Token de un usuario de un centro y lote de otro centro | Consultar el lote ajeno | Respuesta 404; el parámetro `idCentro` no permite cambiar el centro del JWT | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-04 | Integración | 100 L, 4 °C, 16 °D y 1.0300 g/mL con catálogo activo | Registrar recepción | Respuesta 201; lote APROBADO, reglas DEMO-1, QR y una sola fila de calidad | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-05 | Calidad | Temperatura físicamente válida de 15 °C | Registrar recepción | La recepción se conserva como RECHAZADA con motivo e incidencia; no se genera QR | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-06 | Calidad/UI | Acidez numérica de 22 °D y etiqueta visible en °D | Registrar recepción y revisar la pantalla | La unidad mostrada es °D; la recepción se conserva como RECHAZADA. La API no puede detectar si el usuario pensó en porcentaje | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-07 | Calidad | Densidad físicamente válida de 1.0200 g/mL | Registrar recepción | La recepción se conserva como RECHAZADA con motivo e incidencia; no se genera QR | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-08 | Móvil | Datos válidos, sesión vigente y backend no disponible | Guardar el lote y cerrar/reabrir la app | El lote permanece en SQLite con el mismo UUID y estado pendiente de envío | SQLite conservó el registro, la edición y el UUID después de recargar; falta repetir en celular | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-09 | Móvil/Integración | Lote local pendiente y backend nuevamente disponible | Pulsar enviar desde el detalle | El envío es manual; el servidor recibe el mismo UUID y la app cambia el estado local a recibido | El flujo móvil mantuvo el UUID y confirmó la respuesta simulada; falta envío al backend real | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-10 | Integración | Mismo UUID con contenido diferente | Enviar por segunda vez | Respuesta 409; el lote original no cambia y no se crea duplicado | El móvil conservó UUID/huella y no marcó como recibido una respuesta inválida; falta comprobar el 409 real | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-11 | Integración | Temperatura de -274 °C o volumen con más de dos decimales, en solicitudes separadas | Intentar registrar cada recepción | Respuesta 400; ninguna solicitud crea filas en lote_leche ni registro_calidad | Las validaciones locales tienen pruebas automatizadas; falta comprobar el rechazo y la ausencia de filas en el backend real | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-12 | Integración | Mismo UUID, misma huella y mismo contenido | Reenviar la recepción | Respuesta 200 con `idempotente=true`; continúa existiendo un solo lote y un registro de calidad | El móvil mantuvo UUID, contenido y huella durante el reintento; falta comprobar la respuesta real 200 | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-13 | Integración/Seguridad | Lote aprobado y tanque perteneciente a otro centro | Intentar asignar el tanque | Respuesta 404; no se asigna tanque ni se modifica su ocupación | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-14 | Integración/BD | Lote aprobado de 120 L y tanque con solo 100 L disponibles | Intentar asignar el tanque | Respuesta 409; el lote queda sin destino y el volumen del tanque no cambia | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-15 | Integración | Token JEFATURA y filtros fecha/estado/búsqueda | Consultar reporte y CSV | Solo aparecen registros del centro del JWT; fechas inclusivas según America/Lima y CSV con los mismos filtros | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-16 | Seguridad | Token vencido | Consultar o registrar | Respuesta 401; no se procesa la operación | El móvil rechazó una sesión local vencida y distinguió el error HTTP simulado; backend real pendiente | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-17 | Integración/BD | Proveedor o vehículo inactivo | Registrar una nueva recepción | Respuesta 400 y ninguna fila nueva; una recepción antigua mantiene su trazabilidad | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-18 | Móvil/Seguridad | Dos operarios en el mismo dispositivo con borradores locales distintos | Cambiar de sesión y consultar borradores | Cada operario ve únicamente sus datos locales; no se mezclan ediciones | La prueba SQLite confirmó que las ediciones quedan aisladas por operario | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | APROBADO AUTOMATIZADO |
| CP-19 | Integración/BD | Lote aprobado ya asignado a un tanque | Repetir la misma asignación | Respuesta 200 con `idempotente=true`; la ocupación del tanque aumenta una sola vez | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-20 | Concurrencia/BD | Dos lotes aprobados de 80 L cada uno y un tanque vacío, disponible, del mismo centro y con capacidad de 100 L | Enviar ambas asignaciones al mismo tiempo | Una asignación responde 201 y la otra 409; el tanque queda con 80 L ocupados y un solo lote asignado | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-21 | Integración/BD | Recepción válida y una restricción temporal de prueba que impide guardar su registro de calidad en una base aislada | Ejecutar la prueba de fallo de persistencia y retirar la restricción al terminar | Respuesta 400 por la restricción de prueba; la transacción se revierte y no quedan filas del UUID probado en lote_leche ni registro_calidad | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-22 | Instalación/BD | Base PostgreSQL nueva, vacía y exclusiva para pruebas | Iniciar el backend con Flyway y revisar su historial | Se aplican V1, V2, V3 y V4 en orden y sin errores; el backend inicia con ddl-auto=validate | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-23 | Actualización/BD | Base aislada con V1, V2 y V3 aplicadas y datos ficticios registrados | Iniciar la versión que incluye V4 y comparar los datos antes y después | V4 se aplica correctamente; se conservan los registros e identificadores y se actualizan los hashes previstos; un segundo inicio no vuelve a aplicar las migraciones | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-24 | Persistencia JPA | Base aislada con las cuatro migraciones aplicadas | Comprobar el mapeo de las 9 entidades y el arranque con ddl-auto=validate; repetir con una columna requerida ausente en otra base desechable | Con el esquema correcto el backend inicia; con la columna ausente falla la validación y Hibernate no crea ni modifica el esquema | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |

## Criterios de cierre

- Cada caso tiene fecha, commit, entrada, resultado obtenido y enlace o nombre de evidencia.
- Los resultados automáticos se distinguen de las pruebas manuales.
- Las pruebas manuales conservan UUID y muestran el mismo dato en móvil, API y PostgreSQL.
- Los casos bloqueados indican la causa; no se registran como aprobados.
- La aceptación web permanece bloqueada hasta que el dashboard deje de usar datos ficticios y consuma la API.
