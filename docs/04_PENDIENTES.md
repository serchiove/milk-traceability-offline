# Plan de implementación

## Base disponible
- [x] Backend, PostgreSQL y dashboard conectados.
- [x] Nueve tablas y migraciones iniciales.
- [x] App Android conectada al backend, según captura del usuario.
- [x] Tres comprobaciones guardadas en SQLite, según captura del usuario.
- [x] Confirmar persistencia SQLite después de cerrar completamente y reabrir la app.

## Entrega 1: autenticación y catálogos
- [ ] Acordar contrato de API y permisos de operario / jefatura.
- [ ] Implementar contraseña protegida, autenticación y autorización en backend.
- [ ] Crear inicio/cierre de sesión web y móvil, con manejo de credenciales incorrectas.
- [ ] Preparar proveedores y vehículos ficticios y endpoints de consulta.
Aceptación: usuarios autorizados acceden a su rol; una petición sin permiso es rechazada por el servidor.

## Entrega 2: registro de lotes
- [ ] Formulario con proveedor, vehículo, centro, volumen, temperatura, acidez y densidad.
- [ ] Validar datos en móvil y servidor; guardar lote con identificador estable.
- [ ] Mostrar el lote guardado en el dashboard.
Aceptación: registrar desde el celular y consultar el mismo registro desde web y PostgreSQL.

## Entrega 3: calidad
- [ ] Confirmar umbrales y unidades con el equipo/docente antes de codificarlos.
- [ ] Implementar servicio de evaluación apoyado en las restricciones existentes de la base.
- [ ] Guardar resultado y motivo; generar incidencia al rechazar.
Aceptación: casos aprobado/rechazado reproducibles y resultado coherente en ambos clientes.

## Entrega 4: acopio y trazabilidad
- [ ] Asignar tanque validando centro, estado y capacidad.
- [ ] Generar/consultar QR e historial según las reglas del proyecto.
- [ ] Indicadores y reportes del dashboard.
Aceptación: seguir un lote desde su recepción hasta su destino y bloquear asignaciones inválidas.

## Entrega 5: funcionamiento sin conexión
- [ ] Guardar lotes pendientes en SQLite, separándolos del diagnóstico actual.
- [ ] Reintentar envío y confirmar guardado del servidor antes de marcar sincronizado.
- [ ] Evitar duplicados con identificador estable y operación idempotente.
Aceptación: registrar sin conexión, recuperar conexión y verificar exactamente un lote en el servidor.

La base contiene restricciones de negocio; los endpoints y recorridos de negocio todavía están pendientes. No confundir esas restricciones con un sistema ya implementado.
