# Organización de clases de la aplicación Flutter

Esta guía explica cómo se distribuye el código móvil de ACOPIO dentro de `mobile-flutter/lib` y dónde buscar cuando necesitamos entender o modificar una función. La aplicación separa responsabilidades: las vistas presentan la interfaz, los ViewModels coordinan el estado, y los servicios y el repositorio realizan las operaciones de red y almacenamiento.

## Estructura general

```text
lib/
├── main.dart
├── core/
├── models/
├── repositories/
├── services/
├── viewmodels/
└── views/
    ├── capture/
    └── components/
```

## Inicio y dependencias

### `main.dart`

Es el punto de entrada de Flutter. Inicializa la aplicación dentro de `ProviderScope`, configura el tema y el idioma español, y muestra `AuthGate`. Este control consulta la autenticación: durante la restauración presenta una espera; si no hay sesión abre `LoginView`, y si la sesión es válida abre `ShellView`.

### `core/providers.dart`

Declara los providers de Riverpod y conecta las dependencias. Crea el cliente HTTP y el repositorio local, y construye los servicios y ViewModels que los necesitan. Los providers permiten compartir estos objetos entre pantallas.

## Configuración común: `core/`

- **`config.dart`**: URL de la API, rutas y valores de configuración.
- **`providers.dart`**: dependencias y ciclo de vida de servicios y ViewModels.
- **`theme.dart`**: tema general de Material y estilos compartidos.
- **`app_colors.dart` y `design_tokens.dart`**: colores y valores visuales reutilizables.
- **`formatters.dart`**: presentación uniforme de fechas y mediciones.

Para ajustar un color global revisamos primero `app_colors.dart` y `theme.dart`. Para cambiar un botón compartido revisamos `PrimaryButton`; los botones con estilo propio pueden estar definidos en su vista.

## Modelos: `models/`

Representan los datos de la aplicación y las conversiones entre la información recibida y los objetos de Dart.

- **`session.dart`**: sesión, token, centro y vigencia.
- **`catalog.dart`**: elementos de catálogos y resultados paginados.
- **`lot.dart`**: recepción, solicitud de envío y resultado de sincronización.
- **`sync_summary.dart`**: resumen de envíos.

Los modelos describen información; no dibujan pantallas.

## Almacenamiento local: `repositories/`

- **`local_repository.dart` — `LocalRepository`**: abre y consulta SQLite. Conserva recepciones, solicitudes pendientes, resultados, borradores y configuración local asociados al usuario y centro. Registra localmente la confirmación cuando el servidor acepta un envío.

Guardar un registro en SQLite lo conserva en el teléfono; no significa que el servidor ya lo haya recibido.

## Comunicación: `services/`

Los servicios realizan operaciones externas y coordinan sus pasos; no presentan widgets.

- **`api_client.dart` — `ApiClient`**: envía solicitudes HTTP, adjunta el token cuando corresponde y traduce respuestas de error.
- **`session_service.dart` — `SessionService`**: inicia, restaura y cierra la sesión; consulta y actualiza catálogos y guarda de forma segura la información de acceso.
- **`sync_service.dart` — `SyncService`**: prepara y envía una recepción pendiente. Reutiliza el identificador de solicitud durante reintentos y registra el resultado confirmado.
- **`central_service.dart` — `CentralService`**: consulta lotes, detalles y tanques del centro, y solicita asignaciones.

## Estado y coordinación: `viewmodels/`

Los ViewModels mantienen el estado que necesita una pantalla y coordinan acciones con servicios o almacenamiento. Notifican a la interfaz cuando ese estado cambia.

