<div align="center">

<img src="docs/assets/readme-banner.svg" alt="ACOPIO — Recepción y trazabilidad de leche" width="100%" />

**Flutter y Dart · Spring Boot y Java 17 · PostgreSQL · Dashboard React**

Capturamos recepciones en campo, conservamos los datos sin conexión y consultamos su calidad y destino desde una API compartida.

</div>

## Nuestro proyecto

Desarrollamos ACOPIO como un sistema académico de recepción y trazabilidad de leche. La aplicación móvil utiliza **Flutter y Dart**; el backend, **Java 17, Spring Boot, JPA/Hibernate y PostgreSQL**; el dashboard de jefatura, **React y Vite**.

Trabajamos con datos de prueba y reglas **DEMO-1**. Los umbrales son demostrativos y no representan criterios oficiales de Leche Gloria.

## Organización

| Carpeta | Responsabilidad |
| --- | --- |
| `mobile-flutter/` | App Android/iOS, MVVM, Riverpod, SQLite y sesión segura |
| `backend/` | API REST, JWT, permisos, recepción, calidad, tanques y reportes |
| `dashboard/` | Jefatura, indicadores, incidencias, trazabilidad, QR y exportaciones |
| `database/` | SQL de referencia; el esquema ejecutable se administra con Flyway |
| `scripts/` | Preparación, arranque, pruebas y conexión USB |
| `docs/` | Documentación técnica y evidencias del tercer avance |

El móvil conserva borradores y recepciones en SQLite. PostgreSQL es la fuente central de los registros confirmados que consultan la app y el dashboard.

## Recorrido implementado

1. El operario inicia sesión y descarga proveedores, vehículos y centro autorizado.
2. Captura origen y mediciones en tres pasos, con recuperación del borrador.
3. Guarda la recepción localmente y la deja pendiente de envío.
4. Envía una recepción o sincroniza los pendientes conservando UUID y huella para reintentar sin duplicados.
5. El backend confirma la recepción y evalúa calidad. Un rechazo de calidad también cuenta como recibido por el servidor.
6. Central consulta lotes, mediciones, calidad y QR.
7. Un lote aprobado puede asignarse a un tanque disponible del mismo centro con capacidad suficiente.
8. Jefatura consulta el dashboard y exporta CSV o Excel con los mismos filtros.

La captura offline necesita sesión vigente y catálogos descargados. Los registros se separan por usuario y centro. La actualización de catálogos conserva el borrador y la copia anterior si falla la descarga.

## Preparar el entorno

En Windows utilizamos Git, Java 17, Maven, Node.js con npm, PostgreSQL 18, Flutter y Android SDK. Completamos la configuración de `flutter doctor` y autorizamos la depuración USB en el teléfono.

Desde la raíz, en PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Preparar.ps1
```

El procedimiento instala dependencias web y Flutter, prepara PostgreSQL local y ejecuta la compilación y las pruebas. Está pensado para la preparación inicial de cada computadora.

Las claves privadas quedan en `.local/db-password.txt` y `.local/jwt-secret.txt`, fuera de Git. `.env.example` documenta las variables del backend; no se carga automáticamente.

`ACOPIO_JAVA_HOME` permite indicar otro JDK 17; `ACOPIO_PG_BIN`, la carpeta `bin` de PostgreSQL; y `ACOPIO_NODE`, una ruta específica de Node.

## Iniciar y detener

En una terminal desde la raíz:

```powershell
.\Iniciar.cmd
```

Se inician PostgreSQL, backend y dashboard. En otra terminal, con el teléfono conectado:

```powershell
.\Abrir_Flutter.cmd
```

El lanzador configura Java 17, identifica el Android autorizado, prepara el enlace USB de la API y ejecuta Flutter. Si hay varios dispositivos:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Dev.ps1 -Action Mobile -DeviceId ID_DEL_CELULAR
```

Para comprobar el entorno o detener los servicios:

```powershell
.\Verificar.cmd
.\Detener.cmd
```

Salimos del proceso móvil con `q` en la terminal de `flutter run`. La [guía Flutter](mobile-flutter/README.md) detalla el uso de emulador, USB y Wi-Fi.

| Servicio | Dirección de desarrollo |
| --- | --- |
| Dashboard | http://127.0.0.1:5173 |
| Diagnóstico API | http://127.0.0.1:18080/api/estado |
| PostgreSQL | 127.0.0.1:55440 |
| Base y usuario PostgreSQL | `acopio_dev` |
| API desde Android por USB | `http://127.0.0.1:18080`, mediante `adb reverse` |

## Cuentas de desarrollo y pgAdmin

| Uso | Correo | Contraseña inicial de los datos ficticios |
| --- | --- | --- |
| App OPERARIO | `operario@gloria.com.pe` | `123456` |
| Dashboard JEFATURA | `jefatura@gloria.com.pe` | `123456` |

Si se cambiaron las contraseñas, utilizamos las vigentes. La clave privada de PostgreSQL es independiente.

