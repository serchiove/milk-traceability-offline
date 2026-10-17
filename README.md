<div align="center">

<img src="docs/assets/readme-banner.svg" alt="ACOPIO — Trazabilidad de recepción de leche. Proyecto Integrador, Equipo 4." width="100%" />

<br />

**Del registro en campo al seguimiento de cada recepción.**

Aplicación móvil · API compartida · Dashboard de jefatura

<img alt="Java 17" src="https://img.shields.io/badge/Java-17-173B63?style=flat-square" />
<img alt="Spring Boot 4.1.1" src="https://img.shields.io/badge/Spring_Boot-4.1.1-173B63?style=flat-square" />
<img alt="JPA e Hibernate" src="https://img.shields.io/badge/Persistencia-JPA%20%2F%20Hibernate-173B63?style=flat-square" />
<img alt="PostgreSQL 18" src="https://img.shields.io/badge/PostgreSQL-18-173B63?style=flat-square" />
<br />
<img alt="React Native" src="https://img.shields.io/badge/M%C3%B3vil-React_Native-287DAD?style=flat-square" />
<img alt="TypeScript" src="https://img.shields.io/badge/Lenguaje-TypeScript-287DAD?style=flat-square" />
<img alt="Expo SDK 57" src="https://img.shields.io/badge/Expo-SDK_57-287DAD?style=flat-square" />
<img alt="React y Vite" src="https://img.shields.io/badge/Web-React%20%2F%20Vite-287DAD?style=flat-square" />

<br />
<br />

