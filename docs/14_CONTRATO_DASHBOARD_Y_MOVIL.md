# Integración del dashboard de Fernando y la app móvil

Revisión: 17/10/2026. Rama remota Fernando: `570d6673398f5b62aaf1d211859c6eac375b5e1c`.

## Estado comprobado

El dashboard de esa revisión solo llama a GET `/api/estado`. Su `signIn` valida `jefatura.demo` localmente, `DEMO_LOTS` alimenta las pantallas, los indicadores son constantes y el CSV se genera con datos ficticios. No hay un contrato HTTP funcional que conservar para esas pantallas. El backend proporciona las rutas descritas aquí; Fernando debe sustituir esas fuentes locales por peticiones autenticadas. No se modificó ni mezcló su rama.

La app móvil ya usa login, catálogos, envío de lotes, consultas y asignación. Se mantienen sus rutas y formatos. Los campos nuevos de reportes son aditivos y exclusivos de consultas JEFATURA.

## Conexión y acceso

Backend de desarrollo: `http://127.0.0.1:18080`. El `vite.config.js` de Fernando ya redirige `/api` a ese puerto. Usar rutas relativas desde el dashboard; ese proxy funciona en desarrollo, no se incorpora automáticamente a un despliegue estático.

Si el navegador llama directamente al backend desde otro origen, CORS permite por defecto `http://localhost:5173` y `http://127.0.0.1:5173`. Configurar `CORS_ALLOWED_ORIGINS` con una lista separada por comas de orígenes exactos para un despliegue. No usar `*`. Se permiten Authorization y Content-Type; el navegador puede leer Content-Disposition del CSV. CORS no reemplaza JWT ni permisos.

POST `/api/auth/login`, JSON `{ "email": "jefatura@gloria.com.pe", "password": "123456" }` (cuenta ficticia de desarrollo). Respuesta:

```json
{"accessToken":"<JWT>","usuario":{"id":1,"nombre":"Jefatura","rol":"JEFATURA","idCentro":1,"centro":"Nombre del centro"}}
```

IDs y nombres son ilustrativos: usar los recibidos. Para móvil: `operario@gloria.com.pe` / `123456`, rol OPERARIO. El dashboard debe aceptar JEFATURA, no `jefatura.demo` con cualquier contraseña. Todas las consultas privadas llevan `Authorization: Bearer <accessToken>`. Nunca incluir el token en la URL. Ante 401 volver al login, ante 403 mostrar falta de permisos; nunca sustituir un error por datos demo. No hay refresh token; cerrar sesión debe descartar el token del cliente.

## Rutas por pantalla

| Pantalla | Petición | Datos |
|---|---|---|
| Resumen | GET /api/reportes | Volúmenes, cantidades, tasas e incidencias |
| Ocupación | GET /api/tanques?pagina=0&tamano=25 | `elementos`, `total`, `pagina`, `tamano` |
| Incidencias | GET /api/reportes con filtros | `incidencias`: id, idLote, tipo, descripcion, fecha; enlazar idLote con registros |
| Tabla de lotes | GET /api/lotes?pagina=0&tamano=25 | Lista paginada |
| Detalle | GET /api/lotes/{UUID} | Identidad, mediciones, evaluación, QR y tanque |
| Buscar QR | GET /api/lotes/por-qr?codigo=ACOPIO%3A{UUID} | Detalle del lote aprobado |
| Vista previa de reporte | GET /api/reportes | `registros` filtrados, máximo 10 000 |
| Descargar reporte | GET /api/reportes/csv | CSV UTF-8; descargar como blob, usando el mismo JWT y filtros |
| Centro permitido | GET /api/catalogos/centro | Centro asociado a la sesión |
| Administración | /api/administracion/catalogos | Contrato en 13_ADMINISTRACION_CATALOGOS.md |

