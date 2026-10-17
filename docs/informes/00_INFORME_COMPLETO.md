# Informe completo del estado del proyecto Acopio

Equipo: Sergio, Fernando, Patricio y Elías. Curso: Integrador I. Fecha de corte: 09 de octubre de 2026.

## Resumen ejecutivo
Disponemos de un entorno de desarrollo con tres componentes separados: aplicación móvil, dashboard web y backend compartido. Ambos clientes consultan una API real que accede a PostgreSQL. La aplicación móvil también guarda comprobaciones en SQLite. Esta base permite comenzar la implementación operativa, pero todavía no registra recepciones, autentica usuarios ni sincroniza lotes.
El proyecto aborda la recepción y trazabilidad de leche en centros de acopio. El recorrido previsto comprende captura, conservación local ante desconexión, envío confirmado, evaluación de calidad, asignación de tanque y consulta administrativa. La implementación debe conservar las unidades, relaciones y reglas acordadas en la documentación académica.

## Arquitectura y responsabilidades
La aplicación móvil utiliza una separación inicial MVVM entre vista, ViewModel y repositorio local. El dashboard utiliza React con acceso a la API. El backend Spring Boot separa Controller, Service y Repository. PostgreSQL es la base central y SQLite el almacenamiento local móvil. MVVM describe la aplicación móvil; no es el nombre de toda la arquitectura del sistema.
La comunicación actual utiliza HTTP local: dashboard 5173, API 18080, PostgreSQL 55440 y Metro 8081. El enlace Android por USB usa adb reverse. La configuración actual es de desarrollo y no constituye despliegue de producción.

| Integrante | Componente | Carpeta principal |
|---|---|---|
| Sergio | Aplicación móvil | mobile |
| Fernando | Dashboard web | dashboard |
| Patricio | Backend y API | backend |
| Elías | Base de datos y pruebas | migraciones del backend y database |

## Estado global
| Entregable | Estado |
|---|---|
| Entorno local y lanzadores Windows | Implementado |
| Esquema de nueve tablas y migraciones iniciales | Implementado |
| Diagnóstico web y API real | Implementado y observado |
| Diagnóstico móvil y escritura SQLite | Observado en capturas del usuario |
| Persistencia SQLite después de cerrar y reabrir | Pendiente de confirmar |
| Autenticación y permisos | Pendiente |
| Registro de lotes mediante API | Pendiente |
| Motor de calidad en Java | Pendiente |
| Restricciones SQL de calidad y asignación | Implementadas; no sustituyen servicios API |
| Cola offline y sincronización sin duplicados | Pendiente |
| Dashboard de negocio, QR visual y reportes | Pendiente |

## Evidencia de verificación
Las revisiones anteriores registraron compilación del backend, prueba de integración del esquema, compilación del dashboard y comprobación de tipos del móvil aprobadas. Se probaron restricciones SQL en una base QA separada y recuperación del dashboard tras fallo del backend.
Las capturas más recientes aportadas por Sergio muestran API conectada a PostgreSQL con nueve tablas en web y móvil, y tres comprobaciones locales SQLite. La persistencia después de cerrar la app todavía requiere confirmación. Este informe documenta esa evidencia; su generación no vuelve a ejecutar todas las pruebas.

## Relación con la documentación académica
Se mantienen como antecedentes el informe acumulado, diagramas BPMN de Bizagi, modelo ER y físico, diccionario de datos, SQL, casos de uso, arquitectura, cronograma y prototipo. No todos esos artefactos están incluidos en este repositorio de código ni han sido revalidados contra una última versión del informe durante esta preparación. Las funciones dibujadas o simuladas deben identificarse como propuestas hasta integrarse con los servicios reales.
El informe de estado sirve para organizar la implementación y puede adaptarse al formato académico requerido. No reemplaza por sí solo el informe IEEE acumulado ni certifica el cumplimiento de una rúbrica no revisada en esta preparación.

# Informe de la aplicación móvil

Responsable: Sergio. Fecha de corte: 09 de octubre de 2026.