[Comenzar](#comenzar) · [Estado](#estado-del-proyecto) · [Equipo](#equipo) · [Guía completa](#guia-completa) · [Informes](#informes)

</div>

---

## El proyecto

**ACOPIO** permite registrar recepciones de leche desde Android, conservarlas localmente y enviarlas al servidor para evaluar calidad, consultar trazabilidad y asignar un tanque de destino.

Proyecto académico contextualizado en **Leche Gloria**. Los datos y los umbrales **DEMO-1** son ficticios; no representan criterios oficiales de la empresa.

| 01 · Capturar | 02 · Evaluar | 03 · Consultar |
| :--- | :--- | :--- |
| Guardar en SQLite con usuario, centro y UUID. | Enviar manualmente; confirmar y evaluar sin duplicar. | Revisar resultado, QR y destino mediante la API compartida. |

## Estado del proyecto

**Corte de referencia: 17 de octubre de 2026.**

| Componente | Estado | Alcance actual |
| :--- | :--- | :--- |
| **Backend** | ✅ Implementado | Login, permisos, recepción, calidad, tanques, reportes y administración |
| **App móvil** | ✅ Implementada | Captura local, sesión, envío manual, calidad, QR y tanques |
| **Dashboard** | 🟡 Integración pendiente | Interfaz incorporada; operación aún con datos ficticios |
| **Aceptación integral** | 🟡 Por completar | Evidencia del mismo lote entre móvil, servidor y web |

> [!IMPORTANT]
> El dashboard de Fernando utiliza un login local y datos de demostración. Su consulta real actual es `/api/estado`. El backend ya ofrece las APIs para conectarlo.

**Últimas ejecuciones registradas:** 33 pruebas backend y 29 móviles aprobadas. Son resultados históricos, no un indicador CI en vivo ni una aceptación integral. [Ver evidencias →](#pruebas)

<details>
<summary><strong>Explorar los componentes y carpetas</strong></summary>

| Carpeta | Tecnología / responsabilidad | Estado |
|---|---|---|
| `backend/` | Java 17, Spring Boot 4.1.1, JPA/Hibernate, JWT, Flyway | API real; nueve entidades; 33 pruebas aprobadas en la última verificación |
| `mobile/` | React Native, Expo 57, TypeScript, MVVM, SQLite, SecureStore | Captura local, envío manual, calidad, QR y tanques |
| `dashboard/` | React, Vite, Bootstrap | Interfaz de Fernando; conexión de pantallas a APIs pendiente |
| `database/` | SQL de referencia del informe | No ejecutar sobre el esquema instalado por Flyway |
| `scripts/` | Preparación y operación Windows | Entorno local con puertos separados |
| `docs/` | Banner e informes PDF/Word | La documentación técnica está en este README |
| `.local/` | Base, secretos, cachés y logs de esta PC | Ignorada por Git; no compartir |

</details>

## Comenzar

### 1. Preparar el entorno

Requisitos: Java 17, Maven 3.9+, Node 24 LTS, PostgreSQL 18 y Git. Para móvil: Android con depuración USB autorizada y Expo Go compatible con SDK 57. Los scripts son para Windows; `ACOPIO_PG_BIN` y `ACOPIO_NODE` permiten indicar rutas alternativas.

```powershell
git clone https://github.com/serchiove/milk-traceability-offline.git
cd milk-traceability-offline
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Preparar.ps1
```

Si ya existe el entorno, no es necesario prepararlo nuevamente para cada arranque. Los lanzadores usan `.local/db-password.txt` y `.local/jwt-secret.txt`; `.env.example` documenta variables, no se carga automáticamente.

### 2. Arrancar, probar y detener

Desde la raíz del repositorio:

```powershell
.\Iniciar.cmd
# En otra terminal, con el celular conectado:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Conectar-Android.ps1
.\Abrir_Movil.cmd
# Cuando Metro esté listo, pulsar a.
```

| Servicio | Dirección |
|---|---|
| Dashboard | http://127.0.0.1:5173 |
| Diagnóstico API | http://127.0.0.1:18080/api/estado |
| PostgreSQL | 127.0.0.1:55440 · base/usuario acopio_dev |
| Metro | 127.0.0.1:8081 |

Después de cambios Java, ejecutar `.\Probar_Proyecto.cmd` para recompilar el JAR; `Iniciar.cmd` reutiliza el JAR existente. La compilación también comprueba web y tipos móviles. Las pruebas unitarias móviles se ejecutan aparte:

```powershell
Push-Location mobile
npm test
Pop-Location
```

Al terminar, Ctrl+C en Metro y luego `.\Detener.cmd`. No borra los datos. Detalles y solución de errores: [Inicio rápido](#inicio-detallado).

<details>
<summary><strong>Cuentas de demostración y acceso local</strong></summary>

| Uso | Identidad | Clave |
|---|---|---|
| API / app móvil OPERARIO | operario@gloria.com.pe | 123456 |
| API JEFATURA | jefatura@gloria.com.pe | 123456 |
| Dashboard actual de demostración | jefatura.demo | Cualquier texto de prueba; no autentica en backend |

Son cuentas ficticias de desarrollo. La contraseña de PostgreSQL es distinta y privada. El dashboard debe reemplazar su login local por el login real de JEFATURA según el [contrato](#contrato-compartido).

</details>

## Equipo

Las responsabilidades de mantenimiento no equivalen a autoría exclusiva. Aportes contrastados con el historial después de actualizar `origin` el 17/10/2026:

| Integrante | Aporte incorporado y comprobado | Referencias |
| :--- | :--- | :--- |
| Sergio | Entorno y esquema inicial; app móvil; integración, ampliaciones backend y migración JPA, con asistencia de Codex en este trabajo | `1489916`, `3bf07c9`, `c87f7c1`, `8f559fa` |
| Patricio | Base JWT, DTO, autenticación, recepción, reglas de calidad, repositorios y datos V3 | `17cc591`, `356ac1b` |
| Fernando | Interfaz y estilos del dashboard; aún utiliza datos operativos demo | `570d667`, PR #4 |
| Elías | Documentos de datos ficticios y matriz de 15 casos, aún pendientes de ejecución en su rama | `7d40673`, `2bbdf91`, `efb4135` |

El esquema inicial V1/V2 y JPA no se atribuyen a Elías por su rol de base de datos. Las ampliaciones del backend firmadas por Sergio no se atribuyen a Patricio por su rol de mantenedor. Los merges integran trabajo, no sustituyen la autoría de los commits. El Word detalla las evidencias y sus límites.

<a id="informes"></a>
## Informes del equipo

| Documento | Uso |
| :--- | :--- |
| [Pendientes de Fernando y Elías](docs/informes/Pendientes_Fernando_Elias.pdf) | Informe temporal de tareas y criterios de cierre; retirar al completar y conservar la evidencia |
| [Incidencias y aportes verificados](docs/informes/Incidencias_y_aportes_verificados.docx) | Registro en Word de problemas, correcciones, implementaciones y aportes reales por commit |

<a id="guia-completa"></a>
## Guía completa

Toda la documentación técnica se consulta aquí. Desplegar el apartado necesario; los informes del equipo son los dos archivos de la sección anterior.

[Inicio detallado y pgAdmin](#inicio-detallado) | [Arquitectura y organización](#arquitectura) | [Estado y alcance pendiente](#alcance) | [Pruebas y evidencias](#pruebas) | [Git y entregas](#github) | [Sesión y acceso móvil](#acceso) | [Correcciones históricas del backend](#historia-backend) | [Catálogos y consultas de lotes](#consultas) | [Tanques y asignación](#tanques) | [Integración móvil](#movil) | [Alineación con el informe oficial](#informe-oficial) | [Administración de catálogos](#administracion) | [Contrato dashboard y móvil](#contrato-compartido) | [Persistencia JPA e Hibernate](#jpa)

<a id="inicio-detallado"></a>
<details>
<summary><strong>Inicio detallado y pgAdmin</strong></summary>

## Computadora de Sergio
1. Trabajar siempre en esta carpeta `acopio-app` de Documents; evitar mezclarla con la copia del Desktop.
2. Abrir `Iniciar.cmd`: inicia PostgreSQL, backend y dashboard.
3. Abrir http://127.0.0.1:5173 y pulsar «Comprobar API».
4. Para Android, conectar USB con depuración autorizada y ejecutar desde PowerShell en esta carpeta:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Conectar-Android.ps1
```

5. Ejecutar `Abrir_Movil.cmd`, esperar que Metro esté listo y pulsar `a`.
6. Al terminar, pulsar Ctrl+C en Metro y ejecutar `Detener.cmd`.

| Archivo | Función |
|---|---|
| Iniciar.cmd | Arrancar base, backend y web |
| Abrir_Movil.cmd | Arrancar Expo para Android |
| Verificar.cmd | Consultar estado de servicios |
| Probar_Proyecto.cmd | Compilar backend/web y comprobar tipos del móvil |
| Detener.cmd | Detener los servicios del proyecto |

## Otra computadora
Requisitos: Java 17, Maven 3.9+, Node 24 LTS, PostgreSQL 18 y Git. Android requiere Expo Go compatible con SDK 57 y depuración USB, o emulador con ADB.
Descomprimir el paquete de código y ejecutar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Preparar.ps1
```

Después seguir los pasos de arranque. Cada computadora genera su propia base y contraseña; el paquete no incluye datos privados ni dependencias instaladas.
Los scripts buscan PostgreSQL en `C:\Program Files\PostgreSQL\18\bin`; usar `ACOPIO_PG_BIN` para otra ruta y `ACOPIO_NODE` para especificar Node.

## Puertos y errores
- Web: 5173. API: 18080. PostgreSQL: 55440. Metro: 8081.
- Diagnóstico: http://127.0.0.1:18080/api/estado.
- Logs locales: `.local/backend.log`, `.local/backend.error.log`, `.local/postgres.log`.
- Falta contraseña: preparar primero el entorno; no inventar un archivo de contraseña.
- Android no conecta: confirmar `adb devices`, volver a ejecutar Conectar-Android y mantener Metro abierto.
- No eliminar `.local/pgdata` ni ejecutar de nuevo el SQL del informe para reparar un error.
- `.env.example` es una referencia: los lanzadores usan la contraseña privada de `.local`, no cargan automáticamente ese archivo.


## Conectar PostgreSQL a pgAdmin

La base ya se crea en PostgreSQL mediante los scripts del proyecto. pgAdmin es una herramienta para administrarla; registrar la conexión permite ver la instancia existente.

1. Ejecutar Iniciar.cmd en la carpeta del proyecto y esperar a que los servicios estén disponibles.
2. Abrir pgAdmin. Hacer clic derecho en Servers, seleccionar Register y después Server.
3. En General, escribir Acopio Desarrollo como nombre.
4. En Connection, completar estos valores:

| Campo | Valor |
|---|---|
| Host name o address | 127.0.0.1 |
| Port | 55440 |
| Maintenance database | acopio_dev |
| Username | acopio_dev |
| Password | Contenido del archivo .local/db-password.txt de esta computadora |

5. Abrir el archivo de contraseña local y copiar su contenido sin espacios ni saltos de línea adicionales. No compartir esa contraseña ni incluirla en capturas, informes o GitHub. Cada computadora genera la suya.
6. Pulsar Save. Desplegar Servers → Acopio Desarrollo → Databases → acopio_dev → Schemas → acopio → Tables. Si es necesario, hacer clic derecho y seleccionar Refresh.
7. Deben aparecer nueve tablas: rol, centro_acopio, usuario, proveedor, vehiculo, tanque, lote_leche, registro_calidad e incidencia. Las tablas del proyecto están en acopio; public contiene el historial de migraciones de Flyway.

Si aparece connection timeout expired, confirmar que Iniciar.cmd terminó, revisar host 127.0.0.1 y puerto 55440 y ejecutar Verificar.cmd. Si continúa, revisar .local/postgres.log. Ese mensaje indica que no se alcanza el servidor; no exige recrear las tablas. Si aparece un error de autenticación, revisar usuario y contraseña local.
Al ejecutar Detener.cmd se detiene también esta instancia de PostgreSQL; para volver a conectarse desde pgAdmin, ejecutar Iniciar.cmd nuevamente. No confundir esta instancia con otros servidores de PostgreSQL que usen el puerto 5432.

[Volver al índice](#guia-completa)

</details>

<a id="arquitectura"></a>
<details>
<summary><strong>Arquitectura y organización</strong></summary>

## Flujo

Móvil (React Native / TypeScript / MVVM) → API REST Spring Boot → JPA/Hibernate → PostgreSQL. El móvil conserva borradores y catálogos en SQLite y su sesión en SecureStore. El dashboard React debe consumir la misma API como JEFATURA; actualmente sus pantallas operativas usan datos ficticios.

## Carpetas

| Ruta | Responsabilidad |
|---|---|
| mobile/src/view | Pantallas |
| mobile/src/viewmodel | Acciones y estado de pantalla |
| mobile/src/model | Datos y repositorio SQLite |
| mobile/src/services | Acceso HTTP, sesión, huella y envío |
| mobile/src/navigation | Recorrido del operario |
| backend/.../controller | Contratos HTTP y validación de entrada |
| backend/.../service | Negocio y límites transaccionales |
| backend/.../repository | EntityManager, consultas JPQL y bloqueos |
| backend/.../model | Nueve entidades JPA y sus relaciones |
| backend/.../DTO | Datos de entrada/salida; no exponer entidades |
| backend/.../security | JWT, identidad y permisos |
| backend/.../calidad | Motor y reglas DEMO-1 |
| backend/src/main/resources/db/migration | Fuente oficial del esquema, Flyway V1–V4 |
| dashboard/src | Interfaz de Fernando; main.jsx concentra actualmente las vistas |
| database | SQL del informe como referencia, no instalador adicional |

`backend/...` abrevia `backend/src/main/java/pe/edu/utp/acopio`.

## Decisiones

- El móvil guarda responsable, centro y solicitud antes del envío; confirma únicamente después de respuesta válida. La sincronización es manual.
- El servidor obtiene usuario y centro del JWT, verifica el estado actual y mantiene el aislamiento de consultas.
- UUID y SHA-256 permiten reintentar sin duplicar. Recepción y evaluación son transaccionales.
- Asignación: bloquear lote y luego tanque; el trigger reserva capacidad una vez. No hay vaciado, mezcla ni reasignación.
- Hibernate usa `ddl-auto=validate`, nunca crea o altera tablas; Flyway administra el esquema.
- Los catálogos de proveedores/vehículos son globales; los lotes y tanques pertenecen a un centro.
- No existe acceso directo del móvil o navegador a PostgreSQL.

Detalles: [JPA/Hibernate](#jpa) y [contrato compartido](#contrato-compartido).

[Volver al índice](#guia-completa)

</details>

<a id="alcance"></a>
<details>
<summary><strong>Estado y alcance pendiente</strong></summary>

Corte documental: 17/10/2026. Las marcas describen implementación; no sustituyen aceptación integral.

## Implementado

- [x] Backend: login BCrypt/JWT, permisos y validación por cuenta/centro.
- [x] Catálogos, recepción, huella, idempotencia y rollback.
- [x] Calidad DEMO-1, motivos, incidencia y contenido QR.
- [x] Consulta y asignación de tanques con capacidad y concurrencia.
- [x] Reportes JSON/CSV, indicadores y CORS.
- [x] Administración de proveedores y vehículos por JEFATURA.
- [x] Nueve entidades JPA/Hibernate; esquema administrado por Flyway.
- [x] App móvil: captura SQLite, sesión autorizada, envío manual y consultas centrales.
- [x] Interfaz del dashboard de Fernando incorporada a Git.

## Cierre del recorrido integrado

- [ ] Fernando: sustituir login y datos ficticios por APIs reales.
- [ ] Elías: corregir y ejecutar su matriz, completar resultado/evidencia.
- [ ] Equipo: aceptar un mismo lote móvil → PostgreSQL → dashboard con calidad, QR, tanque y CSV.
- [ ] Sergio/Elías: evidenciar offline, cierre/reapertura, reintento, sesión vencida y cámara.
- [ ] Patricio/Elías: documentar una instalación limpia y una actualización sin pérdida de datos.

El detalle operativo está en el [informe temporal](docs/informes/Pendientes_Fernando_Elias.pdf). Las pruebas automatizadas ya aprobadas no deben marcar esos pasos manuales como hechos.

## Mejoras separadas del piloto

Auditoría completa, renovación/recuperación de acceso, limitación de intentos, sincronización automática, cuenta de BD con privilegios mínimos, HTTPS, backups/restauración y medición de rendimiento. Mezclas, vaciados, trasvases y producción completa quedan fuera del alcance descrito en el informe oficial.

[Volver al índice](#guia-completa)

</details>

<a id="pruebas"></a>
<details>
<summary><strong>Pruebas y evidencias</strong></summary>

## Últimas comprobaciones registradas

| Fecha | Alcance | Resultado registrado |
|---|---|---|
| 17/10/2026 | Backend migrado a JPA, HTTP + PostgreSQL aislado | 33 pruebas aprobadas, JAR generado |
| 17/10/2026 | Suite móvil | 29 pruebas aprobadas; almacenamiento SQLite en memoria y HTTP simulado |
| 16/10/2026 | TypeScript y exportación Android | Correctos en la revisión de integración; no equivale a APK distribuible |
| 16/10/2026 | Android conectado | Calidad y tanque TQ-01 consultados desde el teléfono; no se confirmó asignación en esa comprobación |
| 17/10/2026 | Rama Elías efb4135 | 15 casos preparados; resultados/evidencias figuran pendientes |

Esta edición de documentación no vuelve a ejecutar ni renueva esas pruebas. Evidencia técnica: `backend/src/test`, `mobile/tests`, logs locales de verificación y relato de comprobación en la [bitácora](docs/informes/Incidencias_y_aportes_verificados.docx). Los logs privados no deben subirse completos si contienen datos sensibles.

## Ejecución automatizada

Desde la raíz, `.\Probar_Proyecto.cmd` prepara PostgreSQL de pruebas, ejecuta Maven verify, compila el dashboard y comprueba tipos móviles. Usa `acopio_test`, no los lotes de `acopio_dev`. Puede reiniciar el backend local para reemplazar el JAR.

Para la suite móvil adicional:

```powershell
Push-Location mobile
npm test
Pop-Location
```

Si falla una fase, no declarar la ejecución completa aprobada. Consultar el primer error y registrar el resultado obtenido.

## Aceptación manual compartida

1. Registrar versión/commit, fecha, PC y dispositivo; usar datos ficticios.
2. Iniciar servicios y entrar como OPERARIO en el móvil.
3. Crear lote con 100 L, 4 °C, 16 °D, 1,0300 g/mL. Guardar, enviar y registrar UUID.
4. Verificar APROBADO y QR con DEMO-1. Un dato bien formado fuera del rango produce RECHAZADO conservado, no HTTP 400 por calidad.
5. Asignar un tanque disponible del mismo centro, verificar incremento único y reconsulta sin duplicación.
6. Probar rechazo, falta de capacidad, centro ajeno y rol no autorizado.
7. Tras conectar el dashboard, consultar el mismo UUID como JEFATURA y contrastar litros, estado, destino, indicadores y CSV con PostgreSQL.
8. Probar captura sin backend manteniendo Metro disponible por USB; cerrar/reabrir y enviar al recuperar conexión. No confundir caída de Metro con modo offline de negocio.
9. Probar escaneo QR, permiso denegado e ingreso manual; sesión vencida y entrada inválida.
10. Completar la [plantilla](#entrega) con obtenido y evidencia. No marcar aprobado por inferencia.

## Consultas de comprobación en pgAdmin

```sql
SELECT * FROM acopio.lote_leche ORDER BY recibido_en DESC LIMIT 10;
SELECT * FROM acopio.registro_calidad ORDER BY fecha_evaluacion DESC NULLS LAST LIMIT 10;
SELECT * FROM acopio.tanque;
```

No insertar ni borrar lotes de presentación para probar casos destructivos. El error de la consulta antigua con `registro_calidad.fecha_hora` se corrigió: la columna real es `fecha_evaluacion`.

[Volver al índice](#guia-completa)

</details>

<a id="github"></a>
<details>
<summary><strong>Git y entregas</strong></summary>

Repositorio: https://github.com/serchiove/milk-traceability-offline
Rama principal: main.

## Obtener el proyecto en otra computadora

```powershell
git clone https://github.com/serchiove/milk-traceability-offline.git
cd milk-traceability-offline
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Preparar.ps1
```

Preparar.ps1 requiere Java 17, Maven 3.9+, Node 24 LTS, Git y PostgreSQL 18 instalados. Ver la sección Inicio detallado y pgAdmin.

## Trabajar en una función nueva

Con el árbol de trabajo limpio:

```powershell
git switch main
git pull --ff-only origin main
git switch -c feature/login-movil
```

Cambiar el nombre de rama según la función. Revisar git diff, ejecutar comprobaciones pertinentes, agregar solo los archivos de esa función y crear el commit. Publicar la rama y solicitar revisión antes de integrar en main.
No usar force push sobre main ni compartir credenciales. GitHub debe autenticar a cada integrante con su propia cuenta y acceso al repositorio.

## Qué se publica
Código fuente, archivos lock, migraciones, lanzadores y documentación. Se excluyen .local, contraseñas, archivos de entorno privados, dependencias instaladas y compilaciones. Las variables de ejemplo no contienen la contraseña real.
La carpeta del repositorio en GitHub es directamente la raíz del proyecto: backend, mobile y dashboard no están dentro de otra carpeta acopio-app.

[Volver al índice](#guia-completa)

</details>

<a id="acceso"></a>
<details>
<summary><strong>Sesión y acceso móvil</strong></summary>

## Backend implementado

`POST /api/auth/login`, con JSON `email` y `password`.
Consulta `acopio.usuario`, `acopio.rol` y `acopio.centro_acopio`. Comprueba BCrypt, usuario activo y centro activo. Una contraseña incorrecta, usuario inexistente o cuenta/centro inactivo devuelve 401 sin distinguir cuál falló.

Respuesta 200 compatible con `mobile/src/services/authService.ts`:

```json
{
  "accessToken": "TOKEN_GENERADO_POR_EL_BACKEND",
  "usuario": {
    "id": 1,
    "nombre": "Nombre del operario",
    "rol": "OPERARIO",
    "idCentro": 1,
    "centro": "Centro asignado"
  }
}
```

Los IDs son ejemplos; se obtienen de la base. El backend admite cuentas de OPERARIO y JEFATURA; la app móvil acepta únicamente OPERARIO.

## Estado de la app

El acceso móvil usa `/api/auth/login` por defecto. La dirección base se configura con `EXPO_PUBLIC_API_URL`. Perfil → Catálogos consulta proveedores, vehículos y centro con el token de la sesión. El token se conserva en Expo SecureStore hasta la expiración del JWT y la contraseña se limpia después del intento. La sesión vigente se restaura al reiniciar si existen los catálogos locales. Véase [alineación con el informe](#informe-oficial).

Las nuevas capturas y ediciones SQLite se asocian al usuario y centro autorizados y usan IDs de catálogo. Los registros antiguos sin responsable requieren vinculación explícita antes del envío. El acceso no envía automáticamente los borradores; la sincronización disponible es manual.

## Autorización

`POST /api/lotes` requiere `Authorization: Bearer TOKEN` y rol OPERARIO. Los IDs de usuario y centro se toman de la identidad autenticada, no del JSON enviado por el móvil. Cada petición con token comprueba que la cuenta y centro sigan activos y que no hayan cambiado rol o centro respecto del token.

401 indica autenticación ausente, inválida, vencida o invalidada por cambio de cuenta; 403 indica que el rol autenticado no permite esa operación. El backend no implementa todavía limitación de intentos/429 ni recuperación de contraseña.

## Configuración

`JWT_SECRET` es obligatorio y debe tener al menos 32 bytes. `scripts/Dev.ps1` genera una clave aleatoria por PC en `.local/jwt-secret.txt` cuando no se suministra por entorno. No debe publicarse ese archivo. `JWT_EXPIRATION_MS` es configurable y vale 86400000 por defecto. Al cambiar la clave se invalidan los tokens anteriores.

Para despliegue deben usarse HTTPS y credenciales propias; las cuentas de V3/V4 son solo demostración.

[Volver al índice](#guia-completa)

</details>

<a id="historia-backend"></a>
<details>
<summary><strong>Correcciones históricas del backend</strong></summary>

Registro histórico de esa entrega. Estado actual: [alineación](#informe-oficial) y [JPA/Hibernate](#jpa). Los conteos de pruebas y pasos de arranque inferiores corresponden a esa fecha.

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
- SHA-256 normalizado en el servidor. Posteriormente se incorporó cálculo en el móvil y verificación en servidor; ver el contrato vigente en 12.
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

La ampliación de catálogos y consulta central de lotes se encuentra documentada en [Catálogos y consultas de lotes](#consultas). La asignación de tanques está documentada en [Tanques y asignación](#tanques). Indicadores/reportes y envío manual móvil ya están implementados; ver [Alineación con el informe oficial](#informe-oficial). El móvil no envía borradores automáticamente. Administración de proveedores y vehículos: [Administración de catálogos](#administracion).

[Volver al índice](#guia-completa)

</details>

<a id="consultas"></a>
<details>
<summary><strong>Catálogos y consultas de lotes</strong></summary>

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

Esta ampliación no modificó migraciones ni registros de acopio_dev. Posteriormente se integraron las consultas al móvil y se implementaron tanques, indicadores, incidencias y reportes. Estado actualizado en [Alineación con el informe oficial](#informe-oficial); administración de proveedores y vehículos en [Administración de catálogos](#administracion). La integración del dashboard existente queda a cargo de su responsable.

[Volver al índice](#guia-completa)

</details>

<a id="tanques"></a>
<details>
<summary><strong>Tanques y asignación</strong></summary>

Implementado el 16 de octubre de 2026. No requiere nuevas migraciones: utiliza tablas y triggers del modelo original.

## Consulta

`GET /api/tanques` requiere token de OPERARIO o JEFATURA. Devuelve únicamente tanques del centro autenticado.

Parámetros: `pagina` (0 por defecto), `tamano` (25 por defecto, máximo 100), `disponibles` (false por defecto). `disponibles=true` devuelve únicamente tanques con estado DISPONIBLE y saldo positivo; el saldo debe compararse con el volumen del lote antes de elegirlo. La asignación vuelve a comprobarlo dentro de la transacción.

Formato paginado: elementos, total, pagina y tamano. Cada tanque contiene id, codigo, estado, capacidadLitros, volumenAsignadoLitros y disponibleLitros.

El volumen asignado es la reserva controlada por la base, no una medición física ni una lectura de sensores. El listado puede cambiar al producirse otras asignaciones.

## Asignación

`POST /api/lotes/{UUID}/asignacion-tanque`, con token de OPERARIO y cuerpo:

```json
{"idTanque": 1}
```

El ID es ilustrativo. El servidor toma el usuario y el centro del token. Requiere lote APROBADO, tanque del mismo centro, estado DISPONIBLE y saldo suficiente. No hay asignación parcial: un lote tiene un solo tanque.

Respuesta 201 para la primera asignación; 200 con idempotente=true para un reintento al mismo tanque. Incluye idLote, idTanque, codigo, volumenLitros, asignadoEn e idUsuarioAsigna. El reintento no cambia la fecha, responsable ni volumen reservado del registro original, aunque posteriormente el tanque esté lleno o en mantenimiento.

Errores:

- 400: cuerpo/UUID/ID inválido o paginación incorrecta.
- 401: autenticación ausente, inválida o vencida.
- 403: rol sin permiso; JEFATURA puede consultar pero no asignar.
- 404: lote o tanque inexistente o de otro centro.
- 409: lote sin aprobación, tanque no disponible, capacidad insuficiente o intento de reasignar a otro tanque.

## Concurrencia y trazabilidad

El servicio bloquea primero la fila del lote y después la del tanque, siempre en ese orden. La transacción conserva ambas hasta confirmar o revertir. El trigger original reserva el volumen; el servicio no incrementa el contador por separado. Esto evita doble reserva en reintentos y sobreasignación cuando llegan solicitudes simultáneas.

No se permiten reasignaciones, vaciados, mezclas ni trasvases. La consulta de detalle del lote refleja el tanque y la fecha de asignación.

## Verificación

`mvn verify`: 24 pruebas aprobadas y JAR generado, utilizando una base PostgreSQL aislada. Incluye asignación válida, reintentos, lotes rechazados, mantenimiento, capacidad insuficiente, aislamiento entre centros, permisos y dos asignaciones concurrentes que compiten por capacidad insuficiente para ambas.

Actualización: las pantallas móviles de calidad y tanques ya consumen estas rutas. Los indicadores, incidencias y reportes del backend también están implementados; consultar [Alineación con el informe oficial](#informe-oficial). La integración del dashboard existente corresponde a su responsable.

[Volver al índice](#guia-completa)

</details>

<a id="movil"></a>
<details>
<summary><strong>Integración móvil</strong></summary>

Estado actualizado y recorrido completo: [Alineación con el informe oficial](#informe-oficial).

El acceso usa POST /api/auth/login, los catálogos se descargan a SQLite y la sesión se conserva en SecureStore hasta su vencimiento. La captura ya selecciona IDs oficiales y guarda responsable/centro en la misma transacción del lote. No hay captura nueva anónima.

Desde el detalle se envía manualmente conservando UUID, contenido y huella SHA-256. Perfil incluye consulta central de calidad, lectura/generación visual de QR y asignación de tanques. El backend expone reportes CSV e indicadores para que los consuma el dashboard existente de jefatura, cuya interfaz no se modifica.

EXPO_PUBLIC_API_URL configura el backend; por USB, scripts/Conectar-Android.ps1 redirige el puerto 18080 y el puerto 8081 de Expo. Reiniciar Expo después de instalar dependencias o cambiar variables. El backend debe recompilarse para exponer las rutas nuevas.

[Volver al índice](#guia-completa)

</details>

<a id="informe-oficial"></a>
<details>
<summary><strong>Alineación con el informe oficial</strong></summary>

Referencia: INTEGRADOR AVANCE 2 FINAL (1).pdf, 96 páginas. Revisión de implementación: 16/10/2026.

## Distribución de responsabilidades

- CU-01 (pp. 44–45): captura móvil con sesión autorizada, catálogos descargados, UUID, fecha y responsable. La app descarga proveedores, vehículos y centro al iniciar sesión. La edición se aísla por usuario y centro. Guardar confirma en una transacción SQLite el lote y su solicitud de envío, incluyendo sus IDs oficiales y responsable.
- CU-02 (pp. 45–46): envío manual con UUID y huella SHA-256, conservación ante fallos e idempotencia. La huella se calcula en el móvil; Java la recalcula y verifica. El campo es opcional en la API para compatibilidad con clientes antiguos. La respuesta del servidor distingue recepción de aprobación.
- CU-03 (pp. 47–48): Perfil → Tanques de destino muestra lotes aprobados. El operario consulta tanques de su centro y confirma uno. El servidor valida disponibilidad y capacidad y reserva volumen transaccionalmente. La app consulta la asignación actual antes de repetir; un error no se presenta como éxito. No se implementan mezcla, vaciado, trasvase ni reasignación.
- CU-04 (pp. 48–49): Perfil → Resultados de calidad o Buscar por identificador permite consultar información central, mediciones, estado, motivo, QR y destino. La cámara lee QR; si no se autoriza o no es legible, queda disponible el ingreso manual de UUID o ACOPIO:UUID.
- CU-05 (p. 50): el backend expone indicadores e incidencias para JEFATURA mediante /api/reportes y ocupación mediante /api/tanques. El dashboard existente debe consumir estas rutas; no se modifica su implementación ni se acredita su integración desde este trabajo.
- CU-06 (pp. 51–52): API JSON para vista previa filtrada por periodo de captura, estado y búsqueda de proveedor/placa/UUID; API CSV para exportación desde PostgreSQL. Hasta 10 000 registros por consulta; se exige acotar el periodo si se supera. El centro se restringe al autorizado en la cuenta; el esquema actual no tiene autorización multicentro.
- QR (p. 74): PostgreSQL conserva el contenido ACOPIO:UUID, exclusivamente para aprobados. La app genera la matriz visual, con margen blanco, usando qrcode-generator. No se almacena una imagen binaria en PostgreSQL.

## Sesión y operación offline

El primer inicio de sesión requiere conexión. El token y los datos de sesión se guardan con Expo SecureStore; nunca se guarda la contraseña. La vigencia offline termina en la expiración del JWT (configuración backend predeterminada: 24 horas). Cerrar sesión elimina el acceso guardado; mantiene los lotes y ediciones. La revocación en el servidor se detecta al comunicarse; no puede comprobarse mientras el equipo está desconectado.

Los catálogos descargados viven en SQLite, asociados a usuario y centro. Se actualizan con cada inicio de sesión online. El servidor vuelve a validar las referencias al recibir. No se implementa aún renovación de token ni sincronización automática en segundo plano. La sincronización disponible es manual desde el detalle.

Los lotes antiguos se conservan. Los que no tenían responsable oficial requieren vinculación explícita antes del envío; no se adivinan IDs por nombres. La edición antigua sin responsable se conserva en su tabla original, sin importarla automáticamente a una cuenta. Las nuevas ediciones están separadas por operario/centro.

## Contrato de la huella

UTF-8 → SHA-256 hexadecimal minúsculo de:

UUID|idProveedor|idVehiculo|idUsuario|idCentro|instanteUTC|volumen|temperatura|acidez|densidad

Números sin ceros decimales finales. Fecha UTC compatible con java.time.Instant; milisegundos cero se omiten. Los valores de usuario y centro vienen de la sesión autenticada y el backend vuelve a determinarlos. La solicitud guardada no cambia tras un intento, aunque no haya confirmación HTTP.

## Indicadores y CSV

GET /api/reportes y GET /api/reportes/csv: solo JEFATURA. Filtros desde/hasta inclusivos en America/Lima sobre fecha de captura, estado y buscar. Lectura consistente de PostgreSQL para cada consulta. El CSV vuelve a consultar con los filtros de la vista previa: puede incluir cambios confirmados después de esa vista. Incluye identificación, responsable, procedencia, mediciones, resultado, motivo, reglas, tanque y contenido QR. Escapa comillas/saltos de línea y neutraliza fórmulas en campos textuales.

Volumen = suma de litros de los lotes filtrados. Aprobación = aprobados / total de lotes filtrados. Incidencias = lotes distintos con al menos una incidencia / total filtrado. Sin resultados, indicadores cero. El listado de incidencias proviene de incidencia y registro_calidad; no se simula a partir de mensajes de pantalla. La ocupación mostrada corresponde al presente, no a una reconstrucción histórica por fecha.

## Decisiones y límites frente al informe

Los umbrales DEMO-1 siguen siendo demostrativos, como advierte el informe (p. 9). No equivalen a criterios oficiales de Gloria. El esquema de nueve tablas no incluye auditoría detallada RF-14; el informe la identifica como mejora futura (pp. 53 y 75). El entorno USB utiliza HTTP local de desarrollo; el despliegue integrado debe configurar HTTPS. Rendimiento <2 segundos, dispositivos reales y concurrencia de producción requieren medición dedicada; compilar no acredita esos requisitos.

## Prueba de aceptación

1. Reiniciar backend recompilado y Expo. Mantener PostgreSQL y los registros existentes; no reinstalar ni borrar los datos de la app.
2. Iniciar sesión móvil con operario@gloria.com.pe / 123456 (solo datos ficticios de desarrollo). Esperar la descarga de catálogos.
3. Crear una recepción seleccionando proveedor/vehículo oficiales. Guardar 100 L, 4 °C, 16 °D, 1,0300 g/mL. Enviar desde el detalle. Debe confirmarse y aprobarse con DEMO-1.
4. Entrar a Perfil → Resultados de calidad: consultar el lote y comprobar los datos reales, reglas y QR.
5. En Tanques de destino abrir el aprobado, seleccionar uno con capacidad y confirmar. Actualizar y comprobar que conserva el destino; reconsultar no incrementa de nuevo la ocupación.
6. Probar un rechazo: debe conservarse y mostrar el motivo, sin QR ni acción de asignación.
7. Mostrar un QR en otro dispositivo y escanearlo, autorizando la cámara. Probar también el UUID manual y un identificador inexistente.
8. Para probar offline, mantener Expo accesible (por USB) y detener solo el backend o interrumpir su acceso. Mantener sesión vigente, guardar un lote y cerrar/reabrir la app. Debe conservarse. Al volver el backend, enviar el mismo registro. No desconectar Metro si se usa Expo Go: es el servidor de desarrollo, distinto del backend.
9. Con una sesión JEFATURA, probar GET /api/reportes y GET /api/reportes/csv con los mismos filtros. Comparar con PostgreSQL. La conexión de estas rutas al dashboard existente corresponde a su responsable; su interfaz no se modifica aquí.
10. Probar sesión vencida y cuenta de otro centro: no deben enviar ni consultar datos ajenos. Los datos locales nuevos de otro operario no aparecen en el historial de la cuenta actual.

La cámara y la presentación en el teléfono deben comprobarse manualmente. Las pruebas automatizadas de móvil usan SQLite real en memoria y respuestas HTTP simuladas; las del backend usan PostgreSQL aislado, nunca los lotes de acopio_dev.

[Volver al índice](#guia-completa)

</details>

<a id="administracion"></a>
<details>
<summary><strong>Administración de catálogos</strong></summary>

Implementado el 17/10/2026. Ampliación exclusivamente del backend. Requiere JWT de una cuenta activa JEFATURA. OPERARIO recibe 403 y una petición sin autenticación recibe 401.

Base: `/api/administracion/catalogos`. Los catálogos son globales en el modelo actual: una modificación afecta a todos los centros. No existe propiedad por centro de proveedores ni vehículos.

| Método | Ruta relativa | Resultado |
|---|---|---|
| GET | /proveedores o /vehiculos | Activos e inactivos, con `buscar`, `pagina` (0), `tamano` (25, máximo 100) |
| POST | /proveedores o /vehiculos | Crea activo, devuelve 201 y el registro con ID |
| PUT | /proveedores/{id} o /vehiculos/{id} | Actualiza datos editables, devuelve 200 |
| PATCH | /proveedores/{id}/estado o /vehiculos/{id}/estado | Desactiva o reactiva, devuelve 200 |

Proveedor (POST y PUT):

```json
{"tipoDocumento":"DNI","numeroDocumento":"12345678","razonSocial":"Proveedor de demostración","estadoCert":"PENDIENTE"}
```

DNI exige 8 dígitos, RUC 11. Nombre obligatorio, máximo 180 caracteres. Estado documental: PENDIENTE, VIGENTE o VENCIDO; es un dato administrativo, no una certificación verificada. El documento no cambia con PUT; para otra identidad se crea otro proveedor y se desactiva el anterior. El nombre y estado documental sí son editables.

Vehículo (POST y PUT):

```json
{"placa":"ABC-123","capacidadLitros":5000.00}
```

Placa: hasta 12 caracteres alfanuméricos, espacios internos o guiones; se recortan extremos y convierte a mayúsculas. No se impone un formato nacional. Capacidad positiva, máximo 10 enteros y 2 decimales. PUT cambia la capacidad, no la placa.

Estado (PATCH):

```json
{"activo":false}
```

Reactivar: `{"activo":true}`. Repetir el mismo estado es seguro. No se implementa eliminación física. Un registro inactivo conserva su documento/placa reservados; duplicarlo devuelve 409. Las restricciones únicas de PostgreSQL también protegen contra altas concurrentes.

Errores: 400 datos inválidos; 404 ID inexistente; 409 documento/placa duplicado o intento de cambiar identidad. Las respuestas no exponen SQL ni contraseñas.

## Efecto en la recepción y trazabilidad

Las rutas existentes `/api/catalogos/proveedores` y `/api/catalogos/vehiculos` siguen devolviendo solamente activos. Un catálogo descargado antes de una desactivación puede conservarlo temporalmente en el celular: el servidor rechaza nuevas recepciones con referencias inactivas. Los reintentos de una recepción ya confirmada siguen siendo idempotentes.

Los lotes, mediciones, resultados y claves de referencia existentes no se borran ni cambian. Las consultas históricas muestran el nombre actual del proveedor, porque el esquema no almacena versiones del nombre; esta ampliación no añade auditoría ni instantáneas históricas. La última edición confirmada prevalece si dos jefaturas editan el mismo registro.

## Prueba

En Postman: iniciar sesión JEFATURA, usar `Authorization: Bearer <accessToken>`, crear, listar, editar, desactivar y reactivar. Comprobar que un OPERARIO no puede administrar. El móvil conserva sus rutas actuales; no se agregó una pantalla administrativa al dashboard.

Las pruebas automatizadas usan PostgreSQL aislado (`acopio_test`) y HTTP real: permisos, validación, duplicados, normalización de placa, edición, desactivación/reactivación y conservación/reintento de un lote recibido tras desactivar el proveedor.

Verificación del 17/10/2026: `mvn -o verify` completado con 30 pruebas aprobadas y JAR actualizado. Para utilizarlo, iniciar el entorno con `Iniciar.cmd`. No se crearon proveedores ni vehículos de prueba en `acopio_dev`.

[Volver al índice](#guia-completa)

</details>

<a id="contrato-compartido"></a>
<details>
<summary><strong>Contrato dashboard y móvil</strong></summary>

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
| Administración | /api/administracion/catalogos | Contrato en Administración de catálogos |

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

[Volver al índice](#guia-completa)

</details>

<a id="jpa"></a>
<details>
<summary><strong>Persistencia JPA e Hibernate</strong></summary>

Migración realizada el 17/10/2026. Se conserva Java 17, Spring Boot, PostgreSQL, los contratos REST y las migraciones Flyway V1–V4. No requiere recrear la base ni borrar datos.

## Organización

`model` representa las nueve tablas del esquema `acopio`:

| Entidad | Tabla | Relaciones |
|---|---|---|
| Rol | rol | Perfil de acceso |
| CentroAcopio | centro_acopio | Centro de trabajo y recepción |
| Usuario | usuario | Rol y centro |
| Proveedor | proveedor | Identidad documental del proveedor |
| Vehiculo | vehiculo | Placa y capacidad nominal |
| Tanque | tanque | Centro y capacidad reservada |
| LoteLeche | lote_leche | Proveedor, vehículo, operario, centro, tanque y usuario que asignó |
| RegistroCalidad | registro_calidad | Relación uno a uno con lote |
| Incidencia | incidencia | Relación muchos a uno con registro de calidad |

Las relaciones se cargan de forma diferida (`LAZY`). No hay cascadas de eliminación. Los repositorios generan DTO para las respuestas; no se serializan entidades ni relaciones Hibernate al cliente. Usuario mantiene métodos de lectura compatibles con la autenticación y carga rol/centro explícitamente antes de cerrar la transacción.

Los repositorios usan `EntityManager` administrado con `@PersistenceContext`. Esto es JPA real con Hibernate como proveedor; no son interfaces `JpaRepository`. Se eligieron repositorios explícitos para mantener consultas, proyecciones y bloqueos bajo control. El starter es `spring-boot-starter-data-jpa`.

## Consultas y escritura

- Catálogos, autenticación, trazabilidad, tanques e incidencias usan JPQL y entidades.
- Administración crea entidades con `persist`; las ediciones se guardan mediante seguimiento de cambios y `flush` dentro de la transacción.
- Calidad se crea como entidad; la transición PENDIENTE → resultado usa actualización JPQL condicional, conservando la regla de una única evaluación.
- El único SQL de negocio nativo que permanece es la inserción del lote con `ON CONFLICT (id_lote) DO NOTHING`, ejecutada por EntityManager. Permite que dos reintentos concurrentes con el mismo UUID no aborten la transacción antes de comparar la huella.
- El diagnóstico también mantiene una consulta SQL nativa a `information_schema`, porque no es una entidad de negocio.
- El código de producción no utiliza JdbcTemplate. Las pruebas sí lo utilizan para preparar datos y comprobar PostgreSQL independientemente de JPA.

## Transacciones y triggers

Spring utiliza `JpaTransactionManager`. La recepción, mediciones y evaluación se confirman juntas o se revierten juntas. Reportes conserva aislamiento REPEATABLE_READ.

La asignación bloquea primero el lote y después el tanque con `PESSIMISTIC_WRITE`. PostgreSQL sigue validando centro, aprobación y capacidad, e incrementa el contador con su trigger. Java no incrementa el contador por segunda vez.

`codigoQr`, `recibidoEn` y `volumenAsignadoLitros` se mapean como campos de lectura para las escrituras de Hibernate. Después de evaluar o asignar, se vacía el contexto de persistencia para volver a leer QR, fecha de asignación y contador calculados por los triggers; no se reutiliza una entidad desactualizada.

La consulta de lotes conserva PENDIENTE cuando todavía no hay registro de calidad, igual que la vista SQL anterior. Las restricciones únicas siguen resolviendo duplicados y se traducen a HTTP 409, también cuando Hibernate envuelve la excepción SQL.

## Esquema y ejecución

```properties
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false
spring.jpa.properties.hibernate.jdbc.time_zone=UTC
```

Flyway es el responsable del esquema. Hibernate valida que las tablas y columnas coincidan, pero no ejecuta `create`, `update` ni `create-drop`. `open-in-view=false` impide depender de una sesión abierta mientras se serializa la respuesta HTTP.

Después de compilar, iniciar con `Iniciar.cmd`. No cambiar credenciales, reinstalar la app ni recrear PostgreSQL. Móvil y dashboard conservan las rutas y los formatos documentados en [Contrato dashboard y móvil](#contrato-compartido); el dashboard de demostración sigue necesitando que su responsable conecte las APIs.

## Verificación

Pruebas HTTP con PostgreSQL aislado cubren autenticación, roles, aislamiento por centro, administración, duplicados, recepción concurrente, huellas, rollback, evaluación, QR, asignación concurrente y capacidad, filtros, CSV y CORS. Se añadieron verificaciones del proveedor Hibernate, las nueve entidades, el gestor transaccional JPA y la proyección de lotes sin evaluación.

La migración no incorpora nuevas funciones de negocio: auditoría completa, renovación de tokens y despliegue HTTPS siguen siendo trabajos separados.

Resultado del 17/10/2026: `mvn -o verify` finalizado con 33 pruebas aprobadas, cero fallos y JAR generado en `backend/target/acopio-0.0.1-SNAPSHOT.jar`. Se ejecutó sobre `acopio_test`, no sobre los lotes de desarrollo. No se modificaron los archivos del móvil ni del dashboard durante esta migración.

[Volver al índice](#guia-completa)

</details>

<a id="base-datos"></a>
<details>
<summary><strong>SQL de referencia y cuidado de la base</strong></summary>

`database/modelo_original_informe.sql` conserva el modelo del informe como referencia. La instalación se realiza exclusivamente con Flyway en `backend/src/main/resources/db/migration`. No ejecutar ese SQL sobre la base preparada ni modificar migraciones aplicadas. Cada PC conserva sus datos y secretos en `.local`, fuera de Git.

</details>

<a id="entrega"></a>
<details>
<summary><strong>Registrar una entrega o prueba</strong></summary>

Copiar este formato en el PR o en la evidencia de ejecución; no hace falta crear otro Markdown:

```text
Responsable:
Fecha y commit:
Función o incidencia:
Pasos y datos de entrada:
Resultado esperado:
Resultado obtenido:
Evidencia sin secretos:
Pendientes o limitaciones:
```

No subir `.local`, claves, JWT, `.env`, dependencias ni datos personales. Una prueba no ejecutada debe figurar pendiente.

</details>

---

<div align="center">

**ACOPIO · Proyecto Integrador · Equipo 4**

Registro local. Evaluación central. Trazabilidad compartida.

</div>
