# Implementación alineada al informe oficial

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
