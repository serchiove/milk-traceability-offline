# Verificación de ACOPIO móvil

La app utiliza Flutter y Dart. El backend Spring Boot y el dashboard comparten los datos confirmados en PostgreSQL.

## Resultados del 24 de octubre de 2026

| Comprobación | Resultado |
| --- | --- |
| Análisis Flutter | Sin observaciones |
| Conexión, servicios, repositorio y validaciones | 35 pruebas aprobadas |
| Interfaz: acceso, captura, nombres largos, cierre de sesión y accesibilidad | 6 pruebas aprobadas |
| Dashboard: fechas, QR y sesión | 11 pruebas aprobadas |
| Compilación del dashboard | Correcta |
| APK Android de depuración con API USB | Generado correctamente |
| Recorrido manual en Android y dashboard | Confirmado por el usuario y documentado con capturas |

La evidencia backend del tercer avance, con 40 pruebas, Javadoc y TDD, está en [la documentación técnica](../../docs/APF3_LIBRERIAS_JAVADOC_TDD.md). Ese resultado pertenece a la ejecución allí fechada.

## Qué comprobamos

- Precisión numérica, coma decimal, límites y representación canónica compatibles con Java.
- SQLite, recuperación al reabrir, autoguardado y operaciones atómicas.
- Aislamiento por operario y centro y conservación del cuerpo al reintentar.
- Calidad rechazada como recepción confirmada, errores HTTP y respuestas incompletas.
- Envío conjunto, fallos parciales y reintento de pendientes.
- Actualización completa de catálogos y conservación de la copia y del borrador ante fallos.
- Conexión real y expiración de sesión.
- Captura en tres pasos, nombres largos, navegación y texto ampliado.
- QR del servidor y conservación de sesión web al recargar.

## Repetir las comprobaciones

Desde `mobile-flutter`:

```powershell
flutter analyze --no-pub
flutter test --no-pub test/connection_test.dart test/services_test.dart test/widget_test.dart test/repository_test.dart test/validation_test.dart
flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:18080
```

`tool/Test-Contract.ps1` utiliza PostgreSQL y backend temporales en puertos separados. La suite habitual omite ese contrato salvo que se configure expresamente `ACOPIO_TEST_API`.

## Evidencia y límites

Los detalles están en [Verificación del flujo](VERIFICACION_FLUJO.md) y [Evidencias del recorrido](EVIDENCIAS_RECORRIDO.md). Las pruebas automáticas usan dependencias controladas o almacenamiento temporal; las capturas documentan lo observado en teléfono y navegador.

Android se utiliza como plataforma de demostración. La firma de distribución, HTTPS y la compilación iOS son tareas de preparación para publicación.
