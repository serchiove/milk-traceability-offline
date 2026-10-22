# Evidencia de ejecución automatizada - 20/10/2026

## Identificación

| Dato | Valor |
|---|---|
| Fecha | 20/10/2026 |
| Commit base probado | `a59788d` |
| Rama de preparación | `feature/elias-pruebas-actualizadas` |
| Responsable del registro | Elías |
| Entorno de ejecución | Entorno de Codex; pendiente repetir las pruebas en mi computadora |
| Rama de entrega | `feature/elias-pruebas-actualizadas-3` |
| Node.js | 24.19.0 |
| Java | OpenJDK 17.0.20 |

## Aplicación móvil

Comandos ejecutados:

```text
cd mobile
npm ci
npm test
npm run typecheck
```

Resultado:

- 29 pruebas ejecutadas.
- 29 pruebas aprobadas.
- 0 pruebas fallidas.
- TypeScript finalizó sin errores.

Cobertura observada:

- Contrato de login y rechazo de sesiones incompletas.
- Errores de catálogo, permisos, sesión vencida y desconexión.
- Validación de campos y precisión numérica.
- Persistencia SQLite y conservación del UUID.
- Recuperación de edición y preparación de envío después de recargar.
- Rollback local cuando falla el guardado.
- Separación de datos locales entre operarios.
- Reintento de envío sin cambiar el UUID.
- Coincidencia de la huella SHA-256 móvil con el formato canónico de Java.

Estas pruebas usan SQLite real en memoria y respuestas HTTP simuladas. No sustituyen el recorrido manual en un celular ni una comunicación real con el backend.

## Dashboard

Comandos ejecutados:

```text
cd dashboard
npm ci
npm run build
```

Resultado: compilación correcta con Vite; 16 módulos transformados y archivos generados en `dist`.

La compilación solo comprueba que la interfaz puede construirse. No demuestra que el dashboard consuma las APIs, porque esa integración continúa pendiente.

## Backend

Se verificó Java 17 y el wrapper Maven 3.9.13. La suite no pudo ejecutarse en este entorno por dos limitaciones externas:

1. No hay una instancia PostgreSQL disponible para la base aislada `acopio_test`.
2. La conexión a Maven Central no estuvo disponible para resolver las dependencias del proyecto.

Este bloqueo de entorno no se registra como fallo del backend. Las 33 pruebas mencionadas en el README corresponden a una ejecución previa del equipo del 17/10/2026 y no se atribuyen a esta ejecución.

## Pendiente para completar la evidencia

- Ejecutar `Probar_Proyecto.cmd` en la PC preparada del proyecto.
- Guardar el resumen de las 33 pruebas o el nuevo total obtenido.
- Realizar el recorrido manual offline con el celular y Metro disponible.
- Verificar el mismo UUID en móvil, API y PostgreSQL.
- Repetir la aceptación desde la web cuando el dashboard consuma la API.
