<div align="center">

<img src="docs/assets/readme-banner.svg" alt="ACOPIO — Recepción y trazabilidad de leche" width="100%" />

# ACOPIO

**Sistema Automatizado Multiplataforma para el Registro, Validación y Trazabilidad en el Acopio de Materia Prima Láctea en Leche Gloria, 2026**

Avance de Proyecto Final 3 · Curso Integrador I: Sistemas Software · Universidad Tecnológica del Perú

**Flutter y Dart · Java 17 y Spring Boot · PostgreSQL · React y Vite**

</div>

## Presentación

Desarrollamos ACOPIO para registrar recepciones de leche y relacionar su origen, mediciones, evaluación de calidad y tanque de destino. Tomamos como caso de estudio a Leche Gloria y trabajamos con datos ficticios en un entorno académico.

Nuestra propuesta permite continuar el registro cuando el centro no tiene acceso al servidor. El operario conserva la recepción en el teléfono y solicita su envío cuando recupera la conexión. El backend valida la información y la almacena en PostgreSQL; la jefatura consulta los registros confirmados desde el dashboard.

**Estado al 25 de octubre de 2026:** contamos con captura local, envío manual con reintento, evaluación central de calidad, asignación de tanque, consulta por QR y reportes CSV y Excel. El recorrido integrado fue comprobado en Android y dashboard. Las reglas **DEMO-1** son valores académicos de demostración, no criterios oficiales de la empresa. La preparación para producción corresponde a una etapa posterior.

## Contenido

