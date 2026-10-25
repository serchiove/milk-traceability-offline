# Verificación de las correcciones del recorrido

Fecha: 24 de octubre de 2026.

## Cambios incluidos

- El acceso, Inicio y la pantalla Conexión comparten una comprobación real de `/api/estado`. Muestran su fecha y permiten reintentar; se vuelve a comprobar al regresar a la app.
- El selector de período del dashboard aplica fechas locales al resumen y comparte los filtros con los reportes y las exportaciones. También permite consultar todo el historial y reconoce un rango personalizado.
- El envío conjunto muestra avance, confirmaciones, resultados de calidad y motivos de fallo por UUID. El reintento conserva el cuerpo y el identificador; un rechazo de calidad confirmado cuenta como enviado.
- Catálogos permite actualizar la copia de captura sin cerrar sesión. Solo reemplaza la copia anterior después de descargar y validar proveedores, vehículos y centro. Conserva el borrador y los registros locales.
- Inicio y Registros identifican los datos de la cuenta en este celular. Central muestra la fecha de su última consulta correcta. El dashboard identifica el centro, muestra fechas de consulta y recarga cada 30 segundos mientras está visible, al recuperar el foco o por petición manual.
- El acceso se adapta a pantallas estrechas con tamaño de texto ampliado.
- El dashboard conserva la sesión vigente, la pantalla, los filtros y el lote seleccionado al recargar la misma pestaña. La copia se elimina al cerrar sesión o al vencer el token; la API sigue validando el acceso. No guarda la contraseña.
- Trazabilidad muestra una imagen QR descargable generada localmente desde el código confirmado por el backend. Los lotes rechazados, pendientes o sin código no generan un QR.
- La revisión de recepción presenta vehículo y centro en líneas que se ajustan al ancho disponible, para admitir nombres largos.

## Resultados

| Comprobación | Resultado |
| --- | --- |
| `flutter analyze --no-pub` | Sin observaciones |
| Conexión, servicios, repositorio y validación Flutter | 35 pruebas aprobadas |
| Interfaz Flutter: acceso, captura, revisión con nombres largos, cierre de sesión y accesibilidad | 6 pruebas aprobadas |
| Fechas, sesión y QR del dashboard con `node --test test/filters.test.js test/session.test.js test/qr.test.js` | 11 pruebas aprobadas |
| Dashboard con `npm run build` | Compilación correcta |
| Android con `flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:18080` y Java 17 | APK generado correctamente |

Las comprobaciones Flutter se ejecutaron por grupos. Las pruebas usan respuestas HTTP controladas y bases SQLite temporales; no se ejecutó la prueba de contrato que crea recepciones en PostgreSQL.

El usuario confirmó el recorrido manual con el teléfono y aportó cuatro capturas. Muestran la revisión de una recepción de 120 L, su conservación local, un intento fallido por falta de conexión y un lote aprobado asignado a TQ-01 en el dashboard. El lote consultado en el dashboard es `d2f3de03-98c2-47c7-9cfb-3a68561a1ba2`.

Después de corregir el dashboard se verificó en el navegador local que ese lote muestra su imagen QR, que la recarga conserva la sesión de JEFATURA y la selección del lote, y que cerrar sesión seguido de otra recarga vuelve al acceso. Estas comprobaciones consultaron datos existentes y no crearon recepciones nuevas. Las capturas y sus alcances se documentan en [Evidencias del recorrido](EVIDENCIAS_RECORRIDO.md).

## Recorrido manual para comprobar en el celular

1. Iniciar el backend, conectar el celular por USB y configurar `adb reverse tcp:18080 tcp:18080`. Ejecutar la app con la URL indicada en el README.
2. Comprobar conexión e iniciar sesión con un OPERARIO. Revisar el centro y la fecha de descarga en Catálogos; pulsar Actualizar catálogos.
3. Interrumpir el acceso al servidor y volver a comprobar conexión. Capturar una recepción y verificar que permanece pendiente en Registros.
4. Recuperar el acceso y pulsar Sincronizar pendientes. Revisar los confirmados y el resultado de calidad; si alguno falla, revisar su motivo y reintentar.
5. Abrir Central y buscar el mismo UUID. Consultar la calidad y, si está aprobado, su QR y el destino permitido.
6. Entrar al dashboard con JEFATURA del mismo centro. Pulsar Actualizar datos, verificar el UUID y comparar las cifras con el filtro aplicado.
7. Cambiar Hoy, Últimos 7 días y Últimos 30 días; revisar que las fechas correspondientes se reflejan en Reportes y en la exportación.

Una recepción capturada en el celular solo aparece en el dashboard después de que el servidor confirme su envío. Los totales locales pueden diferir de los del centro porque cada equipo conserva sus propios registros.
