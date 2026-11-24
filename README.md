## Validación técnica adicional – Flutter y rendimiento (24/11/2026)

Se realizó una revisión técnica del módulo móvil Flutter y una medición de rendimiento del backend en el entorno local.

### Resultados de las pruebas

| Actividad | Resultado |
|---|---|
| Resolución de dependencias Flutter | Correcta |
| Pruebas automatizadas | 46 aprobadas |
| Pruebas omitidas | 1 |
| Pruebas fallidas | 0 |
| Análisis estático | 40 observaciones informativas |
| Compilación APK Debug | Exitosa |
| Medición de rendimiento | 30 solicitudes |
| Tiempo promedio de respuesta | 20,67 ms |
| Percentil 95 (P95) | 30,97 ms |
| Tiempo máximo | 31,46 ms |

### Resultado de rendimiento

Se evaluó el endpoint autenticado:

`GET /api/lotes?pagina=0&tamano=25`

Se realizaron cinco solicitudes de calentamiento y 30 solicitudes medidas. Las 30 consultas respondieron en menos de 2 segundos, por lo que se cumplió el objetivo de rendimiento para este endpoint en el entorno local.

### Observaciones pendientes

- Revisar individualmente los dos fallos locales reportados originalmente en Flutter, contrastando sus reportes con la versión actual.
- Ejecutar la prueba de contrato `live_contract_test.dart` con un backend y una base de datos de pruebas aislados.
- Revisar las 40 observaciones informativas del análisis estático.
- Ampliar las mediciones de rendimiento a otros endpoints y realizar pruebas desde un dispositivo Android.

### Evidencia

[Consultar informe técnico de Flutter y rendimiento](../INFORME_TECNICO_FLUTTER_RENDIMIENTO.docx)

**Alcance:** los resultados de rendimiento corresponden a una medición desde PowerShell hacia el backend local. No representan todavía una medición integral desde el dispositivo móvil ni una garantía de rendimiento en producción.
