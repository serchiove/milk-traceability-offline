# Registro de evidencias de monitoreo de ACOPIO

**Responsable:** Elías Jhonny Ccama Ynca  
**Fecha:** 22 de noviembre de 2026, hora de Perú (UTC−5). Los nombres de los JSON usan UTC.  
**Versión probada:** `bb4f9fed409df0603a4c58180d9c251185eed6a5`.  
**Entorno:** Windows, Java 17.0.20.1 y PostgreSQL 18.6. Las pruebas de recepción y conflicto se ejecutaron en `acopio_test`.

| ID | Comprobación | Resultado | Evidencia |
|---|---|---|---|
| MON-01 | Salud de la API y conexión a PostgreSQL | 3 de 3 rondas correctas. Ambas rutas devolvieron HTTP 200; salud `UP` y diagnóstico de 9 tablas. | [Sondeo normal](evidencias/sondeo-2026-11-23T00-00-53-907Z-27f8dded.json) |
| MON-02 | Detección de un puerto sin servicio | El monitor registró `ERROR` y devolvió código 2 en el puerto 18089. Al consultar el puerto correcto, 18080, volvió a obtener HTTP 200. ACOPIO permaneció encendido. | [Fallo controlado](evidencias/sondeo-2026-11-23T00-04-34-682Z-5443f9b9.json) y [comprobación posterior](evidencias/sondeo-2026-11-23T00-04-51-437Z-74586a86.json) |
| MON-03 | Registros INFO y WARN | `INFO` para recepciones confirmadas. `WARN` al enviar el mismo UUID con otro volumen. La prueba confirmó HTTP 409 y que el volumen original no cambió. | [INFO](evidencias/recepciones-log-info.txt) y [WARN](evidencias/recepciones-log-warn.txt) |
| MON-04 | Tiempo de registro de lotes | 20 de 20 registros exitosos, 0 fallos y 0 registros de 2 segundos o más. Percentil 95: 41,619 ms. Máximo: 55,825 ms. Se excluyó el calentamiento. | [Resumen](evidencias/recepciones-7a66d7b9-4177-420c-b603-813c39883ac4/recepciones-resumen.txt) y [CSV](evidencias/recepciones-7a66d7b9-4177-420c-b603-813c39883ac4/recepciones.csv) |
| MON-05 | Uso del heap de Java | Tres lecturas de 113,44, 113,58 y 115,44 MiB sobre un máximo de 3 944 MiB: 2,88 %, 2,88 % y 2,93 %. | [Lecturas de memoria](evidencias/java-memoria.txt) |
| MON-06 | Estado de calidad de los lotes medidos | PostgreSQL devolvió `APROBADO` para los 20 UUID del CSV. Pendiente contrastar el conteo con el reporte del dashboard. | [Consulta a PostgreSQL](evidencias/lotes-medidos-calidad.txt) |
| MON-07 | Comprobación tras incorporar los cambios a `main` | Pendiente de integración. | — |

La meta de menos de 2 segundos se cumplió en la prueba local, con un usuario a la vez. El resultado no mide el comportamiento con varios usuarios simultáneos ni en producción.
