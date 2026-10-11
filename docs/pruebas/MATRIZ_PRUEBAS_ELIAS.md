# Matriz de casos de prueba

**Responsable:** Elías  
**Módulo:** Base de datos y pruebas  
**Proyecto:** Sistema de Acopio y Trazabilidad Láctea  

> Los siguientes casos se encuentran preparados para su ejecución. Todos los datos utilizados serán ficticios.

| ID | Caso de prueba | Datos de entrada | Acción | Resultado esperado | Resultado obtenido | Evidencia |
|---|---|---|---|---|---|---|
| CP-01 | Inicio de sesión correcto | Usuario activo y contraseña válida | Iniciar sesión | El sistema permite el acceso según el rol del usuario | Pendiente de ejecución | Pendiente |
| CP-02 | Contraseña incorrecta | Usuario activo y contraseña incorrecta | Iniciar sesión | El sistema rechaza el acceso y muestra un mensaje de error | Pendiente de ejecución | Pendiente |
| CP-03 | Acceso según rol y centro | Usuario con rol de operario | Consultar información de otro centro | El sistema impide consultar información no autorizada | Pendiente de ejecución | Pendiente |
| CP-04 | Registro correcto de lote | Proveedor, vehículo, volumen y controles de calidad válidos | Registrar el acopio | El lote se registra completamente en la base de datos | Pendiente de ejecución | Pendiente |
| CP-05 | Temperatura inválida | Temperatura fuera del rango configurado | Validar el lote | El sistema rechaza el dato y muestra una advertencia | Pendiente de ejecución | Pendiente |
| CP-06 | Acidez en unidad incorrecta | Acidez registrada en porcentaje | Validar el lote | El sistema solicita registrar la acidez en grados Dornic (°D) | Pendiente de ejecución | Pendiente |
| CP-07 | Densidad inválida | Densidad fuera del rango configurado | Validar el lote | El sistema rechaza el dato inválido | Pendiente de ejecución | Pendiente |
| CP-08 | Registro sin conexión | Datos válidos sin acceso a internet | Guardar el registro | El registro se almacena localmente como pendiente de sincronización | Pendiente de ejecución | Pendiente |
| CP-09 | Recuperación de conexión | Registro local pendiente | Recuperar internet y sincronizar | El registro se envía al servidor y cambia a sincronizado | Pendiente de ejecución | Pendiente |
| CP-10 | Registro duplicado | Mismo UUID con contenido diferente | Sincronizar nuevamente | El sistema detecta el conflicto y evita duplicar el lote | Pendiente de ejecución | Pendiente |
| CP-11 | Error durante el registro | Información incompleta o error de base de datos | Intentar registrar el lote | No se guarda información parcial | Pendiente de ejecución | Pendiente |

## Criterios de validación

- La temperatura se registra en °C.
- La acidez se registra en °D.
- La densidad se registra en g/mL.
- Los datos de prueba deben ser ficticios.
- Un error no debe producir registros parciales.
- La sincronización no debe duplicar los lotes.
- Las pruebas ejecutadas deberán incluir evidencias.
