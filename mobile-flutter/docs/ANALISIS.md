# Arquitectura móvil y contrato de integración

La app móvil de ACOPIO está desarrollada en Flutter y Dart. Consulta la API Spring Boot compartida con el dashboard y conserva sus datos de campo en SQLite.

## Componentes

- `core/providers.dart`: dependencias y ciclo de vida de los ViewModels.
- `repositories/local_repository.dart`: registros, ediciones y solicitudes de envío en SQLite.
- `services/session_service.dart`: autenticación y actualización completa de catálogos.
- `services/sync_service.dart`: envío explícito, huella e idempotencia.
- `services/central_service.dart`: calidad, trazabilidad, consulta QR y asignación de tanque.
- `viewmodels/app_viewmodels.dart`: estado y coordinación de captura, sesión y consultas.
- `views/`: acceso, Inicio, Registros, Perfil, captura, detalle, catálogos, conexión y Central.
- `test/`: validaciones, almacenamiento, servicios, conexión e interfaz.

## Endpoints consumidos

| Método | Ruta | Uso |
|---|---|---|
| POST | `/api/auth/login` | `{email,password}` → token y usuario OPERARIO |
| GET | `/api/catalogos/proveedores?buscar=&pagina=0&tamano=25` | Proveedores activos |
| GET | `/api/catalogos/vehiculos?buscar=&pagina=0&tamano=25` | Vehículos activos |
| GET | `/api/catalogos/centro` | Centro autorizado por sesión |
| GET | `/api/estado` | Comprobación de conexión |
| POST | `/api/lotes` | Captura e interpretación del resultado |
| GET | `/api/lotes?pagina=0&tamano=25` | Recepciones del centro |
| GET | `/api/lotes?pagina=0&tamano=25&estado=APROBADO` | Candidatos a destino |
| GET | `/api/lotes/{uuid}` | Detalle, mediciones y estado |
| GET | `/api/lotes/por-qr?codigo=ACOPIO%3A{uuid}` | Consulta QR |
| GET | `/api/tanques?disponibles=true&pagina=0&tamano=25` | Destinos disponibles |
| POST | `/api/lotes/{uuid}/asignacion-tanque` | `{idTanque}` |

El reporte JEFATURA se consulta solo en la prueba de contrato para comprobar coherencia con el dashboard. No se ofrece acceso JEFATURA desde la aplicación móvil.

## Recepción y huella

```json
{
  "idLote": "UUID-v4-generado-una-sola-vez",
  "idProveedor": 1,
  "idVehiculo": 1,
  "fechaHora": "2026-10-24T12:00:00.120Z",
  "volumenLitros": 120.5,
  "mediciones": {"temperaturaC": 4.5, "acidezDornic": 16, "densidadGml": 1.03},
  "huellaSolicitud": "SHA256-en-hexadecimal"
}
```

La cadena canónica une mediante `|`: UUID, proveedor, vehículo, usuario, centro, instante UTC, volumen, temperatura, acidez y densidad. Se quitan ceros decimales no significativos; `.000Z` se convierte en `Z`, y el resto de milisegundos se conserva. Usuario y centro no se envían como autoridad en el JSON: el backend los obtiene de la sesión JWT y los incluye en su huella.

La copia pendiente se prepara antes de HTTP. Un timeout conserva ese cuerpo. HTTP 200/201 no basta: se verifica UUID, estado, fecha, marca de idempotencia y campos opcionales antes de confirmar localmente. Rechazo de calidad es confirmación, no error de transporte. No existe sincronización automática ni evaluación de calidad offline.

## Límites conservados

Texto de origen obligatorio, máximo 180 caracteres. Volumen `>0` y hasta `9999999999.99`; temperatura entre `-273.15` y `9999.99`; acidez entre `0` y `9999.99`; densidad `>0` y hasta `999.9999`. Dos decimales excepto densidad (cuatro). Coma o punto decimal; sin separadores de miles ni exponentes. Estos límites numéricos no son reglas de aprobación de calidad.

Tanques: solo lote aprobado, mismo centro, disponibilidad y capacidad suficientes, una asignación. El servidor conserva la decisión final. La creación de centros, tanques y usuarios corresponde a una siguiente etapa.
