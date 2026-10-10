# Informe del backend compartido

Responsable: Patricio. Fecha de corte: 09 de octubre de 2026.

## Propósito y alcance
El backend centraliza el acceso de la aplicación móvil y el dashboard a PostgreSQL. Debe autenticar usuarios, aplicar permisos, recibir lotes, evaluar calidad y coordinar transacciones. Hoy implementa conexión de diagnóstico y migraciones del esquema; los servicios de negocio todavía están pendientes.

## Qué tenemos implementado
La aplicación usa Java 17, Spring Boot 4.1.1 y Maven. Integra Spring JDBC, validación, Flyway y Actuator. La estructura inicial separa Controller, Service y Repository, con inyección de dependencias.
EntornoController recibe GET /api/estado; EntornoService arma la respuesta; EntornoRepository consulta information_schema para contar las tablas de acopio y recupera los centros activos mediante JdbcTemplate.
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
