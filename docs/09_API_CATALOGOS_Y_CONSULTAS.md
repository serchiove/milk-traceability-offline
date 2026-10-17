# APIs de catálogos y consulta de lotes

Implementadas el 16 de octubre de 2026. Complementan el login y POST /api/lotes.

## Autenticación y alcance

Todas las rutas de este documento requieren `Authorization: Bearer TOKEN` y rol OPERARIO o JEFATURA. POST /api/lotes sigue reservado a OPERARIO.

El centro se toma de la identidad autenticada. No existe un filtro para consultar centros ajenos: enviar `idCentro` en la URL no cambia el alcance. Tanto operario como jefatura pueden consultar las recepciones de su centro, incluidas las de otros operarios de ese mismo centro.

Proveedores y vehículos son catálogos globales en el modelo actual; no tienen asociación a un centro. Se exponen únicamente registros activos. La vigencia documental del proveedor se informa en `estadoCert`, no se presenta como certificación oficial.

## Rutas

| Método y ruta | Resultado |
|---|---|
| GET /api/catalogos/proveedores | Proveedores activos: id, tipoDocumento, numeroDocumento, razonSocial, estadoCert. |
| GET /api/catalogos/vehiculos | Vehículos activos: id, placa, capacidadLitros. |
| GET /api/catalogos/centro | Centro activo asignado al usuario: id, nombre, region, capacidadLitros. |
| GET /api/lotes | Recepciones del centro del usuario con filtros y paginación. |
| GET /api/lotes/{idLote} | Detalle de una recepción por UUID. |
| GET /api/lotes/por-qr?codigo=ACOPIO:UUID | Detalle del lote cuyo código QR fue realmente asignado. |

La consulta por QR resuelve el contenido del código: no genera una imagen ni activa la cámara. Un lote rechazado, sin QR asignado, no se puede consultar por un código inventado; sí puede consultarse por su UUID autorizado.

## Paginación

Proveedores, vehículos y lotes aceptan `pagina` (desde 0) y `tamano` (1 a 100, predeterminado 25). Página máxima: 1000000. Una página fuera de los resultados devuelve elementos vacíos, conservando el total.

```json
{"elementos": [], "total": 0, "pagina": 0, "tamano": 25}
```

La búsqueda `buscar` acepta hasta 180 caracteres y no distingue mayúsculas. En proveedores busca razón social/documento; en vehículos, placa; en lotes, proveedor/placa/UUID. Es texto literal, no un patrón SQL. No se implementa normalización de tildes.

Orden estable: nombre e ID para proveedores, placa e ID para vehículos, fecha descendente y UUID descendente para lotes.

## Filtros de lotes

- `estado`: PENDIENTE, APROBADO o RECHAZADO; si se omite incluye todos.
- `desde` y `hasta`: fechas ISO YYYY-MM-DD, ambas inclusivas. Se filtra la fecha de captura (`fecha_hora`), no la de recepción central.
- Los días se interpretan en America/Lima, configurable mediante `app.consultas.zona`.
- Pueden combinarse estado, fechas, texto y paginación.

Ejemplo:

```text
GET /api/lotes?estado=APROBADO&desde=2026-10-01&hasta=2026-10-16&pagina=0&tamano=25
```

El detalle incluye IDs y nombres de origen, operario y centro; fecha de captura/recepción; volumen, temperatura, acidez y densidad; estado, motivo, versión y fecha de evaluación; código QR; tanque y fecha de asignación cuando existan. No expone contraseñas, tokens ni huella de la petición.

## Errores

- 400: filtros, paginación, fechas o UUID inválidos; QR mal formado o parámetro requerido ausente.
- 401: sin autenticación válida, cuenta/centro inactivos o token revocado/vencido.
- 403: rol sin autorización.
- 404: recurso inexistente o perteneciente a otro centro; no distingue ambos casos.

## Verificación

`mvn verify` completó 19 pruebas sin fallos y generó el JAR. Las pruebas utilizan HTTP real y PostgreSQL en la base aislada acopio_revision_20261016. Se comprobaron autenticación, catálogos activos, aislamiento por centro, consulta por UUID/QR, paginación, fechas en límites de día, validación de filtros y los flujos anteriores de recepción/idempotencia/rollback.

Esta ampliación no modificó migraciones ni registros de acopio_dev. Posteriormente se integraron las consultas al móvil y se implementaron tanques, indicadores, incidencias y reportes. Estado actualizado en `12_ALINEACION_INFORME_OFICIAL.md`; administración de proveedores y vehículos en `13_ADMINISTRACION_CATALOGOS.md`. La integración del dashboard existente queda a cargo de su responsable.
