# Datos de prueba alineados al sistema

## 1. Propósito

Este documento reúne datos ficticios para probar el sistema ACOPIO. No corresponden a trabajadores, proveedores ni operaciones reales de Leche Gloria.

Los datos base ya se cargan mediante las migraciones `V2`, `V3` y `V4`. Estas migraciones no deben modificarse. Las pruebas adicionales deben ejecutarse con datos aislados o mediante la API.

Unidades utilizadas:

- Volumen: litros (L).
- Temperatura: grados Celsius (°C).
- Acidez: grados Dornic (°D).
- Densidad: gramos por mililitro (g/mL).

## 2. Datos disponibles en V2, V3 y V4

Los identificadores numéricos no se fijan manualmente. PostgreSQL los genera y deben recuperarse de la base de datos.

| Entidad | Dato disponible | Uso en pruebas |
|---|---|---|
| Rol | `OPERARIO` | Registra y envía recepciones; puede asignar tanque. |
| Rol | `JEFATURA` | Consulta reportes y administra catálogos; no registra lotes. |
| Centro | Centro de prueba académico - Arequipa - 10000 L | Centro asignado a las cuentas de demostración. |
| Usuario | `operario@gloria.com.pe` - Juan Pérez | Acceso de OPERARIO. |
| Usuario | `jefatura@gloria.com.pe` - María Gómez | Acceso de JEFATURA. |
| Proveedor | RUC `20100190797` - Establo Lechero Los Andes S.A.C. | Proveedor activo y vigente. |
| Vehículo | `V1A-450` - 5000 L | Vehículo activo. |
| Tanque | `TQ-01` - 5000 L - DISPONIBLE | Tanque del centro de prueba. |

La contraseña de ambas cuentas es `123456` únicamente en el entorno de desarrollo. En PostgreSQL se almacena el hash BCrypt corregido por `V4`, no la contraseña en texto plano.

El rol `ADMINISTRADOR` no forma parte de los permisos implementados y no debe usarse en las pruebas actuales.

## 3. Recuperación de identificadores reales

Antes de realizar una prueba se consultan los identificadores reales:

```sql
SELECT id_rol, nombre FROM acopio.rol ORDER BY id_rol;
SELECT id_centro, nombre, activo FROM acopio.centro_acopio ORDER BY id_centro;
SELECT id_usuario, email, id_rol, id_centro, activo FROM acopio.usuario ORDER BY id_usuario;
SELECT id_proveedor, razon_social, activo FROM acopio.proveedor ORDER BY id_proveedor;
SELECT id_vehiculo, placa, activo FROM acopio.vehiculo ORDER BY id_vehiculo;
SELECT id_tanque, codigo, id_centro, capacidad_litros,
       volumen_asignado_litros, estado
FROM acopio.tanque ORDER BY id_tanque;
```

Los valores `1`, `2` o `3` no se deben asumir como identificadores fijos.

## 4. Escenarios de recepción

Los lotes no vienen precargados. Cada prueba genera un UUID nuevo y lo conserva durante todos los reintentos.

### 4.1 Lote aprobado

| Campo | Valor de prueba |
|---|---|
| Proveedor | Establo Lechero Los Andes S.A.C. |
| Vehículo | V1A-450 |
| Volumen | 100.00 L |
| Temperatura | 4.00 °C |
| Acidez | 16.00 °D |
| Densidad | 1.0300 g/mL |

Resultado esperado con reglas `DEMO-1`: lote `APROBADO`, versión `DEMO-1` y código QR `ACOPIO:<UUID>`.

### 4.2 Lote rechazado por calidad

| Campo | Valor de prueba |
|---|---|
| Proveedor | Establo Lechero Los Andes S.A.C. |
| Vehículo | V1A-450 |
| Volumen | 100.00 L |
| Temperatura | 15.00 °C |
| Acidez | 16.00 °D |
| Densidad | 1.0300 g/mL |

La temperatura es físicamente válida, pero está fuera del criterio académico `DEMO-1`. El servidor debe conservar la recepción como `RECHAZADO`, registrar un motivo y una incidencia, y no generar QR.

### 4.3 Entrada inválida

Ejemplos: temperatura menor que `-273.15 °C`, volumen con más de dos decimales, UUID inválido o proveedor inactivo.

Resultado esperado: respuesta `400`, sin crear filas parciales en `lote_leche` ni `registro_calidad`.

### 4.4 Registro sin conexión

| Campo | Valor de prueba |
|---|---|
| UUID | Generado una sola vez por la aplicación móvil |
| Proveedor y vehículo | Identificadores del catálogo local del operario |
| Volumen | 100.00 L |
| Temperatura | 4.00 °C |
| Acidez | 16.00 °D |
| Densidad | 1.0300 g/mL |
| Estado local | Pendiente de envío |

El registro queda en SQLite mientras el backend no está disponible. Cuando se recupera la conexión, el operario debe enviarlo manualmente. No existe sincronización automática.

El móvil calcula y envía la huella SHA-256. El backend vuelve a calcularla y la verifica. El mismo UUID con el mismo contenido confirma el registro original; el mismo UUID con contenido diferente produce conflicto `409`.

## 5. Registro de calidad pendiente

Si una prueba inserta un registro `PENDIENTE` directamente en una base aislada, debe cumplir esta regla:

| Campo | Valor |
|---|---|
| `estado_evaluacion` | `PENDIENTE` |
| `fecha_evaluacion` | `NULL` |
| `version_reglas` | `NULL` |
| `motivo` | `NULL` |

No se debe escribir el texto “Pendiente” en los campos de fecha, versión o motivo.

## 6. Asignación de tanque

El valor `volumen_asignado_litros` no se modifica a mano. Para comprobarlo:

1. Registrar un lote aprobado.
2. Asignarlo a un tanque disponible del mismo centro.
3. Consultar nuevamente el tanque.
4. Verificar que el trigger incrementó el volumen una sola vez.
5. Repetir la asignación y comprobar que el volumen no vuelve a aumentar.

## 7. Reglas de seguridad y conservación

- No almacenar contraseñas ni tokens en las evidencias.
- No usar datos personales reales.
- No eliminar lotes rechazados ni incidencias.
- No cambiar directamente IDs, huellas, QR ni volumen asignado.
- Ejecutar fixtures y pruebas destructivas únicamente en `acopio_test` o en otra base aislada.
- No modificar las migraciones `V1`, `V2`, `V3` ni `V4`.
- Registrar el commit, la fecha y el entorno de cada ejecución.
