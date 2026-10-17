# Acopio: proyecto de desarrollo

**Entrada del equipo:** [Documentación organizada](docs/README.md) · [Inicio rápido](docs/01_INICIO_RAPIDO.md) · [Distribución del trabajo](docs/03_EQUIPO.md) · [Pendientes](docs/04_PENDIENTES.md).

Para abrir los componentes juntos en VS Code, abrir `Acopio.code-workspace`.

Preparado el 09/10/2026 para Sergio, Elías, Patricio y Fernando. Este proyecto inicia la implementación; el prototipo HTML del avance 2 sigue separado y conserva sus datos y pantallas.

## Empezar en la computadora de Sergio

1. Abre esta carpeta en el Explorador de Windows.
2. Ejecuta **Iniciar.cmd**. Se inicia PostgreSQL aislado, se crea `acopio_dev` si no existe y se inicia Spring Boot. Flyway crea las nueve tablas y los catálogos de prueba automáticamente. Después se abre el dashboard en `http://127.0.0.1:5173`.
3. Pulsa **Comprobar conexión real**. Debe aparecer API conectada, PostgreSQL y **9 tablas**, además de un centro académico ficticio leído desde la base.
4. Ejecuta **Verificar.cmd** para consultar los servicios y **Probar_Proyecto.cmd** para compilar y ejecutar la prueba de integración del esquema.
5. Al terminar, ejecuta **Detener.cmd**. No borra la base.

La primera ejecución puede tardar por descargas y creación de la base. Si aparece un error, conserva el mensaje de la ventana y revisa `.local/backend.log`, `.local/backend.error.log` y `.local/postgres.log`. No ejecutes otro `initdb` ni elimines `.local/pgdata` para solucionarlo.

**Estado de verificación (09/10/2026):** backend compilado y empaquetado; prueba de integración aprobada (9 tablas, 59 columnas y 2 migraciones); backend reiniciado y API disponible en 18080. Dashboard compilado y TypeScript móvil aprobado. Se confirmó visualmente la apertura de la app en Android mediante Expo Go. Las capturas posteriores del usuario confirman API móvil conectada y 3 comprobaciones guardadas en SQLite. Falta confirmar persistencia tras cerrar y reabrir. Los recorridos de negocio todavía no están implementados. El bundle Android no es un APK independiente.

## Qué contiene

| Carpeta | Tecnología | Trabajo preparado |
|---|---|---|
| `backend` | Java 17, Spring Boot 4.1.1, Maven | Controller → Service → Repository, endpoint `/api/estado`, Actuator, JDBC y migraciones Flyway |
| `dashboard` | React, Vite, Bootstrap 5 | Pantalla de diagnóstico que consulta la API real y muestra centros de PostgreSQL |
| `mobile` | React Native, Expo SDK 57, TypeScript | Vista, ViewModel y repositorio separados; prueba de API y almacenamiento SQLite |
| `database` | PostgreSQL 18 | Copia del SQL del informe como referencia |
| `scripts` | PowerShell | Preparación, arranque, parada, compilación, comprobación y conexión Android |
| `.local` | Archivos privados de esta máquina | Base, contraseña local, caches y registros; excluidos de Git |

La base es **nueva e independiente** de tus instalaciones existentes: host `127.0.0.1`, puerto `55440`, nombre y usuario `acopio_dev`. La contraseña se genera y guarda en `.local/db-password.txt`; no compartirla ni incluirla en el informe. El usuario propietario es solo para este entorno académico local. Antes de un despliegue deberá separarse del usuario de la aplicación y limitar permisos.

Se reutilizan Java 17.0.18, Maven 3.9.13 y PostgreSQL 18.3 ya instalados. Los scripts prefieren Node 24.19.0 incluido en el runtime local y no modifican el Node 25 global ni las variables permanentes del sistema. Si cambias de máquina, usa Node 24 LTS y define `ACOPIO_NODE` si necesitas una ruta específica.

## App Android

El usuario ya mostró conexión API y guardado SQLite en Android; queda confirmar persistencia después de cerrar y reabrir.