## Propósito y alcance
La aplicación está destinada al operario de descarga. El objetivo del desarrollo es capturar la recepción de leche, conservar los registros cuando no hay conexión y enviarlos al backend compartido al recuperar conectividad. Actualmente funciona una pantalla de diagnóstico técnico; el flujo de recepción todavía está pendiente.

## Qué tenemos implementado
El proyecto usa React Native 0.86.3, React 19.2.3, Expo SDK 57 y TypeScript. Se ejecuta en Android mediante Expo Go. Esta modalidad permite desarrollar y probar, pero no constituye un APK independiente de distribución.
La organización inicial sigue MVVM. App.tsx presenta la vista; useEntornoViewModel administra estados y acciones; diagnosticoRepository encapsula el acceso a SQLite. La vista no consulta directamente PostgreSQL.
La acción Comprobar API real realiza GET /api/estado con un límite de espera de diez segundos y presenta conexión o error. La dirección predeterminada es http://127.0.0.1:18080 y puede configurarse con EXPO_PUBLIC_API_URL.
La acción Guardar prueba en SQLite abre acopio_desarrollo.db, crea comprobacion_local si no existe, inserta la fecha y consulta la cantidad acumulada. Los registros actuales son comprobaciones técnicas, no lotes de leche.

## Evidencia y límites
La captura aportada por Sergio muestra PostgreSQL conectado, nueve tablas y tres comprobaciones almacenadas en el dispositivo. Esto confirma el recorrido de diagnóstico y escritura local observado. Falta confirmar la persistencia después de cerrar completamente y reabrir la aplicación.
La comprobación de tipos pasó en la revisión anterior. La conexión actual por USB depende de adb reverse en los puertos 18080 y 8081 y de Metro en ejecución. No se ha probado un recorrido completo de negocio sin conexión.

## Archivos que debe mantener Sergio
- mobile/App.tsx: pantalla y representación del estado.
- mobile/src/viewmodel/useEntornoViewModel.ts: acciones de API y guardado local.
- mobile/src/model/diagnosticoRepository.ts: almacenamiento de diagnóstico.
- mobile/package.json y package-lock.json: dependencias y versiones.
- mobile/app.json: configuración Expo.

## Trabajo que falta
1. Implementar acceso de operario, cierre de sesión y manejo seguro de la sesión según el contrato acordado con Patricio.
2. Consultar catálogos de proveedores y vehículos, y confirmar el centro del usuario autenticado.
3. Crear formulario de volumen en litros, temperatura en grados Celsius, acidez en grados Dornic y densidad en g/mL, con validaciones y errores por campo.
4. Generar el UUID del lote una sola vez y conservarlo en todos los reintentos.
5. Crear tablas locales de lotes y estados de sincronización separadas de comprobacion_local. Definir sus migraciones y recuperación después de reinicios.
6. Implementar envío, reintento y confirmación. Marcar sincronizado solo cuando el servidor confirme el registro; conservar errores y conflictos para revisión.
7. Mostrar resultado de evaluación, motivo de rechazo y trazabilidad de acuerdo con la respuesta del backend.

## Dependencias y coordinación
Sergio necesita que Patricio defina autenticación, catálogos, creación y consulta de lotes. Deben acordar nombres de campos, unidades, fechas, respuestas y códigos de error antes de conectar pantallas. Elías prepara datos ficticios para probar proveedores, vehículos, centros y tanques.
La interfaz puede validar campos para ayudar al operario, pero la autorización y la decisión de calidad deben verificarse en el servidor. No se deben usar las cuentas simuladas del prototipo como acceso real.

## Criterios de aceptación
La primera entrega móvil queda terminada cuando un operario autorizado accede y obtiene sus catálogos desde la API. La siguiente requiere registrar un lote desde el celular y verlo en el dashboard. La entrega offline exige registrar sin conexión, cerrar y reabrir, recuperar conexión y comprobar que existe exactamente un lote en el servidor, incluso después de reintentos.

## Cómo ejecutar y presentar
Iniciar el proyecto con Iniciar.cmd. Conectar Android con depuración USB autorizada, ejecutar scripts/Conectar-Android.ps1 y después Abrir_Movil.cmd. Esperar que Metro esté listo y pulsar a. Mostrar la comprobación de API y SQLite y explicar que el flujo de negocio se implementará sobre esta base.


