# Estado de pruebas — 09/10/2026

## Evidencia disponible
| Comprobación | Resultado / origen |
|---|---|
| Backend: compilación y prueba de integración | Aprobada en revisión anterior; 9 tablas, 59 columnas y 2 migraciones |
| Dashboard: compilación | Aprobada en revisión anterior |
| Móvil: TypeScript | Aprobado en revisión anterior |
| Restricciones SQL | Casos ejecutados en base QA separada, con rollback de datos de prueba |
| Dashboard: fallo y recuperación del backend | Comprobado en revisión anterior |
| Web → API → PostgreSQL | Captura del usuario: conectada, 9 tablas y centro leído |
| Android → API | Captura del usuario: PostgreSQL conectado, 9 tablas |
| Android → SQLite | Captura del usuario: 3 comprobaciones guardadas |
| Persistencia al cerrar/reabrir | Pendiente de confirmación del usuario |

<<<<<<< HEAD
## Mantenimiento — 22/11/2026

| Comprobación | Resultado |
|---|---|
| Respaldo custom de PostgreSQL y lectura con `pg_restore --list` | Aprobado; archivo local creado en `.local/backups` |
| Restauración integral en una base temporal distinta | Aprobada; 9 tablas y 3 migraciones Flyway exitosas; base temporal eliminada y `acopio_dev` intacta |
| Retención de cinco días | Aprobada con un archivo vencido de prueba; se eliminó solo el archivo de respaldo vencido |
| Tarea diaria de Windows a las 2:00 AM | Instalada y ejecutada manualmente desde el Programador de tareas; resultado `0`, próximo inicio según horario |

El procedimiento y los límites de recuperación están en [Mantenimiento y recuperación](07_MANTENIMIENTO.md). Los respaldos comprobados son locales; configurar una copia externa y probar recuperación desde esa copia siguen siendo tareas manuales.

La organización de carpetas/documentación no vuelve a ejecutar las pruebas anteriores ni convierte su evidencia en una nueva ejecución.
=======
La organización de carpetas/documentación no vuelve a ejecutar estas pruebas ni convierte evidencia anterior en una nueva ejecución.
>>>>>>> ba7c9f4 (feat(mobile): initialize mobile app with Expo and SQLite integration)

## Comprobación manual corta
1. Iniciar el entorno; comprobar conexión real desde web.
2. Abrir Android por USB; comprobar API real.
3. Guardar prueba SQLite y anotar el contador.
4. Cerrar completamente y reabrir; guardar otra prueba: debe aumentar en uno respecto al contador anotado.
5. Ejecutar Verificar.cmd. Para validar cambios de código, ejecutar Probar_Proyecto.cmd.

## Pruebas al desarrollar funciones
Registrar entrada, acción, resultado esperado y resultado obtenido. Cubrir permisos, campos inválidos, error de servidor y duplicados, además del caso exitoso. Para sincronización, comprobar desconexión, reinicio, reintento y ausencia de duplicados.
El diagnóstico actual no prueba autenticación, captura de lotes ni sincronización operativa.
