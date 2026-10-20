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
| CP-11 | Integración/BD | Entrada inválida o fallo forzado de base: -274 °C, exceso de decimales o restricción de prueba | Intentar registrar | Respuesta 400 y rollback completo: cero filas parciales en lote y calidad | Validaciones y rollback local aprobados; rollback PostgreSQL pendiente | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-12 | Integración | Mismo UUID, misma huella y mismo contenido | Reenviar la recepción | Respuesta 200 con `idempotente=true`; continúa existiendo un solo lote y un registro de calidad | El móvil mantuvo UUID, contenido y huella durante el reintento; falta comprobar la respuesta real 200 | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-13 | Integración/Seguridad | Lote aprobado y tanque perteneciente a otro centro | Intentar asignar el tanque | Respuesta 404; no se asigna tanque ni se modifica su ocupación | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-14 | Integración/BD | Lote aprobado de 120 L y tanque con solo 100 L disponibles | Intentar asignar el tanque | Respuesta 409; el lote queda sin destino y el volumen del tanque no cambia | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-15 | Integración | Token JEFATURA y filtros fecha/estado/búsqueda | Consultar reporte y CSV | Solo aparecen registros del centro del JWT; fechas inclusivas según America/Lima y CSV con los mismos filtros | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-16 | Seguridad | Token vencido | Consultar o registrar | Respuesta 401; no se procesa la operación | El móvil rechazó una sesión local vencida y distinguió el error HTTP simulado; backend real pendiente | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | PARCIAL |
| CP-17 | Integración/BD | Proveedor o vehículo inactivo | Registrar una nueva recepción | Respuesta 400 y ninguna fila nueva; una recepción antigua mantiene su trazabilidad | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-18 | Móvil/Seguridad | Dos operarios en el mismo dispositivo con borradores locales distintos | Cambiar de sesión y consultar borradores | Cada operario ve únicamente sus datos locales; no se mezclan ediciones | La prueba SQLite confirmó que las ediciones quedan aisladas por operario | [Ejecución automatizada](EJECUCION_AUTOMATIZADA_2026-10-20.md) | 20/10/2026 - `a59788d` | APROBADO AUTOMATIZADO |
| CP-19 | Integración/BD | Lote aprobado ya asignado a un tanque | Repetir la misma asignación | Respuesta 200 con `idempotente=true`; la ocupación del tanque aumenta una sola vez | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |
| CP-20 | Concurrencia/BD | Dos lotes de 80 L compiten por un tanque con 100 L disponibles | Enviar ambas asignaciones al mismo tiempo | Una asignación responde 201 y la otra 409; ocupación final 80 L y un solo lote asignado | Pendiente de ejecución | Pendiente | Pendiente | PENDIENTE |

## Criterios de cierre

- Cada caso tiene fecha, commit, entrada, resultado obtenido y enlace o nombre de evidencia.
- Los resultados automáticos se distinguen de las pruebas manuales.
- Las pruebas manuales conservan UUID y muestran el mismo dato en móvil, API y PostgreSQL.
- Los casos bloqueados indican la causa; no se registran como aprobados.
- La aceptación web permanece bloqueada hasta que el dashboard deje de usar datos ficticios y consuma la API.