# Informe del dashboard web

Responsable: Fernando. Fecha de corte: 09 de octubre de 2026.

## Propósito y alcance
El dashboard está destinado a la jefatura de planta. Su objetivo es permitir consultar recepciones, revisar calidad, visualizar incidencias y acceder a trazabilidad e indicadores. La implementación actual consiste en una pantalla de diagnóstico conectada al backend real.

## Qué tenemos implementado
El cliente usa React 19.3.0, Vite 8.3.4 y Bootstrap 5.3.8. La interfaz actual muestra estado de la API, motor de base de datos, número de tablas y un catálogo de centros recibido desde PostgreSQL a través de Spring Boot.
El botón Comprobar conexión real consulta /api/estado. Vite redirige /api y /actuator al backend local del puerto 18080. El navegador no tiene credenciales de PostgreSQL ni acceso directo a la base.
La pantalla identifica los datos como ficticios de desarrollo. Muestra un centro académico de Arequipa con capacidad nominal de 10 000 litros. Esa capacidad es un atributo del catálogo; no representa litros recibidos hoy ni ocupación actual.
Cuando falla la consulta, el cliente limpia los datos anteriores y muestra un error. En la revisión anterior se comprobó que, al reiniciar el backend y volver a consultar, recupera los datos.

## Evidencia y límites
La compilación de producción pasó en la revisión anterior. La captura de Sergio muestra API conectada, PostgreSQL, nueve tablas y el catálogo de centros. Todavía no existen indicadores operativos, filtros de lotes, reportes reales ni autenticación de jefatura.
Las pantallas del prototipo del avance académico sirven como referencia visual y funcional; sus datos simulados no están integrados en este dashboard.

## Archivos que debe mantener Fernando
- dashboard/src/main.jsx: interfaz actual y consulta de diagnóstico.
- dashboard/src/style.css: estilos.
- dashboard/vite.config.js: proxy y configuración de desarrollo.
- dashboard/package.json y package-lock.json: scripts y dependencias.

## Trabajo que falta
1. Crear acceso de jefatura y navegación protegida coordinados con el backend.
2. Implementar listado y detalle de lotes con búsqueda, filtros y estados de carga, vacío y error.
3. Mostrar aprobado, rechazado y pendiente con texto visible, sin depender solo del color.
4. Integrar incidencias, motivo de rechazo y consulta de trazabilidad por código o QR.
5. Mostrar indicadores calculados por consultas reales, con definición del período y centro que cubren.
6. Añadir reportes cuando exista un contrato de API acordado y validación de permisos.
7. Mantener una interfaz adaptable a distintas resoluciones y una jerarquía visual consistente con la app móvil.

## Dependencias y coordinación
Patricio debe proporcionar endpoints protegidos, filtros y respuestas estables. Elías prepara escenarios de prueba y verifica que los indicadores correspondan a los datos. Sergio registra lotes desde el móvil para probar el recorrido integrado.
La separación propuesta para ampliar el cliente es features por módulo, services para llamadas API y components para elementos compartidos. Estas carpetas se crean al implementar cada función, no como prueba de que ya existe.

## Criterios de aceptación
La jefatura autenticada debe consultar solo los datos autorizados. Un lote registrado en el móvil debe aparecer con el mismo identificador, mediciones y evaluación. Los filtros y totales deben coincidir con los registros de prueba; una caída del backend debe producir un error claro y permitir recuperación sin conservar información engañosa.

## Cómo ejecutar y presentar
Ejecutar Iniciar.cmd y abrir http://127.0.0.1:5173. Mostrar el botón de comprobación y el catálogo leído mediante la API. Durante desarrollo, Vite recarga los cambios de interfaz. Ejecutar Probar_Proyecto.cmd antes de integrar cambios que requieran la comprobación completa.


# Informe del backend compartido

Responsable: Patricio. Fecha de corte: 09 de octubre de 2026.