- [Roles y responsabilidades](#roles-y-responsabilidades)
- [Recorrido funcional](#recorrido-funcional)
- [Interfaces](#interfaces)
- [Arquitectura y organización](#arquitectura-y-organización)
- [Persistencia y consistencia](#persistencia-y-consistencia)
- [API y permisos](#api-y-permisos)
- [Instalación y ejecución](#instalación-y-ejecución)
- [Pruebas y evidencias](#pruebas-y-evidencias)
- [Alcance pendiente](#alcance-pendiente)
- [Equipo](#equipo)

## Roles y responsabilidades

| Rol | Interfaz | Responsabilidades implementadas |
| --- | --- | --- |
| **OPERARIO** | App Flutter | Registrar recepciones, conservar borradores, enviar pendientes, consultar calidad y trazabilidad y asignar un tanque a una recepción aprobada. |
| **JEFATURA** | Dashboard | Consultar indicadores, lotes, incidencias y tanques del centro; filtrar y exportar reportes CSV y Excel. La API también dispone de administración de proveedores y vehículos. |

El operario registra el destino físico de la recepción porque participa en la operación del centro. La selección del tanque está sujeta a validación del servidor: mismo centro, lote aprobado y capacidad suficiente. La jefatura supervisa la información. Esta distribución es una decisión de nuestro prototipo y debe contrastarse con el procedimiento real de la organización.

La asignación es un registro digital; no controla válvulas ni confirma el trasvase mediante sensores. `acopio_dev` es una cuenta técnica de PostgreSQL, no un tercer rol de la aplicación.

## Recorrido funcional

1. **Acceso y catálogos.** El operario inicia sesión y descarga proveedores, vehículos y centro autorizado. Puede actualizar la copia sin perder su borrador.
2. **Captura.** Selecciona el origen e ingresa volumen, temperatura, acidez y densidad. Revisa el resumen antes de guardar.
3. **Guardado local.** Se conserva la recepción y su UUID en el teléfono. El guardado no realiza un envío automático.
4. **Envío y reintento.** El operario envía una recepción o los pendientes. Un fallo de comunicación conserva el registro y la solicitud para reintentarlos con el mismo UUID.
5. **Evaluación central.** El backend valida las referencias, evalúa las mediciones y registra la calidad y las incidencias correspondientes.
6. **Destino.** Una recepción aprobada puede asignarse a un tanque disponible del mismo centro, con validación de capacidad.
7. **Supervisión.** La jefatura consulta el lote confirmado desde el dashboard y genera reportes con los mismos filtros aplicados.

Distinguimos **guardado local**, **recibido por el servidor** y **resultado de calidad**. Un lote rechazado por calidad también puede estar correctamente enviado. Los totales del teléfono corresponden a esa cuenta y dispositivo; los del dashboard incluyen las recepciones confirmadas del centro.

La captura sin conexión requiere una sesión todavía vigente y catálogos descargados. No guardamos la contraseña, no evaluamos calidad offline ni enviamos recepciones en segundo plano. Cerrar sesión conserva los registros y la edición local, separados por usuario y centro.

## Interfaces

| Sección móvil | Función |
| --- | --- |
| **Inicio** | Nueva recepción, pendientes y últimas recepciones. |
| **Registros** | Búsqueda por proveedor, placa o UUID, filtro de pendientes y acceso al detalle local. |
| **Central** | Trazabilidad, calidad, lectura de QR y asignación de tanque mediante consultas al servidor. |
| **Perfil** | Identidad, centro, catálogos, comprobación de conexión y cierre de sesión. |

<p align="center">
  <img src="mobile-flutter/docs/visual-entrega3/inicio.png" alt="Inicio de la app Flutter" width="260" />
  <img src="mobile-flutter/docs/visual-entrega3/central.png" alt="Menú Central de la app Flutter" width="260" />
</p>

*Vistas actuales renderizadas con datos ficticios de prueba; ilustran la interfaz y no constituyen evidencia de sincronización.*

En el dashboard organizamos la consulta en **Indicadores, Incidencias, Trazabilidad y Reportes**. Compartimos filtros de estado, fechas y búsqueda entre consultas y exportaciones. Los datos se actualizan cada 30 segundos mientras la ventana está visible, al recuperar el foco o al solicitar una actualización.

La sesión vigente, pantalla, filtros y selección del lote se conservan al recargar la misma pestaña. El QR identifica la recepción mediante el código confirmado por el servidor; el acceso al detalle sigue sujeto a autenticación y permisos del centro.

![Trazabilidad y QR del lote confirmado](mobile-flutter/docs/evidencias/recorrido-2026-10-24/05-dashboard-qr-despues-recarga.png)

*Evidencia del 24/10/2026: QR visible después de recargar el dashboard conservando la sesión. El detalle del recorrido está en [Evidencias del recorrido](mobile-flutter/docs/EVIDENCIAS_RECORRIDO.md).*

## Arquitectura y organización

La app y el dashboard consumen la misma API REST. PostgreSQL conserva la información central y SQLite permite trabajar localmente en el teléfono.

```text
milk-traceability-offline/
├── backend/          API REST, seguridad, calidad, reportes y persistencia JPA
├── dashboard/        Interfaz web de jefatura y pruebas
├── mobile-flutter/   Aplicación móvil Flutter, pruebas y evidencias
│   └── lib/
│       ├── core/          Configuración, providers, tema y formatos
│       ├── models/        Sesión, catálogos, lotes y validaciones
│       ├── repositories/  Persistencia SQLite
│       ├── services/      HTTP, sesión, catálogos, envío y consultas
│       ├── viewmodels/    Estado y coordinación de operaciones
│       └── views/         Pantallas, pasos de captura y componentes
├── database/         Modelo SQL de referencia para el informe
├── docs/             Documentación técnica y evidencias de pruebas
├── scripts/          Preparación, ejecución y conexión Android
└── README.md         Presentación y documentación general del proyecto
```

### Aplicación móvil

Aplicamos **MVVM**, con `ChangeNotifier` y Riverpod para observar el estado y administrar dependencias. Las vistas no ejecutan SQL ni realizan directamente las solicitudes HTTP.

| Clases o componentes | Responsabilidad |
| --- | --- |
| `ShellView` | Coordina la navegación entre las cuatro pestañas. |
| `HomeView`, `RecordsView`, `CentralMenuView`, `ProfileView` | Presentan las funciones de cada sección. |
| `CaptureView` y `views/capture/` | Coordinan origen, mediciones y revisión de la recepción. |
| `LocalDetailView`, `CentralView`, `ScannerView` | Presentan el registro local, la consulta central y la lectura de QR. |
| `AuthViewModel`, `WorkspaceViewModel`, `CentralViewModel`, `CatalogViewModel`, `ConnectionViewModel` | Mantienen el estado y coordinan acceso, captura, envío, consultas, catálogos y conexión. |
| `LocalRepository` | Conserva registros, solicitudes y ediciones en SQLite. |
| `ApiClient`, `SessionService`, `SyncService`, `CentralService` | Gestionan HTTP, acceso y catálogos, envío y consultas centrales. |
| `AppColors`, tema y componentes compartidos | Unifican colores, tipografía, botones, menús y etiquetas de estado. |

Cada ViewModel tiene su propio archivo. `app_viewmodels.dart` conserva las exportaciones para los consumidores existentes. `MenuAction`, `SectionIntro`, `PrimaryButton` y `StateBadge` evitan repetir la composición visual.

### Backend y dashboard

En Java separamos controladores REST, servicios de negocio, reglas de calidad, entidades y repositorios JPA. Spring Security valida el JWT y los permisos; Flyway administra la evolución del esquema. En el dashboard, React presenta las consultas de jefatura y Vite sirve el entorno de desarrollo con un proxy hacia la API.

| Tecnología | Uso |
| --- | --- |
| Flutter, Dart y Riverpod | Interfaz móvil y gestión del estado. |
| SQLite y almacenamiento seguro | Registros locales y persistencia separada del token. |
| Java 17, Spring Boot, JPA/Hibernate | API, transacciones y acceso a PostgreSQL. |
| PostgreSQL y Flyway | Persistencia relacional central y migraciones. |
| React, Vite y Bootstrap | Dashboard de jefatura. |
| Guava | Cálculo SHA-256 de la representación canónica de una recepción. |
| Apache POI y Commons CSV | Exportaciones XLSX y CSV. |
| Logback | Diagnóstico técnico y eventos de recepción y reportes. |

Las versiones declaradas se encuentran en [pom.xml](backend/pom.xml), [pubspec.yaml](mobile-flutter/pubspec.yaml) y [package.json](dashboard/package.json). Conservamos los archivos de bloqueo de dependencias para reproducir el entorno.

## Persistencia y consistencia

El modelo central incluye nueve tablas de negocio: `rol`, `centro_acopio`, `usuario`, `proveedor`, `vehiculo`, `tanque`, `lote_leche`, `registro_calidad` e `incidencia`. Flyway mantiene además su historial de migraciones.

Las [migraciones del backend](backend/src/main/resources/db/migration) son la fuente ejecutable del esquema. [modelo_original_informe.sql](database/modelo_original_informe.sql) es una referencia del informe y no debe ejecutarse encima de una base ya administrada por Flyway.

En el teléfono usamos `acopio_flutter.db`, con tablas `lots`, `sends`, `editions` y `config`. La captura, la asociación de la identidad y la eliminación del borrador se confirman en una transacción. Serializamos las escrituras y separamos formularios y catálogos por usuario y centro. El token se almacena mediante `flutter_secure_storage`.

Para reintentar sin duplicar, conservamos el UUID y el cuerpo de la solicitud. Calculamos una huella SHA-256 sobre UUID, proveedor, vehículo, usuario, centro, instante UTC, volumen y mediciones. La representación elimina ceros decimales no significativos y normaliza el instante; usuario y centro autorizados provienen de la sesión. Un UUID reutilizado con contenido diferente genera un conflicto.

La confirmación local requiere una respuesta válida y coherente del servidor. Un código HTTP de éxito por sí solo no basta. El backend controla el aislamiento por centro, las referencias activas, la calidad y la capacidad del tanque dentro de sus operaciones transaccionales.

## API y permisos

| Método y ruta | Acceso | Función |
| --- | --- | --- |
| `POST /api/auth/login` | Público | Autenticación y emisión de JWT. |
| `GET /api/estado` | Público | Diagnóstico de API y PostgreSQL. |
| `GET /api/catalogos/proveedores`, `/vehiculos` y `/centro` | OPERARIO / JEFATURA | Catálogos y centro autorizado. Las tres rutas comienzan por `/api/catalogos`. |
| `POST /api/lotes` | OPERARIO | Recepción, control de duplicados y evaluación. |
| `GET /api/lotes` y `/api/lotes/{uuid}` | OPERARIO / JEFATURA | Listado y detalle del centro. |
| `GET /api/lotes/por-qr?codigo=ACOPIO:UUID` | OPERARIO / JEFATURA | Consulta por código QR. |
| `GET /api/tanques` | OPERARIO / JEFATURA | Tanques del centro. |
| `POST /api/lotes/{uuid}/asignacion-tanque` | OPERARIO | Asignación del destino. |
| `GET /api/reportes`, `/api/reportes/csv`, `/api/reportes/xlsx` | JEFATURA | Indicadores y exportaciones. |
| `/api/administracion/catalogos/**` | JEFATURA | Administración de proveedores y vehículos mediante API. |

Las consultas paginadas utilizan `pagina` y `tamano`. Los lotes y reportes aceptan `estado`, `desde`, `hasta` y `buscar`. Las fechas se interpretan en `America/Lima` y cada reporte admite hasta 10000 registros. CSV y Excel conservan los filtros y el centro autenticado; las cadenas similares a fórmulas reciben un tratamiento específico en la exportación.

## Instalación y ejecución

### Requisitos

Nuestro entorno de desarrollo en Windows utiliza Git, **Java 17**, Maven, Node.js con npm, **PostgreSQL 18**, Flutter y Android SDK. La configuración Android debe estar disponible en `flutter doctor`. Para un teléfono físico se requiere depuración USB autorizada.

### Preparación inicial

Desde la raíz del repositorio, en PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Preparar.ps1
```

El script instala dependencias, prepara PostgreSQL local y ejecuta compilación y pruebas. Las claves de esa computadora se conservan en `.local/db-password.txt` y `.local/jwt-secret.txt`, fuera de Git. [.env.example](.env.example) documenta las variables; no se carga automáticamente.

Podemos configurar `ACOPIO_JAVA_HOME`, `ACOPIO_PG_BIN` y `ACOPIO_NODE` si las herramientas están en rutas diferentes. No incluimos datos privados, claves ni dependencias instaladas en el repositorio.

### Arranque habitual

```powershell
.\Iniciar.cmd
```

En otra terminal, con Android conectado:

```powershell
.\Abrir_Flutter.cmd
```

El lanzador móvil configura Java 17, selecciona el dispositivo autorizado, prepara `adb reverse` para el puerto 18080 y ejecuta Flutter. Si hay varios dispositivos:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Dev.ps1 -Action Mobile -DeviceId ID_DEL_CELULAR
```

| Servicio | Dirección de desarrollo |
| --- | --- |
| Dashboard | http://127.0.0.1:5173 |
| API | http://127.0.0.1:18080 |
| Diagnóstico | http://127.0.0.1:18080/api/estado |
| PostgreSQL | `127.0.0.1:55440`, base y usuario `acopio_dev` |

`Verificar.cmd` comprueba el entorno y `Detener.cmd` detiene los servicios administrados. El proceso móvil termina con `q` en su terminal.

### Conexión móvil y cuentas de desarrollo

| Entorno móvil | `API_BASE_URL` |
| --- | --- |
| Android físico por USB y `adb reverse` | `http://127.0.0.1:18080` |
| Emulador Android estándar | `http://10.0.2.2:18080` |
| Android por red local | `http://IP_LAN_DEL_PC:18080` |
| Simulador iOS en el mismo Mac que la API | `http://127.0.0.1:18080` |

La URL se define al compilar con `--dart-define=API_BASE_URL=...`. Por defecto el backend escucha en la interfaz local; usar la red local requiere configurar su dirección de escucha y acceso al puerto. Preferimos USB para el entorno académico. `adb.exe` suele encontrarse en `%LOCALAPPDATA%\Android\Sdk\platform-tools`.

| Interfaz | Correo ficticio | Contraseña inicial de desarrollo |
| --- | --- | --- |
| App OPERARIO | `operario@gloria.com.pe` | `123456` |
| Dashboard JEFATURA | `jefatura@gloria.com.pe` | `123456` |

Estas cuentas pertenecen a los datos de demostración. Si se modificaron sus claves, se utilizan las vigentes. La contraseña de PostgreSQL es independiente. En pgAdmin registramos el host y puerto anteriores con la clave local de esta computadora; la instancia del proyecto es independiente de otros servidores en el puerto 5432.

### Actualizar después de cambios del backend

```powershell
.\Probar_Proyecto.cmd
```

El comando recompila el backend y ejecuta las pruebas. Si la API está en funcionamiento, la detiene para reemplazar el JAR y la reinicia. Después comprueba dashboard y Flutter y genera el APK Android de depuración.

`Iniciar.cmd` reutiliza el JAR existente: iniciar los servicios no equivale a recompilar el código actualizado. El 25/10 comprobamos que un JAR antiguo impedía exportar Excel; la recompilación y el reinicio resolvieron el problema.

## Pruebas y evidencias

| Componente | Resultado comprobado | Alcance |
| --- | --- | --- |
| Backend, 25/10/2026 | **43 pruebas**, sin fallos, errores ni omitidas | 2 de aplicación, 38 de flujos y 3 del exportador; reportes Surefire conservados. |
| Flutter, 25/10/2026 | **46 pruebas aprobadas**, análisis sin incidencias y APK generado | Conexión, servicios, repositorio, validaciones y widgets, incluido ajuste de los detalles en pantallas estrechas. |
| Dashboard, evidencia del 24/10/2026 | **11 pruebas aprobadas** y compilación correcta | Fechas, QR y conservación de sesión. No sumamos ejecuciones de fechas distintas. |
| Recorrido integrado | Comprobado en teléfono y dashboard; funcionamiento confirmado nuevamente el 25/10 | Captura local, recuperación de conexión, envío, calidad, destino y consulta. Excel confirmado tras actualizar el backend. |

La matriz de Elías contiene **24 casos** y documenta sus alcances. No los sumamos al número de pruebas automatizadas. Incluye aislamiento por centro, calidad, capacidad, reintentos, concurrencia, rollback, migraciones y validación JPA. Las pruebas adicionales cubren vehículos inactivos, límites del día en Lima y paginación de 30 tanques.

Para ejecutar las pruebas de Flutter desde la raíz:

```powershell
Push-Location mobile-flutter
flutter analyze --no-pub
flutter test --no-pub test/connection_test.dart test/services_test.dart test/widget_test.dart test/repository_test.dart test/validation_test.dart test/detail_layout_test.dart
Pop-Location
```

Para el dashboard:

```powershell
Push-Location dashboard
npm test
npm run build
Pop-Location
```

Las pruebas de integración del lanzador utilizan la base separada `acopio_test`. Las pruebas locales de Flutter usan almacenamiento temporal y respuestas controladas. El contrato con servidor real se ejecuta mediante `mobile-flutter/tool/Test-Contract.ps1`: requiere un JAR actualizado y prepara PostgreSQL y backend aislados en los puertos 55441 y 18081. Crea una recepción de prueba; no debe apuntarse a una base de presentación.

El APK se genera en `mobile-flutter/build/app/outputs/flutter-apk/app-debug.apk`. La compilación Android no acredita una compilación iOS ni una firma de distribución.

### Documentación técnica conservada

| Documento | Contenido |
| --- | --- |
| [Librerías, Javadoc y TDD](docs/APF3_LIBRERIAS_JAVADOC_TDD.md) | Uso de librerías, ciclo rojo–verde–refactorización de Excel y evidencias académicas. |
| [Matriz de pruebas de Elías](docs/pruebas/MATRIZ_PRUEBAS_ELIAS.md) | Casos, resultados y evidencias por versión. |
| [Datos ficticios](docs/pruebas/DATOS_FICTICIOS_ELIAS.md) | Datos de preparación para las pruebas. |
| [Cierre adicional de Elías](docs/pruebas/CIERRE_ADICIONAL_ELIAS_2026-10-24.md) | Comprobaciones de integración y pruebas adicionales del 24/10. |
| [Verificación móvil](docs/pruebas/VERIFICACION_FLUTTER.md) | Resultados móviles consolidados, alcance y evidencias del recorrido. |
| [Evidencias del recorrido](mobile-flutter/docs/EVIDENCIAS_RECORRIDO.md) | Capturas originales y explicación de lo observado. |
| [Resultados backend del 25/10](docs/pruebas/evidencias/2026-10-25) | Resúmenes Surefire de la suite completa de 43 pruebas. |

Los documentos fechados describen la versión probada en ese momento; sus incidencias históricas no sustituyen este resumen del estado actual. Conservamos evidencias anteriores de migraciones y transacciones porque permiten contrastar resultados antes y después de una operación.

Generamos Javadoc desde `backend` con `mvn javadoc:javadoc`; el resultado está en `backend/target/site/apidocs/index.html`. Los registros de Logback son diagnóstico técnico y no sustituyen una auditoría durable de usuarios.

## Alcance pendiente

| Área | Trabajo pendiente |
| --- | --- |
| Reportes | Exportación PDF y diferenciación visual entre errores y descargas correctas en los avisos del dashboard. |
| Administración | Pantallas completas para proveedores y vehículos; gestión de usuarios, centros y alta de tanques. |
| Tanques | Vaciado, mantenimiento e historial de movimientos; completar la paginación del dashboard, que consulta los primeros 25 tanques. |
| Recepciones | Corrección o anulación autorizada, con motivo e historial. |
| Publicación | HTTPS, firma de distribución, respaldos con restauración comprobada y pruebas de rendimiento y aceptación final. |
| Validación operativa | Contrastar responsabilidades y reglas de calidad con el proceso real. |
| iOS | Compilar, firmar y probar en macOS/Xcode. |

La prueba de 30 tanques valida la paginación de la API; no equivale a tener implementadas todas las páginas en el dashboard. El proyecto Android constituye la plataforma comprobada de esta entrega.

## Equipo

| Integrante | Responsabilidad principal |
| --- | --- |
| Sergio Rodrigo Veliz Carrasco | Aplicación móvil, entorno e integración. |
| Patricio Alejandro Durant Carbajal | Backend, autenticación, recepción y calidad. |
| Fernando José Huayto Abarga | Dashboard y consumo de la API. |
| Elías Jhonny Ccama Ynca | Base de datos y pruebas. |

Integramos nuestros aportes en este repositorio y conservamos en Git el historial de cambios. La documentación distingue las funciones implementadas, las verificaciones realizadas y el alcance previsto para la siguiente entrega.
