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
