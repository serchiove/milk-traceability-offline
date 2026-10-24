# Verificacion adicional de Elias - 24/10/2026

## Version y entorno
- Proyecto descargado en ZIP de feature/elias-pruebas-actualizadas-3, actualizada con main.
- Se agregaron dos pruebas locales a BackendFlowTests.java. Falta registrar el commit de publicacion.
- La huella SHA-256 del archivo probado esta en evidencias/2026-10-24/pruebas-adicionales-sha256.txt.
- PostgreSQL real: 18.6; base automatizada acopio_test; Java 17.0.20.1.

## Resultados automaticos
- Antes de agregar las dos pruebas: 40 aprobadas, sin fallos, errores ni omitidas (2 de aplicacion, 35 de flujos y 3 del exportador).
- Despues de agregarlas: ejecucion focalizada de las 2 nuevas, ambas aprobadas, sin fallos, errores ni omitidas; BUILD SUCCESS, 24/10/2026 a las 12:36:13 -05:00.
- No se ha ejecutado una suite completa de 42 pruebas en una sola corrida.
- Vehiculo inactivo: nueva recepcion devuelve 400, sin filas nuevas de lote ni calidad; la recepcion anterior sigue consultable.
- Reporte y CSV: incluyen 00:00:00 y 23:59:59 de Lima; excluyen el segundo anterior y las 00:00:00 del dia siguiente.

## Comprobacion manual web
- Lote: 010aba18-ba9e-4c57-adb2-875abf7768f7.
- Coinciden con las evidencias anteriores del movil, API y PostgreSQL: 120.50 L, 4.50 C, 16 D, 1.0300 g/mL, APROBADO y TQ-01.
- Ocupacion mostrada de TQ-01: 220.50 L; disponibles: 4779.50 L.
- UUID, estado y fechas combinados: un registro; CSV con el mismo lote y mediciones.
- Fecha que excluye el lote: cero registros y CSV solo con encabezados.
- Ampliar el rango hasta el dia de captura vuelve a incluir el lote.
- Filtrar ese UUID aprobado como RECHAZADO devuelve cero registros.
- Matriz actualizada: 24 casos aprobados para los alcances y versiones indicados en cada fila.

## Comprobaciones web con problemas
- Detalle por UUID: al cambiar de lote con Network grabando y el filtro Fetch/XHR activo, no se registro una nueva consulta GET /api/lotes/{UUID}. La pantalla anuncia esta integracion como pendiente.
- QR: en la vista revisada aparece su contenido como texto, sin una imagen QR escaneable. No se aprobo su lectura desde la web.
- Selector de periodo: al seleccionar Hoy, Ultimos 7 dias y Ultimos 30 dias no se registraron nuevas consultas en Network y se mantuvieron los mismos resultados. Hoy tambien mostraba lotes del dia anterior.
- Exportacion CSV sin conexion simulada: la solicitud fallo y la aplicacion mostro "Failed to fetch" en un aviso verde. El error debe distinguirse visualmente de una operacion exitosa. Se restauro No throttling al terminar.
- Estas comprobaciones no aprueban la aceptacion integrada, aunque los casos de la matriz tengan resultados aprobados para sus alcances y versiones.

## Comprobaciones aun pendientes
- Consulta de mas de 25 tanques y actualizacion de ocupacion despues de una nueva asignacion desde el movil. No se ejecutaron estas comprobaciones en esta revision.
- Repetir el recorrido offline completo con un nuevo lote sobre la version actualizada. En esta revision se contrasto el lote conservado del recorrido anterior.
- Repetir las comprobaciones web con problemas cuando sus correcciones esten disponibles y registrar el commit probado.

## Evidencias
Los informes, capturas y CSV de esta verificacion estan en evidencias/2026-10-24.
Las evidencias anteriores permanecen en evidencias/2026-10-23.
## Recorrido nuevo comprobado - 24/10/2026
- Se guardo un nuevo lote en el celular mientras la API estaba inaccesible al retirar la redireccion USB del puerto 18080. No se simulo desconexion total de internet.
- El envio fallo mientras la API no estaba disponible. Al restaurar la redireccion, se envio el mismo registro.
- UUID comprobado: af77a42b-7b39-46a3-91db-6e370f004b08.
- Resultado esperado y obtenido en movil, API, PostgreSQL, dashboard y CSV: 50.00 L, temperatura 4.00 C, acidez 16.00 D, densidad 1.0300 g/mL, APROBADO y tanque TQ-01.
- PostgreSQL devolvio una fila en la consulta del lote con su calidad y tanque.
- La ocupacion de TQ-01 paso de 220.50 L a 270.50 L despues de asignar los 50.00 L desde el movil.
- El dashboard mantuvo la ocupacion anterior durante la observacion; mostro 270.50 L despues de recargar la pagina.
- Evidencias directas: movil-nuevo-lote-api-con-tanque.json y movil-nuevo-lote-postgresql-con-tanque.txt, en evidencias/2026-10-24.
- Esta comprobacion completa el recorrido nuevo que figuraba pendiente en el apartado anterior. La actualizacion de ocupacion se comprobo despues de recargar, sin confirmar actualizacion automatica.
- La aceptacion web sigue abierta por los problemas registrados de periodos, detalle por UUID, QR y aviso de error de exportacion.
- La consulta de mas de 25 tanques sigue sin probarse: el codigo revisado solicita solamente pagina=0 y tamano=25.
