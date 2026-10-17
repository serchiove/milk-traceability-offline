# Correcciones del backend — 16 de octubre de 2026

## Cambios

- Consultas de autenticación con esquema `acopio`, nombre del centro y comprobación de centro activo.
- Login compatible con la estructura esperada por el móvil: `accessToken` y `usuario` con `id`, `idCentro`, `nombre`, `centro`, `rol`.
- Identidad autenticada tipada en el controlador. No se vuelve a cortar ni interpretar manualmente el encabezado Authorization.
- Recepción reservada a OPERARIO; endpoints no implementados denegados por defecto.
- Tokens contrastados con estado actual de cuenta, rol y centro. Respuestas 401/403 JSON.
- Clave JWT externa; generación local de una clave aleatoria fuera de Git mediante Dev.ps1. Debe dejar de utilizarse la antigua clave publicada.
- Validación de IDs positivos, precisión decimal y límites numéricos del modelo antes de persistir. Una medición válida fuera de los rangos de calidad conserva un lote rechazado, no se elimina.
- Referencias activas exigidas para nuevas recepciones. Reenvíos idénticos históricos siguen confirmándose sin duplicados aunque luego se desactive un catálogo.
- Errores de datos/referencias devuelven 400 sin mensajes internos SQL; UUID con contenido diferente devuelve 409.
- SHA-256 calculado exclusivamente por servidor con números normalizados e instante UTC.
- Rangos configurables por entorno (`CALIDAD_TEMPERATURA_MIN/MAX`, `CALIDAD_ACIDEZ_MIN/MAX`, `CALIDAD_DENSIDAD_MIN/MAX`) y versión `CALIDAD_VERSION`.
- La versión predeterminada es DEMO-1. Los rangos son de desarrollo, no una afirmación de cumplimiento de una NTP ni criterios oficiales de Gloria. Cualquier cambio de rangos debe acompañarse de una versión nueva. No se reevalúan lotes finalizados.
- V4 corrige el hash incorrecto de las dos cuentas de desarrollo de V3, únicamente si conservan ese hash. V1, V2 y V3 no se modifican. Contraseña ficticia de esas cuentas: `123456`; no usar fuera de desarrollo.

## Recepción

`POST /api/lotes`, con token de operario:

```json
{
  "idLote": "550e8400-e29b-41d4-a716-446655440004",
  "idProveedor": 1,
  "idVehiculo": 1,
  "volumenLitros": 120.50,
  "fechaHora": "2026-10-16T08:30:00-05:00",
  "mediciones": {
    "temperaturaC": 4.5,
    "acidezDornic": 16,
    "densidadGml": 1.0300
  }
}
```

Los IDs son ilustrativos. Deben existir y estar activos. No enviar `huellaSolicitud`, usuario ni centro en la petición. Usar el mismo UUID, fecha y contenido en cada reintento.

Respuesta: 201 para nuevo lote, 200 con `idempotente=true` para reintento idéntico, 409 para UUID reutilizado con contenido distinto. Incluye estadoEvaluacion, versionReglas, motivo, codigoQr, huellaSolicitud y fechas. Lote y mediciones se escriben en una transacción; los triggers existentes generan QR o incidencia al finalizar la evaluación.

## Verificación

Se ejecutó `mvn verify`: 13 pruebas aprobadas y JAR generado.
La prueba de flujo usa HTTP real, Spring Security y PostgreSQL en `acopio_revision_20261016`, separada de `acopio_dev`.
Cubre login y contrato, credenciales incorrectas, cuenta/centro inactivos, roles, tokens inválidos/vencidos, aprobación, rechazo, incidencia única, idempotencia, conflicto, referencias inactivas, precisión, rollback y solicitudes concurrentes.

`Probar_Proyecto.cmd` prepara `acopio_test` para pruebas; la configuración de test usa `TEST_DB_NAME` (por defecto acopio_test), independientemente de DB_NAME. Para ejecutar Maven directamente debe existir la base de pruebas y definirse DB_PASSWORD.

El backend actualizado se empaquetó, pero estas pruebas no aplicaron V3/V4 sobre acopio_dev. El próximo inicio del backend con Iniciar.cmd ejecutará las migraciones pendientes de desarrollo mediante Flyway. No se ha hecho commit ni push de las correcciones.

## Pendiente de integración

La ampliación de catálogos y consulta central de lotes se encuentra documentada en `09_API_CATALOGOS_Y_CONSULTAS.md`. La asignación de tanques está documentada en `10_API_TANQUES.md`. Indicadores/reportes y envío manual móvil ya están implementados; ver `12_ALINEACION_INFORME_OFICIAL.md`. El móvil no envía borradores automáticamente. Administración de proveedores y vehículos: `13_ADMINISTRACION_CATALOGOS.md`.
