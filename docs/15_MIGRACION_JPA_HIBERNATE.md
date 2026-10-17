# Persistencia JPA/Hibernate

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

Después de compilar, iniciar con `Iniciar.cmd`. No cambiar credenciales, reinstalar la app ni recrear PostgreSQL. Móvil y dashboard conservan las rutas y los formatos documentados en `14_CONTRATO_DASHBOARD_Y_MOVIL.md`; el dashboard de demostración sigue necesitando que su responsable conecte las APIs.

## Verificación

Pruebas HTTP con PostgreSQL aislado cubren autenticación, roles, aislamiento por centro, administración, duplicados, recepción concurrente, huellas, rollback, evaluación, QR, asignación concurrente y capacidad, filtros, CSV y CORS. Se añadieron verificaciones del proveedor Hibernate, las nueve entidades, el gestor transaccional JPA y la proyección de lotes sin evaluación.

La migración no incorpora nuevas funciones de negocio: auditoría completa, renovación de tokens y despliegue HTTPS siguen siendo trabajos separados.

Resultado del 17/10/2026: `mvn -o verify` finalizado con 33 pruebas aprobadas, cero fallos y JAR generado en `backend/target/acopio-0.0.1-SNAPSHOT.jar`. Se ejecutó sobre `acopio_test`, no sobre los lotes de desarrollo. No se modificaron los archivos del móvil ni del dashboard durante esta migración.
