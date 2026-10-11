# Datos ficticios para pruebas

## 1. Descripción

Los siguientes datos son ficticios y se prepararon únicamente para realizar pruebas del sistema de acopio y trazabilidad de leche. No corresponden a proveedores, trabajadores ni operaciones reales de Leche Gloria.

Las unidades utilizadas son:

- Volumen: litros.
- Temperatura: °C.
- Acidez: °D.
- Densidad: g/mL.

## 2. Roles

| id_rol | nombre | descripción |
|---|---|---|
| 1 | OPERARIO | Registra los lotes recibidos |
| 2 | JEFATURA | Revisa resultados y reportes |
| 3 | ADMINISTRADOR | Gestiona usuarios y configuraciones |

## 3. Centros de acopio

| id_centro | nombre | región | capacidad_litros | activo |
|---|---|---|---:|---|
| 1 | Centro de Acopio Arequipa | Arequipa | 50000.00 | true |
| 2 | Centro de Acopio Majes | Arequipa | 35000.00 | true |

## 4. Usuarios de prueba

| id_usuario | id_rol | id_centro | nombre | DNI | correo | contraseña | activo |
|---|---:|---:|---|---|---|---|---|
| 1 | 1 | 1 | Operario Demo | 70000001 | operario.demo@prueba.com | Generada por el backend | true |
| 2 | 2 | 1 | Jefatura Demo | 70000002 | jefatura.demo@prueba.com | Generada por el backend | true |

Las contraseñas no deben guardarse como texto. El backend deberá generar el campo `password_hash`.

## 5. Proveedores ficticios

| id_proveedor | tipo_documento | numero_documento | razon_social | estado_cert | activo |
|---|---|---|---|---|---|
| 1 | DNI | 47651238 | Ganadería Los Andes | VIGENTE | true |
| 2 | RUC | 20600000011 | Fundo Valle Verde S.A.C. | PENDIENTE | true |
| 3 | DNI | 45879632 | Productor Santa Rosa | VENCIDO | false |

## 6. Vehículos ficticios

| id_vehiculo | placa | capacidad_litros | activo |
|---|---|---:|---|
| 1 | ABC-123 | 10000.00 | true |
| 2 | V7K-456 | 8000.00 | true |

## 7. Tanques ficticios

| id_tanque | id_centro | código | capacidad_litros | volumen_asignado_litros | estado |
|---|---:|---|---:|---:|---|
| 1 | 1 | T-01 | 5000.00 | 320.00 | DISPONIBLE |
| 2 | 1 | T-02 | 7000.00 | 0.00 | DISPONIBLE |
| 3 | 2 | T-03 | 6000.00 | 0.00 | MANTENIMIENTO |

## 8. Lotes ficticios

| id_lote | proveedor | vehículo | operario | centro | fecha y hora | volumen | estado |
|---|---|---|---|---|---|---:|---|
| 550e8400-e29b-41d4-a716-446655440001 | Ganadería Los Andes | ABC-123 | Operario Demo | Centro de Acopio Arequipa | 2026-10-10 08:30 | 320.00 L | APROBADO |
| 550e8400-e29b-41d4-a716-446655440002 | Fundo Valle Verde S.A.C. | V7K-456 | Operario Demo | Centro de Acopio Arequipa | 2026-10-10 09:15 | 450.00 L | RECHAZADO |
| 550e8400-e29b-41d4-a716-446655440003 | Ganadería Los Andes | ABC-123 | Operario Demo | Centro de Acopio Arequipa | 2026-10-10 10:00 | 280.00 L | PENDIENTE |

Cada lote deberá conservar el mismo UUID durante los reintentos de sincronización. La huella SHA256 será calculada por el backend para comprobar si el contenido fue modificado.

## 9. Registros de calidad ficticios

| id_registro | id_lote | temperatura_c | acidez_dornic | densidad_g_ml | estado_evaluacion | versión de reglas | motivo |
|---|---|---:|---:|---:|---|---|---|
| 1 | 550e8400-e29b-41d4-a716-446655440001 | 4.0 | 16.0 | 1.030 | APROBADO | V1 | Parámetros conformes |
| 2 | 550e8400-e29b-41d4-a716-446655440002 | 12.0 | 22.0 | 1.020 | RECHAZADO | V1 | Valores fuera de los criterios configurados |
| 3 | 550e8400-e29b-41d4-a716-446655440003 | 5.0 | 17.0 | 1.029 | PENDIENTE | Pendiente | Pendiente de evaluación |

Los valores se usarán para comprobar el funcionamiento del sistema. Las reglas definitivas de aprobación o rechazo serán aplicadas por el backend.

## 10. Incidencia ficticia

| id_incidencia | id_registro | tipo_alerta | descripción | fecha y hora |
|---|---:|---|---|---|
| 1 | 2 | CALIDAD | Lote rechazado por valores fuera de los criterios configurados | 2026-10-10 09:20 |

## 11. Registro sin conexión

| campo | dato de prueba |
|---|---|
| UUID | 550e8400-e29b-41d4-a716-446655440004 |
| Proveedor | Ganadería Los Andes |
| Vehículo | ABC-123 |
| Volumen | 300.00 L |
| Temperatura | 4.5 °C |
| Acidez | 16.5 °D |
| Densidad | 1.030 g/mL |
| Estado local | Pendiente de sincronización |

Este registro deberá guardarse localmente cuando no exista conexión. Al recuperar la conectividad, se enviará al servidor conservando el mismo UUID para evitar duplicados.

## 12. Observaciones

- Todos los datos presentados son ficticios.
- La acidez se registra únicamente en grados Dornic (°D).
- No deben guardarse contraseñas en texto plano.
- Los lotes rechazados deben conservarse para mantener la trazabilidad.
- Un lote aprobado solo puede asignarse a un tanque disponible del mismo centro y con capacidad suficiente.
- Los archivos de migración V1 y V2 no deben modificarse.
- Cualquier nueva migración deberá coordinarse previamente con Patricio.
