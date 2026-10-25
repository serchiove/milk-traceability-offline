# ACOPIO · Flutter

Aplicación móvil de ACOPIO para recepción y trazabilidad de leche, desarrollada en Flutter y Dart. Consulta la API Spring Boot y comparte con el dashboard los datos confirmados en PostgreSQL. La captura de campo y los borradores se conservan localmente en SQLite.

## Inicio rápido (PowerShell)

Desde esta carpeta, con Flutter instalado:

```powershell
flutter pub get
flutter devices
flutter run -d ID_DEL_EMULADOR --dart-define=API_BASE_URL=http://10.0.2.2:18080
```

Sustituye `ID_DEL_EMULADOR` por el identificador que muestre `flutter devices`. Inicia el backend existente con el procedimiento habitual del repositorio. Flutter no inicia ni modifica Spring Boot automáticamente.

### Celular Android por USB

Activa depuración USB, conecta el equipo y acepta su autorización. Ejecuta:

```powershell
adb devices
adb reverse tcp:18080 tcp:18080
flutter run -d ID_DEL_CELULAR --dart-define=API_BASE_URL=http://127.0.0.1:18080
```

`adb` está normalmente en `%LOCALAPPDATA%\Android\Sdk\platform-tools`. Si no está en PATH, usa su ruta completa. Si hay varios dispositivos, añade `-s ID_DEL_CELULAR` a `adb reverse`.

La app se instala como **ACOPIO Flutter** (`pe.edu.utp.acopio_flutter`) directamente en Android. Desde la raíz del repositorio también se puede ejecutar `Abrir_Flutter.cmd`; el lanzador configura Java 17 y el enlace USB a la API.

### Direcciones del servidor

| Entorno | API_BASE_URL |
|---|---|
| Emulador Android estándar | `http://10.0.2.2:18080` |
| Celular conectado mediante `adb reverse` | `http://127.0.0.1:18080` |
| Celular por Wi-Fi | `http://IP_LAN_DEL_PC:18080` |
| Simulador iOS en el mismo Mac que el backend | `http://127.0.0.1:18080` |

`localhost` en el celular apunta al propio celular. El backend actual escucha en `127.0.0.1`: para Wi-Fi debe arrancarse con `SERVER_ADDRESS=0.0.0.0` (o `--server.address=0.0.0.0`) y permitir ese puerto en el firewall. Esto es una opción de ejecución, no requiere editar el backend. Preferimos USB para la demostración local. El valor por defecto de Flutter es el del emulador Android. Las URLs se fijan al compilar; no son contraseñas. También se admite `--dart-define=AUTH_PATH=/api/auth/login`.

## Recorrido funcional

1. Inicia sesión con una cuenta **OPERARIO** del backend. El primer acceso necesita conexión y descarga todos los proveedores, vehículos y el centro autorizado. Una cuenta JEFATURA corresponde al dashboard.
2. En **Inicio**, los indicadores representan los registros locales del operario en este dispositivo. **Central** consulta los datos del servidor y necesita conexión.
3. Abre **Nueva recepción**: elige proveedor y vehículo, completa mediciones y revisa. El centro proviene de la cuenta. Los campos se guardan mientras escribes.
4. Pulsa **Guardar recepción**. Se crean el UUID, el registro local y su envío pendiente en una misma transacción. No se envía todavía.
5. Abre el detalle y confirma **Enviar al servidor**, o usa **Sincronizar pendientes** desde Registros. El envío conjunto muestra el avance, los confirmados, los resultados de calidad y el motivo de cada pendiente, con opción de reintentar. Un rechazo de calidad también es una recepción recibida; no significa un fallo de sincronización.
6. Si se pierde la conexión, reintenta sobre el mismo registro. El UUID, la identidad y el cuerpo permanecen congelados; el backend evita duplicados.
7. En **Central**, consulta calidad y trazabilidad por lista paginada, UUID o cámara QR. Solo un lote aprobado muestra QR y puede asignarse a un tanque disponible del mismo centro con capacidad suficiente.
8. La asignación consulta el estado antes de cada intento. Si el resultado es incierto, vuelve a consultar el lote. No hay reasignación ni vaciado de tanques en el backend actual.
9. El dashboard verá los mismos datos al actualizar y entrar con un usuario del mismo centro. Consulta todos los equipos del centro y se actualiza cada 30 segundos mientras está visible, al recuperar el foco o al pulsar **Actualizar datos**. Muestra las fechas de consulta de lotes, indicadores y tanques. El período del resumen comparte filtros con reportes y exportaciones.
10. Cerrar sesión conserva las recepciones y la edición. Otra cuenta o centro no puede leer ni enviar esos registros locales.