## Propósito y alcance
El backend centraliza el acceso de la aplicación móvil y el dashboard a PostgreSQL. Debe autenticar usuarios, aplicar permisos, recibir lotes, evaluar calidad y coordinar transacciones. Hoy implementa conexión de diagnóstico y migraciones del esquema; los servicios de negocio todavía están pendientes.

## Qué tenemos implementado
La aplicación usa Java 17, Spring Boot 4.1.1 y Maven. Integra JPA/Hibernate, validación, Flyway y Actuator. La estructura inicial separa Controller, Service y Repository, con inyección de dependencias.
EntornoController recibe GET /api/estado; EntornoService arma la respuesta; EntornoRepository consulta information_schema para contar las tablas de acopio y recupera los centros activos mediante EntityManager y entidades JPA.
La respuesta contiene estado, baseDatos, tablas, centros y alcance. Los datos proceden de consultas reales, pero el diagnóstico no evalúa todas las funciones de negocio. /actuator/health permite verificar la salud del servicio.
El servidor escucha en 127.0.0.1:18080. La configuración toma host, puerto, nombre, usuario y contraseña de base mediante variables de entorno. Flyway crea el esquema con V1 y carga dos roles y un centro ficticio con V2. La limpieza de Flyway está deshabilitada.

## Evidencia y límites
La compilación y empaquetado pasaron en la revisión anterior. La prueba de integración verificó nueve tablas, 59 columnas y dos migraciones. También se comprobó que el dashboard recupera conexión después de detener y reiniciar el backend.
No existen aún endpoints de login, proveedores, vehículos, lotes, evaluación, asignación de tanques ni reportes. El endpoint de diagnóstico actual no implementa autorización; debe mantenerse como herramienta local de desarrollo.

## Archivos que debe mantener Patricio
- backend/pom.xml: dependencias y versión Java.
- backend/src/main/java/pe/edu/utp/acopio/controller: recepción HTTP.
- backend/src/main/java/pe/edu/utp/acopio/service: coordinación y futuras transacciones.
- backend/src/main/java/pe/edu/utp/acopio/repository: consultas a PostgreSQL.
- backend/src/main/resources/application.properties: configuración sin secretos.
- backend/src/main/resources/db/migration: migraciones coordinadas con Elías.
- backend/src/test/java/pe/edu/utp/acopio/AcopioApplicationTests.java: integración del esquema.

## Trabajo que falta
1. Definir contratos de API, DTOs, validaciones y formato de errores para ambos clientes.
2. Implementar autenticación con contraseñas protegidas, gestión de sesión y autorización por rol y centro. No confiar en un id_usuario enviado por el cliente como prueba de identidad.
3. Implementar catálogos y transacción de recepción: insertar lote y mediciones pendientes de forma atómica.
4. Calcular SHA256 de una representación canónica acordada del contenido. Ante UUID repetido, comparar huella: mismo contenido confirma el original; contenido distinto devuelve conflicto.
5. Implementar evaluación de temperatura, acidez y densidad con umbrales confirmados, versión de reglas y decisión final única. Las restricciones SQL no sustituyen ese motor.
6. Implementar asignación de tanque mediante la actualización prevista del lote, dejando que la base valide centro, estado y capacidad dentro de la misma transacción.
7. Crear consultas de trazabilidad, indicadores y reportes autorizados, con filtros y límites claros.
8. Añadir pruebas de permisos, transacciones, reintentos y concurrencia apropiadas para los servicios de negocio.

## Coordinación con la base
V1 ya incluye protección de datos originales, evaluación final inmutable, reserva de capacidad y generación de contenido QR o incidencia al persistir un resultado. El backend debe respetar ese contrato y evitar duplicar efectos, por ejemplo creando una segunda incidencia además de la del trigger.
Patricio y Elías acuerdan nuevas migraciones sin alterar V1/V2 aplicadas. Para desplegar, deben separar propietario y cuenta de aplicación y restringir privilegios; la cuenta actual es exclusivamente de desarrollo.

## Criterios de aceptación
Las peticiones inválidas o no autorizadas se rechazan sin escrituras parciales. La repetición de una recepción idéntica no duplica lotes; UUID con contenido diferente produce conflicto. Un resultado final no se reevalúa silenciosamente. Dos asignaciones concurrentes no exceden la capacidad del tanque.

