# Verificación de la aplicación Flutter

## Estado comprobado el 25/10/2026

La suite local de Flutter completó 46 pruebas aprobadas después de la reorganización de vistas y de la revisión visual. El análisis estático terminó sin incidencias y se generó el APK Android de depuración con Java 17 y API por USB.

Incluimos conexión, servicios, persistencia, validaciones, navegación y distribución de detalles. Las pruebas de interfaz verifican pantallas estrechas y texto ampliado. Estos resultados corresponden a datos temporales y respuestas HTTP controladas; no acreditan por sí solos una comunicación con PostgreSQL.

La comprobación manual del recorrido completo fue confirmada por Sergio el 25/10/2026. Se confirmó también la exportación Excel tras recompilar el backend que estaba ejecutándose con un JAR anterior. No incorporamos capturas nuevas como si fueran evidencia del 24/10.

## Evidencia previa del 24/10/2026

La ejecución anterior registró 35 pruebas de conexión, servicios, repositorio y validaciones, más 6 de interfaz: 41 en total. El dashboard registró 11 pruebas de fechas, sesión y QR y una compilación correcta. Estos conteos son históricos y no se suman al resultado posterior.

En esa revisión comprobamos la recuperación de catálogos sin perder borrador, los reintentos de envío y su resultado por registro, la consulta de conexión, los filtros de fechas del dashboard, la conservación de sesión al recargar y la imagen QR descargable. La revisión de recepción se ajustó para nombres largos.

El recorrido con un lote de 120 L, temperatura 4,5 °C, acidez 16 °D y densidad 1,0300 g/mL documentó guardado local, fallo de envío, consulta central y destino TQ-01. El UUID fue `d2f3de03-98c2-47c7-9cfb-3a68561a1ba2`.

Las [capturas originales y su alcance](../../mobile-flutter/docs/EVIDENCIAS_RECORRIDO.md) permanecen disponibles. Algunas muestran estados visuales previos a las correcciones; se conservan como evidencia histórica.

## Alcance de las pruebas

- Precisión numérica, límites y representación canónica compatible con Java.
- SQLite, recuperación al reabrir y atomicidad del guardado.
- Aislamiento por usuario y centro y conservación del cuerpo al reintentar.
- Confirmación de calidad rechazada, fallos parciales y respuestas incompletas.
- Actualización de catálogos y conservación de la copia anterior ante fallos.
- Acceso, navegación, cierre de sesión, texto largo y pantallas estrechas.

Los comandos reproducibles y los requisitos del contrato aislado se mantienen en el [README principal](../../README.md#pruebas-y-evidencias). La prueba de contrato crea registros y debe utilizar su entorno temporal. La compilación y firma iOS siguen pendientes.
