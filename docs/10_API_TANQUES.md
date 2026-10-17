# Consulta y asignación de tanques

Implementado el 16 de octubre de 2026. No requiere nuevas migraciones: utiliza tablas y triggers del modelo original.

## Consulta

`GET /api/tanques` requiere token de OPERARIO o JEFATURA. Devuelve únicamente tanques del centro autenticado.

Parámetros: `pagina` (0 por defecto), `tamano` (25 por defecto, máximo 100), `disponibles` (false por defecto). `disponibles=true` devuelve únicamente tanques con estado DISPONIBLE y saldo positivo; el saldo debe compararse con el volumen del lote antes de elegirlo. La asignación vuelve a comprobarlo dentro de la transacción.

Formato paginado: elementos, total, pagina y tamano. Cada tanque contiene id, codigo, estado, capacidadLitros, volumenAsignadoLitros y disponibleLitros.

El volumen asignado es la reserva controlada por la base, no una medición física ni una lectura de sensores. El listado puede cambiar al producirse otras asignaciones.

## Asignación

`POST /api/lotes/{UUID}/asignacion-tanque`, con token de OPERARIO y cuerpo:

```json
{"idTanque": 1}
```

El ID es ilustrativo. El servidor toma el usuario y el centro del token. Requiere lote APROBADO, tanque del mismo centro, estado DISPONIBLE y saldo suficiente. No hay asignación parcial: un lote tiene un solo tanque.

Respuesta 201 para la primera asignación; 200 con idempotente=true para un reintento al mismo tanque. Incluye idLote, idTanque, codigo, volumenLitros, asignadoEn e idUsuarioAsigna. El reintento no cambia la fecha, responsable ni volumen reservado del registro original, aunque posteriormente el tanque esté lleno o en mantenimiento.

Errores:

- 400: cuerpo/UUID/ID inválido o paginación incorrecta.
- 401: autenticación ausente, inválida o vencida.
- 403: rol sin permiso; JEFATURA puede consultar pero no asignar.
- 404: lote o tanque inexistente o de otro centro.
- 409: lote sin aprobación, tanque no disponible, capacidad insuficiente o intento de reasignar a otro tanque.

## Concurrencia y trazabilidad

El servicio bloquea primero la fila del lote y después la del tanque, siempre en ese orden. La transacción conserva ambas hasta confirmar o revertir. El trigger original reserva el volumen; el servicio no incrementa el contador por separado. Esto evita doble reserva en reintentos y sobreasignación cuando llegan solicitudes simultáneas.

No se permiten reasignaciones, vaciados, mezclas ni trasvases. La consulta de detalle del lote refleja el tanque y la fecha de asignación.

## Verificación

`mvn verify`: 24 pruebas aprobadas y JAR generado, utilizando una base PostgreSQL aislada. Incluye asignación válida, reintentos, lotes rechazados, mantenimiento, capacidad insuficiente, aislamiento entre centros, permisos y dos asignaciones concurrentes que compiten por capacidad insuficiente para ambas.

Actualización: las pantallas móviles de calidad y tanques ya consumen estas rutas. Los indicadores, incidencias y reportes del backend también están implementados; consultar `12_ALINEACION_INFORME_OFICIAL.md`. La integración del dashboard existente corresponde a su responsable.
