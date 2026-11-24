# Mantenimiento y recuperación

## Alcance

El proyecto guarda PostgreSQL en `.local/pgdata`, una carpeta local excluida de Git. Los respaldos se guardan por defecto en `.local/backups`; tampoco se publican en Git. No copies ni compartas `pgdata`, `db-password.txt` ni los archivos de respaldo.

El script `scripts/Maintenance.ps1` respalda la base `acopio_dev` en formato PostgreSQL custom, valida el archivo, elimina respaldos vencidos y permite verificar una restauración en una base temporal separada. La prueba nunca restaura encima de `acopio_dev`.

> `.local/backups` está en el mismo disco que la base local. Para protegerse de pérdida o daño del equipo, copia periódicamente los respaldos a otro disco o almacenamiento privado; el respaldo local por sí solo no es una copia externa.

## Respaldo manual

Desde la raíz del proyecto:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Maintenance.ps1 -Action Backup
```

El script toma la ruta de PostgreSQL de `ACOPIO_PG_BIN` si existe; de lo contrario, usa `C:\Program Files\PostgreSQL\18\bin`. Si PostgreSQL está detenido, el script inicia la instancia local para hacer el respaldo y la detiene al terminar. Si ya estaba funcionando, no la detiene.

El resultado es un archivo `acopio_<fecha>.dump` en `.local/backups`. El respaldo solo se considera correcto cuando `pg_dump` finaliza y `pg_restore --list` puede leer el archivo. Después de crear un respaldo válido, se eliminan únicamente archivos `acopio_*.dump` con más de cinco días. El registro queda en `.local/backups/maintenance.log`.

Para guardar respaldos en otra ruta, usa `-BackupDirectory`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Maintenance.ps1 -Action Backup -BackupDirectory "E:\Respaldos\Acopio"
```

## Programación automática

La tarea elegida para este equipo se instala con:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Maintenance.ps1 -Action InstallSchedule -RetentionDays 5
```

Windows programa `Acopio-PostgreSQL-Backup` todos los días a las 2:00 AM, con cinco días de retención. La tarea conserva la ruta de las herramientas PostgreSQL detectada al instalarla. Se ejecuta con el usuario actual cuando ha iniciado sesión; si el equipo estaba suspendido, Windows intenta ejecutarla al reanudarse. Revisa el historial de la tarea en el Programador de tareas y el registro en `.local/backups/maintenance.log`.

Para cambiar la ruta o la retención, vuelve a ejecutar `InstallSchedule` con los valores deseados; la tarea existente se reemplaza. Para quitar la tarea:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Maintenance.ps1 -Action RemoveSchedule
```

## Prueba de recuperación

Después de crear un respaldo, prueba el más reciente:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Maintenance.ps1 -Action TestRestore
```

También se puede verificar un archivo específico:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Maintenance.ps1 -Action TestRestore -BackupPath ".\.local\backups\acopio_<fecha>.dump"
```

El script valida el formato, crea `acopio_restore_check_<identificador>`, restaura el respaldo, comprueba que haya tablas del esquema `acopio` y migraciones exitosas en `public.flyway_schema_history`, y elimina la base temporal. Si falla la restauración, el error queda en la consola y en el registro; la base original no se modifica.

## Recuperación en una instalación local

La restauración anterior es una prueba aislada. Para recuperar datos en una base local sin arriesgar la actual:

1. Detén el proyecto con `Detener.cmd` y conserva una copia del respaldo fuera de `.local/pgdata`.
2. No borres ni recrees `.local/pgdata` para intentar recuperar datos: contiene toda la instancia y su configuración local.
3. Usa el script `TestRestore` para comprobar el respaldo en una base temporal. Para conservar una copia recuperada que puedas revisar independientemente, crea una base nueva (por ejemplo, `acopio_recovered`) con `createdb -h 127.0.0.1 -p <PUERTO> -U acopio_dev acopio_recovered` y restáurala con `pg_restore --exit-on-error --no-owner --no-privileges -h 127.0.0.1 -p <PUERTO> -U acopio_dev -d acopio_recovered "ruta\al\respaldo.dump"`. Sustituye `<PUERTO>` por el puerto configurado en `ACOPIO_DB_PORT` o `.local/db-port.txt` (por defecto, 55440). Ambos comandos usan las herramientas de PostgreSQL 18 y te solicitarán la contraseña local.
4. Verifica primero esa base restaurada; no apuntes la aplicación a ella ni reemplaces `acopio_dev` hasta confirmar que los datos son los correctos.
5. Si necesitas que la aplicación vuelva a usar esos datos, coordina un cambio de nombre de las bases con el equipo: detén todos los clientes, renombra `acopio_dev` para conservarla como respaldo y renombra la base recuperada a `acopio_dev`. Conserva la original hasta validar la aplicación; si el cambio falla, vuelve a su nombre original.
6. Ejecuta `Probar_Proyecto.cmd` y `Verificar.cmd`; confirma las migraciones, las tablas y la conexión antes de volver a usar la aplicación.

No uses este procedimiento sobre una base existente con datos que deban conservarse. La restauración de producción o una migración entre equipos requiere una base de destino, credenciales y un plan de recuperación coordinados por separado.

## Criterios de mantenimiento

- Conservar al menos un respaldo válido fuera del equipo.
- Verificar diariamente el resultado de la tarea y atender cualquier error.
- Ejecutar `TestRestore` después de configurar respaldos y luego de cambios relevantes en la base.
- Registrar fecha, nombre del respaldo, resultado de restauración y responsable en la evidencia de entrega.