Filtros de lotes y reportes: `desde=YYYY-MM-DD`, `hasta=YYYY-MM-DD`, `estado=APROBADO|RECHAZADO|PENDIENTE`, `buscar=texto`. Omitir estado para Todos. Fechas inclusivas sobre fecha de captura en America/Lima. Para Hoy/7 días/30 días calcular ambos extremos en esa zona. Búsqueda por proveedor, placa o UUID; no por nombre de centro. Listas paginadas: máximo 100 por página, recorrer páginas si se requiere toda la colección.

El centro se obtiene del JWT: **Todos significa todos los registros del centro autorizado**, no todos los centros. Eliminar las opciones ficticias CA-01/CA-02; no existe autorización multicentro. Nunca enviar un idCentro esperando ampliar acceso. Ocupación de tanques es actual, no histórica según el filtro de fechas.

Indicadores de reporte:

- `volumenLitros`: total recibido, incluidos pendientes.
- `volumenAprobadoLitros`, `volumenRechazadoLitros`, `volumenPendienteLitros`: litros por estado.
- `porcentajeVolumenAprobado`, `porcentajeVolumenRechazado`: porcentajes sobre litros totales, adecuados para las tarjetas actuales de Fernando. Redondear únicamente al mostrar.
- `total`, `aprobados`, `rechazados`, `pendientes`: cantidades de lotes.
- `tasaAprobacion`: porcentaje por cantidad de lotes, NO por litros.
- `porcentajeLotesConIncidencia`: lotes con al menos una incidencia / total.

Con cero registros las tasas son cero. No sumar solo la primera página de lotes para obtener totales. Un reporte superior a 10 000 registros requiere acotar filtros. La exportación vuelve a consultar la base, así que puede incorporar datos confirmados después de la vista previa.

## Correspondencia con DEMO_LOTS

| Campo de Fernando | Campo real del lote |
|---|---|
| id | idLote (UUID, no L-001) |
| supplier | proveedor |
| center | centro |
| liters | volumenLitros |
| quality | estadoEvaluacion |
| tank / destination | tanque (null si no asignado) |
| vehicle | placa |
| operator | operario |
| date | fechaHora (ISO con zona) |
| temperature | temperaturaC |
| acidity | acidezDornic |
| density | densidadGml (mostrar 4 decimales, no toFixed(2)) |
| rule | motivo y versionReglas |

QR: renderizar `codigoQr` solo si existe y el estado es APROBADO; no generar `ACOPIO-DEMO-*`. Historial: `recibidoEn`, `fechaEvaluacion` y `asignadoEn` son eventos reales; omitir los ausentes y no inventar fechas. No es una auditoría completa.

Tanque: `id`, `codigo`, `estado`, `capacidadLitros`, `volumenAsignadoLitros`, `disponibleLitros`. Barra = volumenAsignadoLitros / capacidadLitros. JEFATURA solo consulta; la asignación corresponde a OPERARIO desde el móvil.

## Ejemplo de consumo sin alterar el diseño

```javascript
async function api(ruta, token) {
  const response = await fetch(ruta, {
    headers: { Authorization: `Bearer ${token}` },
    signal: AbortSignal.timeout(15000)
  });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.json();
}
const filtros = new URLSearchParams({ desde: '2026-10-01', hasta: '2026-10-31' });
const reporte = await api(`/api/reportes?${filtros}`, accessToken);
const litrosRechazados = reporte.volumenRechazadoLitros;
const lotes = reporte.registros;
```

Agregar estados de carga, error y vacío. La app móvil conserva SQLite y reintentos con UUID/huella; el dashboard consulta lo recibido por el servidor, por lo que un borrador no enviado no aparecerá allí.

## Verificación y límites

Pruebas del backend con HTTP y PostgreSQL aislado cubren roles, centros, recepción/idempotencia, evaluación, QR, capacidad de tanques, catálogos, reportes/CSV y CORS. Esto verifica las APIs, no la integración visual del dashboard: sigue pendiente que Fernando conecte su interfaz a estas rutas. Para producción faltan configuración HTTPS, credenciales propias y verificación de despliegue.
