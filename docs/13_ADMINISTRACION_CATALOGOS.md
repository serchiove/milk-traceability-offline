# Administración de proveedores y vehículos

Implementado el 17/10/2026. Ampliación exclusivamente del backend. Requiere JWT de una cuenta activa JEFATURA. OPERARIO recibe 403 y una petición sin autenticación recibe 401.

Base: `/api/administracion/catalogos`. Los catálogos son globales en el modelo actual: una modificación afecta a todos los centros. No existe propiedad por centro de proveedores ni vehículos.

| Método | Ruta relativa | Resultado |
|---|---|---|
| GET | /proveedores o /vehiculos | Activos e inactivos, con `buscar`, `pagina` (0), `tamano` (25, máximo 100) |
| POST | /proveedores o /vehiculos | Crea activo, devuelve 201 y el registro con ID |
| PUT | /proveedores/{id} o /vehiculos/{id} | Actualiza datos editables, devuelve 200 |
| PATCH | /proveedores/{id}/estado o /vehiculos/{id}/estado | Desactiva o reactiva, devuelve 200 |

Proveedor (POST y PUT):

```json
{"tipoDocumento":"DNI","numeroDocumento":"12345678","razonSocial":"Proveedor de demostración","estadoCert":"PENDIENTE"}
```

DNI exige 8 dígitos, RUC 11. Nombre obligatorio, máximo 180 caracteres. Estado documental: PENDIENTE, VIGENTE o VENCIDO; es un dato administrativo, no una certificación verificada. El documento no cambia con PUT; para otra identidad se crea otro proveedor y se desactiva el anterior. El nombre y estado documental sí son editables.

Vehículo (POST y PUT):

```json
{"placa":"ABC-123","capacidadLitros":5000.00}
```

Placa: hasta 12 caracteres alfanuméricos, espacios internos o guiones; se recortan extremos y convierte a mayúsculas. No se impone un formato nacional. Capacidad positiva, máximo 10 enteros y 2 decimales. PUT cambia la capacidad, no la placa.

Estado (PATCH):

```json
{"activo":false}
```

Reactivar: `{"activo":true}`. Repetir el mismo estado es seguro. No se implementa eliminación física. Un registro inactivo conserva su documento/placa reservados; duplicarlo devuelve 409. Las restricciones únicas de PostgreSQL también protegen contra altas concurrentes.

Errores: 400 datos inválidos; 404 ID inexistente; 409 documento/placa duplicado o intento de cambiar identidad. Las respuestas no exponen SQL ni contraseñas.

## Efecto en la recepción y trazabilidad

Las rutas existentes `/api/catalogos/proveedores` y `/api/catalogos/vehiculos` siguen devolviendo solamente activos. Un catálogo descargado antes de una desactivación puede conservarlo temporalmente en el celular: el servidor rechaza nuevas recepciones con referencias inactivas. Los reintentos de una recepción ya confirmada siguen siendo idempotentes.

Los lotes, mediciones, resultados y claves de referencia existentes no se borran ni cambian. Las consultas históricas muestran el nombre actual del proveedor, porque el esquema no almacena versiones del nombre; esta ampliación no añade auditoría ni instantáneas históricas. La última edición confirmada prevalece si dos jefaturas editan el mismo registro.

## Prueba

En Postman: iniciar sesión JEFATURA, usar `Authorization: Bearer <accessToken>`, crear, listar, editar, desactivar y reactivar. Comprobar que un OPERARIO no puede administrar. El móvil conserva sus rutas actuales; no se agregó una pantalla administrativa al dashboard.

Las pruebas automatizadas usan PostgreSQL aislado (`acopio_test`) y HTTP real: permisos, validación, duplicados, normalización de placa, edición, desactivación/reactivación y conservación/reintento de un lote recibido tras desactivar el proveedor.

Verificación del 17/10/2026: `mvn -o verify` completado con 30 pruebas aprobadas y JAR actualizado. Para utilizarlo, iniciar el entorno con `Iniciar.cmd`. No se crearon proveedores ni vehículos de prueba en `acopio_dev`.