- **`view_model.dart` — `ViewModel`**: estado común de carga, errores y notificación de cambios.
- **`auth_view_model.dart` — `AuthViewModel`**: restaura la sesión y procesa el inicio y cierre de sesión.
- **`workspace_view_model.dart` — `WorkspaceViewModel`**: coordina sesión de trabajo, catálogos descargados, formularios, borradores, recepciones locales, búsquedas y envíos pendientes.
- **`central_view_model.dart` — `CentralViewModel`**: carga páginas de lotes, consulta detalles y tanques, y coordina asignaciones.
- **`catalog_view_model.dart` — `CatalogViewModel`**: consulta y filtra páginas de catálogos.
- **`connection_viewmodel.dart` — `ConnectionViewModel`**: comprueba la disponibilidad del servidor y conserva el resultado y la hora de consulta.
- **`app_viewmodels.dart`**: reúne exportaciones para importar ViewModels desde un punto común.

## Pantallas: `views/`

Las vistas construyen la interfaz y conectan los controles con los ViewModels.

- **`login_view.dart`**: formulario de acceso.
- **`shell_view.dart` — `ShellView`**: estructura principal y navegación.
- **`home_view.dart`**: resumen e inicio del operario.
- **`records_view.dart`**: lista, búsqueda y revisión de registros locales.
- **`central_menu_view.dart`**: accesos a consultas del centro.
- **`central_view.dart`**: lotes confirmados, detalles y asignación de tanque.
- **`catalog_view.dart`**: consulta y actualización de catálogos.
- **`capture_view.dart`**: coordina los pasos de captura de una recepción.
- **`local_detail_view.dart`**: detalle de una recepción local y su estado de envío.
- **`scanner_view.dart`**: lectura de códigos QR.
- **`profile_view.dart`**: información y acciones de la cuenta.
- **`connection_view.dart` y `connection_status.dart`**: presentación y comprobación del estado de conexión.
- **`widgets.dart`**: exportaciones o composición de widgets compartidos.

### Pasos de captura: `views/capture/`

- **`origin_step.dart`**: proveedor, vehículo y origen.
- **`measurements_step.dart`**: volumen y mediciones físico-químicas.
- **`review_step.dart`**: resumen antes de guardar.
- **`reception_fields.dart`**: campos reutilizados en el formulario.

### Componentes: `views/components/`

Contienen piezas visuales reutilizables como `PrimaryButton`, `MenuAction`, `SectionIntro`, `SectionCard`, `StateBadge`, `Notice`, `LocalLotCard`, `CatalogPicker`, `Paging` y `LotQr`. Si un elemento compartido necesita un cambio, conviene revisar primero su componente para mantenerlo consistente en todas las pantallas.

## Ejemplo: guardar y enviar una recepción

1. `CaptureView` presenta los pasos de origen, mediciones y revisión.
2. El ViewModel de trabajo valida el formulario y solicita guardar al `LocalRepository`.
3. `LocalRepository` persiste la recepción en SQLite. El registro queda en el teléfono.
4. Cuando el operario solicita el envío, `WorkspaceViewModel` coordina `SyncService`.
5. `SyncService` usa `ApiClient` para enviar los datos al backend con la sesión vigente.
6. Si el servidor confirma, el resultado se asocia al registro local. Si falla la conexión, la recepción permanece pendiente para reintentar.

El backend aplica las reglas de calidad. La app muestra el resultado que recibe y no sustituye las validaciones del servidor.

## Dónde buscar un cambio

| Cambio | Dónde empezar |
| --- | --- |
| Color o estilo global | `core/app_colors.dart`, `core/theme.dart` |
| Botón o etiqueta reutilizable | `views/components/` |
| Posición o texto de una pantalla | Vista correspondiente en `views/` |
| Pasos del registro | `views/capture/` y `capture_view.dart` |
| Acción o estado de pantalla | ViewModel responsable en `viewmodels/` |
| Formato o campos de un dato | `models/` |
| Guardado local o borradores | `repositories/local_repository.dart` |
| Solicitudes HTTP y errores | `services/api_client.dart` |
| Inicio de sesión y catálogos | `services/session_service.dart` y su ViewModel |
| Envío y reintentos | `services/sync_service.dart` y `WorkspaceViewModel` |
| Consultas y tanques | `services/central_service.dart` y `CentralViewModel` |
