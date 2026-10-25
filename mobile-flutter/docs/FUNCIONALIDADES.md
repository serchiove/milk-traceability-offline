# Funcionalidades de la aplicación móvil

| Función | Implementación | Verificación |
| --- | --- | --- |
| Autenticación OPERARIO y JWT | SessionService, AuthViewModel, LoginView | Servicios y acceso en teléfono |
| Sesión segura | SecureSessionStore | Integración y recorrido de acceso |
| Captura con catálogos | WorkspaceViewModel, CaptureView | Validación e interfaz |
| Recuperación del borrador | LocalRepository.editions | Reapertura SQLite |
| Captura e identidad atómicas | LocalRepository.capture | Transacciones, rollback y aislamiento |
| Registros y pendientes | WorkspaceViewModel, ShellView | Repositorio y recorrido manual |
| Envío individual y conjunto | SyncService, WorkspaceViewModel | Fallos parciales, reintentos e idempotencia |
| Huella compatible con Java | LotRequest.canonical/fingerprint | Vector canónico del servidor |
| Calidad y trazabilidad | CentralViewModel, CentralView | API y dashboard |
| QR y consulta por código | LotQr, ScannerView, CentralService | Generación, consulta y evidencia visual |
| Tanques y destino | CentralService, CentralView | Contrato y lote visible con tanque |
| Actualización de catálogos | CatalogView, SessionService | Borrador y recuperación ante fallo |
| Conexión | ConnectionViewModel, ConnectionStatus | Caída y recuperación |
| Cierre de sesión | AuthViewModel, WorkspaceViewModel | Conservación de datos |

La base local es `acopio_flutter.db` y el identificador Android es `pe.edu.utp.acopio_flutter`. Las consultas centrales necesitan conexión. La app no evalúa calidad sin el servidor ni envía recepciones en segundo plano.

Las funciones de administración de centros, usuarios y tanques, el vaciado y la corrección de recepciones con historial corresponden a una siguiente etapa.