## Cómo ejecutar y presentar
Iniciar.cmd ejecuta el JAR compilado. Después de modificar Java, usar Probar_Proyecto.cmd: recompila y reinicia el backend del proyecto si estaba activo. Mostrar /api/estado y explicar el recorrido Controller, Service, Repository y PostgreSQL. Revisar .local/backend.log y backend.error.log ante fallos, sin compartirlos si contienen información privada.


# Informe de base de datos y pruebas

Responsable: Elías. Fecha de corte: 09 de octubre de 2026.

## Propósito y alcance
PostgreSQL conserva usuarios, origen de las recepciones, lotes, mediciones, evaluación y destino de acopio. Su función es mantener relaciones e integridad, mientras el backend autentica y aplica las reglas de negocio. El esquema físico de nueve entidades ya está incorporado mediante Flyway.

## Modelo implementado
- rol: perfiles y descripción.
- centro_acopio: centro, región, capacidad nominal y disponibilidad.
- usuario: rol, centro de trabajo, identidad, correo, hash de contraseña y disponibilidad.
- proveedor: documento, razón social, estado documental y disponibilidad.
- vehiculo: placa, capacidad nominal y disponibilidad.
- tanque: centro, código, capacidad, volumen reservado y estado.
- lote_leche: UUID, referencias de origen, fechas, volumen, huella, QR y asignación opcional.
- registro_calidad: una medición por lote, temperatura, acidez, densidad, estado, fecha, versión y motivo.
- incidencia: referencia a evaluación rechazada y detalle de alerta.

El modelo contiene 59 columnas. V1 crea tablas, índices, funciones, triggers y v_trazabilidad; V2 incorpora dos roles y un centro ficticio. No crea usuarios de acceso, proveedores ni lotes operativos.
La temperatura se expresa en grados Celsius, acidez en grados Dornic y densidad en g/mL. Las capacidades y volúmenes se expresan en litros. La capacidad nominal del centro o vehículo no equivale a ocupación diaria calculada.

## Integridad ya implementada
Las claves foráneas mantienen referencias. Se controla unicidad de correos sin distinguir mayúsculas, documentos de proveedores, placas y códigos de tanque por centro. Las mediciones excluyen valores nulos o incompatibles con las restricciones básicas; esos límites no son criterios de aprobación sanitaria.
El UUID es la clave de lote. La base conserva los datos originales y prohíbe eliminar lotes o mediciones mediante las operaciones protegidas. La evaluación final es inmutable y el rechazo exige motivo.
Al persistir APROBADO se asigna el contenido ACOPIO seguido del UUID como código QR; esto no genera una imagen QR. Al persistir RECHAZADO se crea la incidencia desde el trigger.
La primera asignación de tanque exige lote aprobado, tanque del mismo centro, estado disponible y capacidad suficiente. El contador de volumen asignado es una reserva técnica; el piloto no modela descarga física, mezclas, vaciado ni reasignación.

## Entorno y archivos
La instancia local usa 127.0.0.1:55440, base y usuario acopio_dev. Los datos y la contraseña permanecen en .local, fuera de Git. Esta instancia no reemplaza las instalaciones existentes del usuario.
La fuente de instalación es backend/src/main/resources/db/migration. database/modelo_original_informe.sql se conserva como referencia y no debe ejecutarse encima del esquema preparado.
Cada modificación posterior requiere nueva migración con versión coordinada con Patricio. No modificar V1 o V2 ya aplicadas ni compartir el directorio pgdata.

## Pruebas disponibles y evidencia
La prueba de integración del backend verificó tablas, columnas y migraciones. En la revisión anterior se ejecutaron casos SQL en una base QA separada, con rollback de los datos de prueba: asignación aprobada, reintento sin doble conteo, bloqueo por capacidad, centro o mantenimiento, bloqueo de pendientes/rechazados, conservación de mediciones y evaluación final, QR e incidencia.
Las capturas del usuario confirman web y móvil consultando el backend y guardado local de diagnóstico. La persistencia SQLite después de cerrar/reabrir queda pendiente. Las pruebas de SQL no demuestran autenticación ni sincronización de la aplicación, que todavía no están implementadas.