En pgAdmin usamos host `127.0.0.1`, puerto `55440`, usuario `acopio_dev` y la clave privada de esta computadora. Primero ejecutamos `Iniciar.cmd`. Esta instancia es independiente de otros servidores instalados en el puerto 5432.

## Dashboard y trazabilidad

El dashboard autentica JEFATURA y consulta el centro autorizado. El QR visible y descargable se genera en el navegador desde el código confirmado por el backend.

Los filtros de estado, fechas y búsqueda se comparten entre resumen, reportes y exportaciones. Los datos se actualizan cada 30 segundos mientras la ventana está visible, al recuperar el foco o al pulsar **Actualizar datos**. La pantalla informa las fechas de consulta.

La sesión vigente, pantalla, filtros y lote seleccionado se conservan al recargar la misma pestaña; cerrar sesión elimina el acceso guardado. Un registro local solo aparece en el dashboard después de confirmar su envío, de modo que los totales del celular y del centro pueden diferir.

## API compartida

| Ruta | Operación |
| --- | --- |
| `POST /api/auth/login` | Autenticación y JWT |
| `GET /api/estado` | Comprobación de API y PostgreSQL |
| `GET /api/catalogos/proveedores` y `/api/catalogos/vehiculos` | Catálogos activos paginados |
| `GET /api/catalogos/centro` | Centro autorizado |
| `POST /api/lotes` | Recepción, idempotencia y calidad |
| `GET /api/lotes` y `/api/lotes/{uuid}` | Listado y detalle |
| `GET /api/lotes/por-qr?codigo=ACOPIO:UUID` | Consulta por QR |
| `GET /api/tanques` | Tanques del centro |
| `POST /api/lotes/{uuid}/asignacion-tanque` | Destino |
| `GET /api/reportes` | Indicadores de jefatura |
| `GET /api/reportes/csv` y `/api/reportes/xlsx` | Exportaciones |
| `/api/administracion/catalogos` | Administración de proveedores y vehículos para jefatura |

El centro y el operario se obtienen del JWT. Las consultas usan `pagina` y `tamano`; lotes y reportes aceptan `estado`, `desde`, `hasta` y `buscar`. El período se interpreta en `America/Lima`; cada reporte admite hasta 10000 registros.

El JSON de recepción, la huella y los límites numéricos se documentan en [Arquitectura y contratos](mobile-flutter/docs/ANALISIS.md).

## Pruebas y compilación

Para compilar y comprobar los tres componentes:

```powershell
.\Probar_Proyecto.cmd
```

El lanzador usa la base separada `acopio_test` para el backend. Si la API está ejecutándose, la detiene para reemplazar el JAR y la vuelve a iniciar. Después comprueba el dashboard, analiza y prueba Flutter y construye el APK de depuración.

Para comprobar solo el móvil:

```powershell
Push-Location mobile-flutter
flutter analyze --no-pub
flutter test --no-pub test/connection_test.dart test/services_test.dart test/widget_test.dart test/repository_test.dart test/validation_test.dart
flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:18080
Pop-Location
```

Para el dashboard:

```powershell
Push-Location dashboard
npm test
npm run build
Pop-Location
```

El APK se genera en `mobile-flutter/build/app/outputs/flutter-apk/app-debug.apk`. El contrato aislado con Spring Boot y PostgreSQL se ejecuta mediante `mobile-flutter/tool/Test-Contract.ps1`, con su propio entorno temporal.

Los resultados y sus límites están en [Verificación](mobile-flutter/docs/VERIFICACION.md), [Correcciones del recorrido](mobile-flutter/docs/VERIFICACION_FLUJO.md) y [Evidencias con teléfono y dashboard](mobile-flutter/docs/EVIDENCIAS_RECORRIDO.md).

## Documentación del tercer avance

Usamos Guava para SHA-256, Apache POI para Excel, Commons CSV para la exportación y Logback para diagnóstico. El ciclo TDD, Javadoc y sus evidencias están en [la documentación técnica](docs/APF3_LIBRERIAS_JAVADOC_TDD.md).

```powershell
Push-Location backend
mvn javadoc:javadoc
Pop-Location
```

La documentación se genera en `backend/target/site/apidocs/index.html`. Flyway administra las migraciones del esquema.

## Equipo

| Integrante | Responsabilidad principal |
| --- | --- |
| Sergio | App móvil, entorno e integración |
| Patricio | Backend, autenticación, recepción y calidad |
| Fernando | Dashboard y consumo de API |
| Elías | Base de datos y pruebas |

## Próxima etapa

Quedan previstas la administración de usuarios y centros, el alta de tanques, su vaciado y mantenimiento, y la corrección o anulación de recepciones con historial. El despliegue final requiere HTTPS, firma de publicación y validación de reglas. iOS necesita compilación y pruebas con macOS/Xcode.

Los logs están en `.local`; dependencias, compilaciones, claves y datos privados quedan fuera de Git.