1. Inicia el backend con `Iniciar.cmd`.
2. Conecta un Android por USB, activa la depuración USB y acepta la autorización del equipo. Alternativamente, inicia un emulador desde Android Studio.
3. Abre PowerShell en la carpeta del proyecto y ejecuta:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Conectar-Android.ps1
```

4. Instala una versión de Expo Go compatible con SDK 57 en el dispositivo. Ejecuta **Abrir_Movil.cmd** y pulsa **a**. Si hay varios dispositivos, usa `Conectar-Android.ps1 -Serial IDENTIFICADOR` y selecciona el mismo en Expo.
5. En la app pulsa **Comprobar API real** y después **Guardar prueba en SQLite**. Repite el guardado, cierra y abre la app y comprueba que el contador continúa aumentando. El contador registra diagnósticos, no lotes.

Se utiliza `adb reverse` para acceder al backend y Metro por USB/emulador. El backend escucha solo en localhost: escanear un QR por Wi-Fi no habilita esa conexión. No necesitas abrir puertos del router. Si Expo solicita actualizar su cliente, usa las instrucciones oficiales: https://docs.expo.dev/get-started/start-developing/.

## Trabajar cada día

- Backend: editar `backend/src/main/java/pe/edu/utp/acopio`. Después de cambios, ejecutar `Probar_Proyecto.cmd`: detiene solo el backend del proyecto si está activo, recompila y lo reinicia al finalizar correctamente. El lanzador ejecuta el JAR compilado, no recompila cada vez si ya existe.
- Dashboard: editar `dashboard/src`; Vite recarga automáticamente mientras esté iniciado.
- Móvil: editar `mobile/App.tsx`, `src/viewmodel` y `src/model` con Expo abierto.
- Base: agregar una **nueva** migración `V3__...sql` en `backend/src/main/resources/db/migration`. No modificar V1/V2 una vez aplicadas ni ejecutar encima el SQL de referencia de `database`.
- Git: repositorio del equipo https://github.com/serchiove/milk-traceability-offline, rama principal `main`. `.local`, contraseñas, dependencias y compilaciones están excluidos.

## Prepararlo en otra computadora del equipo

Copiar el paquete de código fuente o usar Git cuando acuerden el repositorio. Requisitos: Java 17, Maven 3.9+, Node 24 LTS, Git y PostgreSQL 18. Para móvil, Android por USB o Android Studio. No hace falta XAMPP.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Preparar.ps1
```

El script instala versiones de los archivos lock, genera una contraseña distinta, crea la instancia local y ejecuta las comprobaciones. PostgreSQL se busca en `C:\Program Files\PostgreSQL\18\bin`; si está en otra carpeta, define `ACOPIO_PG_BIN`. La base utiliza puerto 55440 y no toca los servidores de 5432.


## Siguiente parte a programar

Autenticación y roles, captura y consulta de lotes, UUID estable, huella de solicitudes, reglas de calidad versionadas, asignación de tanques y sincronización con confirmación del servidor. Todavía no existen estos endpoints ni una pantalla de inicio de sesión real. No utilizar las cuentas del prototipo HTML en este proyecto.

Referencias de configuración: https://docs.spring.io/spring-boot/system-requirements.html y https://docs.expo.dev/get-started/create-a-project/.

## Corrección de arranque móvil (09/10/2026)
Metro se inicia con `--dns-result-order=ipv4first` para atender `127.0.0.1` mediante USB. Se usan las carpetas `.local/expo-windows` y `.local/temp-windows` para evitar conflictos de permisos con la caché anterior. Se confirmó visualmente la apertura de la app en el Android conectado; las capturas del usuario confirman los botones de API y SQLite. La persistencia tras reiniciar queda pendiente.

## Informe técnico del equipo

[Informe completo y estado por componente](docs/informes/00_INFORME_COMPLETO.md). Incluye lo implementado, evidencia, pendientes y criterios de aceptación para Sergio, Fernando, Patricio y Elías.