La sesión offline debe seguir vigente y tener catálogos descargados. No se guarda la contraseña. Si vence el JWT, inicia sesión con conexión y la misma cuenta. En **Catálogos → Actualizar catálogos** puedes descargar la copia de captura sin cerrar sesión. Se muestra la fecha de descarga y se conserva la copia anterior si falla alguna parte; los borradores y registros guardados se conservan. Revisa las selecciones del borrador si un proveedor o vehículo dejó de estar activo.

El indicador de conexión consulta `/api/estado`, muestra la fecha de comprobación y permite reintentar. También vuelve a comprobar al abrir la pantalla o al regresar a la app. Ese estado corresponde a la última consulta; el envío siempre necesita su propia confirmación del servidor. Inicio y Registros muestran datos de esta cuenta en este celular; Central muestra consultas online del centro con su fecha de actualización.

## Arquitectura

```text
lib/
  core/          Configuración, errores, tema Material 3 e inyección Riverpod
  models/        Sesión, catálogos, lote, envío y validaciones
  repositories/  SQLite independiente y cola de escrituras
  services/      HTTP, acceso seguro, catálogos, sincronización y consultas centrales
  viewmodels/    Estado de autenticación, captura, catálogos y consultas
  views/         Pantallas y componentes Material 3
test/            Dominio, SQLite real, HTTP, widgets y contrato con Spring Boot
tool/            Prueba con PostgreSQL y backend aislados
docs/            Arquitectura, funcionalidades, pruebas y evidencias
```

MVVM usa `ChangeNotifier` con Riverpod para inyección, observación y ciclo de vida. Riverpod 3 mantiene ese adaptador en `legacy.dart`; su uso es deliberado para evitar generación de código y conservar ViewModels simples y comprobables. Las vistas no ejecutan SQL ni construyen solicitudes HTTP.

SQLite: `acopio_flutter.db`, tablas `lots`, `sends`, `editions`, `config`. Las escrituras se serializan. Captura, asociación del operario y eliminación de la edición se confirman juntas o se revierten juntas. Los formularios y catálogos se identifican por `usuario:centro`. Los tokens se guardan mediante `flutter_secure_storage`, separado de SQLite. Android deshabilita la copia automática de datos de esta app.

## Pruebas y compilación

```powershell
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:18080
```

El APK se genera en `build/app/outputs/flutter-apk/app-debug.apk`. Para instalarlo en un celular con enlace USB, recompílalo con `API_BASE_URL=http://127.0.0.1:18080`, ejecuta `adb reverse` e instala con `flutter install -d ID_DEL_CELULAR` o `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.

La suite habitual omite deliberadamente `live_contract_test.dart` salvo que exista `ACOPIO_TEST_API`. La prueba completa contra el backend real se ejecuta así:

```powershell
.\tool\Test-Contract.ps1
```

Requiere el JAR existente en `../backend/target/acopio-0.0.1-SNAPSHOT.jar`, Java y PostgreSQL 18. Crea un clúster de pruebas en `mobile-flutter/.local`, PostgreSQL en 55441 y Spring Boot en 18081. Las migraciones del JAR inicializan los catálogos de prueba. Comprueba login, huella, envío, repetición idempotente, QR, asignación y reporte JEFATURA. Detiene los procesos y retira la base temporal al terminar. No arranca ni modifica `acopio_dev`. Los archivos temporales restantes están ignorados por Git. Los puertos se pueden cambiar con `-Port` y `-PgPort`.

No apuntes `ACOPIO_TEST_API` a una base de presentación: esa prueba crea y asigna una recepción. Las credenciales demo usadas por ella son las definidas por las migraciones existentes.

## Alcance y estado

Consulta [las funcionalidades](docs/FUNCIONALIDADES.md), [la arquitectura y los contratos](docs/ANALISIS.md), [la verificación](docs/VERIFICACION.md) y [las evidencias del recorrido](docs/EVIDENCIAS_RECORRIDO.md).

Android: APK de depuración compilado y recorrido probado en un teléfono físico. Las pruebas de interfaz incluyen captura, acceso, cierre de sesión y nombres largos con pantalla estrecha. iOS: proyecto y permisos preparados; compilación y firma pendientes en un Mac con Xcode. No se incluyen destinos web o escritorio.

HTTP está habilitado para el servidor académico local. Para distribución real se debe utilizar HTTPS, limitar las excepciones de transporte y configurar la firma de publicación.