## Trabajo que falta
1. Preparar datos ficticios de usuarios con hashes válidos generados por el backend, proveedores, vehículos y tanques.
2. Coordinar migraciones, privilegios y cambios de esquema con Patricio.
3. Mantener una matriz de casos con entrada, acción, resultado esperado, resultado obtenido y evidencia.
4. Probar autenticación por rol/centro, validaciones, recepción atómica, UUID repetido y contenido distinto, calidad y asignación concurrente.
5. Verificar el recorrido móvil a servidor a dashboard y los totales de indicadores.
6. Probar persistencia local, pérdida de conexión, reintento y recuperación después de reinicio cuando la cola offline exista.

## Criterios de aceptación
Las migraciones se aplican en una base nueva y los cambios se agregan sin destruir datos existentes. Un caso inválido no deja escrituras parciales ni altera el saldo. Los resultados se pueden repetir con datos ficticios. Ninguna prueba de negocio debe ejecutarse sobre datos de presentación sin identificar y controlar su impacto.

## Preparación y comprobación
En otra máquina ejecutar scripts/Preparar.ps1 con requisitos instalados. Verificar.cmd consulta el entorno; Probar_Proyecto.cmd ejecuta las comprobaciones de compilación e integración preparadas. Registrar resultados de nuevas pruebas con fecha, sin presentar resultados históricos como ejecuciones recientes.

# Integración y próximas entregas

## Secuencia de implementación
1. Patricio y Elías acuerdan contrato de autenticación, datos ficticios y catálogos. Sergio y Fernando preparan acceso y navegación por rol.
2. Implementar un recorrido completo: Sergio captura un lote, Patricio lo guarda con sus mediciones en una transacción y Fernando lo consulta. Elías verifica identidad, campos, unidades y persistencia.
3. Añadir evaluación con reglas versionadas y umbrales confirmados. Mostrar resultados e incidencias sin duplicar los efectos de los triggers.
4. Añadir asignación de tanque, consulta de trazabilidad e indicadores con pruebas de capacidad y permisos.
5. Incorporar cola SQLite, reintentos e idempotencia; probar desconexión, cierre, reapertura y sincronización sin duplicados.

## Acuerdos para trabajar juntos
Cada función debe tener un contrato de API y datos de ejemplo antes de conectar clientes. El identificador del usuario proviene de la sesión validada; el centro y los permisos se comprueban en el servidor. Los errores deben distinguir validación, falta de autorización, conflicto y fallo de infraestructura.
Reservar versiones de migración entre Patricio y Elías. Conservar archivos lock. Trabajar en ramas por función y revisar cambios antes de integrarlos; el commit inicial solicitado se incorpora en main. No publicar claves, .local, bases, node_modules ni compilaciones.

## Repositorio y ejecución
Repositorio de destino: https://github.com/serchiove/milk-traceability-offline. La carpeta raíz contiene backend, dashboard, mobile, database, docs y scripts. El historial existente debe preservarse mediante un commit descendiente de main, sin force push.
En cada equipo instalar Java 17, Maven 3.9+, Node 24 LTS, PostgreSQL 18 y Git. Ejecutar scripts/Preparar.ps1, después Iniciar.cmd. Android requiere Expo Go compatible y autorización USB. Las instrucciones completas y los puertos están en docs/01_INICIO_RAPIDO.md.

## Limitaciones que deben mantenerse visibles
El entorno es local. No hay todavía autenticación real, HTTPS de despliegue, APK independiente, cuenta PostgreSQL de mínimos privilegios ni sincronización de lotes. El modelo piloto no incluye mezclas, vaciados o reasignaciones. No introducir esas funciones sin acordar cambios de alcance y migraciones.

## Resultado esperado del siguiente avance
El primer hito operativo será demostrar un usuario autorizado que registra un lote desde Android y una jefatura que consulta exactamente ese lote en web. Ese recorrido proporciona una base comprobable para agregar calidad, trazabilidad y trabajo sin conexión.


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
