# Informe de la aplicación móvil

Responsable: Sergio. Fecha de corte: 09 de octubre de 2026.

## Propósito y alcance
La aplicación está destinada al operario de descarga. El objetivo del desarrollo es capturar la recepción de leche, conservar los registros cuando no hay conexión y enviarlos al backend compartido al recuperar conectividad. Actualmente funciona una pantalla de diagnóstico técnico; el flujo de recepción todavía está pendiente.

## Qué tenemos implementado
El proyecto usa React Native 0.86.3, React 19.2.3, Expo SDK 57 y TypeScript. Se ejecuta en Android mediante Expo Go. Esta modalidad permite desarrollar y probar, pero no constituye un APK independiente de distribución.
La organización inicial sigue MVVM. App.tsx presenta la vista; useEntornoViewModel administra estados y acciones; diagnosticoRepository encapsula el acceso a SQLite. La vista no consulta directamente PostgreSQL.
La acción Comprobar API real realiza GET /api/estado con un límite de espera de diez segundos y presenta conexión o error. La dirección predeterminada es http://127.0.0.1:18080 y puede configurarse con EXPO_PUBLIC_API_URL.
La acción Guardar prueba en SQLite abre acopio_desarrollo.db, crea comprobacion_local si no existe, inserta la fecha y consulta la cantidad acumulada. Los registros actuales son comprobaciones técnicas, no lotes de leche.

## Evidencia y límites
La captura aportada por Sergio muestra PostgreSQL conectado, nueve tablas y tres comprobaciones almacenadas en el dispositivo. Esto confirma el recorrido de diagnóstico y escritura local observado. Falta confirmar la persistencia después de cerrar completamente y reabrir la aplicación.
La comprobación de tipos pasó en la revisión anterior. La conexión actual por USB depende de adb reverse en los puertos 18080 y 8081 y de Metro en ejecución. No se ha probado un recorrido completo de negocio sin conexión.

## Archivos que debe mantener Sergio
- mobile/App.tsx: pantalla y representación del estado.
- mobile/src/viewmodel/useEntornoViewModel.ts: acciones de API y guardado local.
- mobile/src/model/diagnosticoRepository.ts: almacenamiento de diagnóstico.
- mobile/package.json y package-lock.json: dependencias y versiones.
- mobile/app.json: configuración Expo.

## Trabajo que falta
1. Implementar acceso de operario, cierre de sesión y manejo seguro de la sesión según el contrato acordado con Patricio.
2. Consultar catálogos de proveedores y vehículos, y confirmar el centro del usuario autenticado.
3. Crear formulario de volumen en litros, temperatura en grados Celsius, acidez en grados Dornic y densidad en g/mL, con validaciones y errores por campo.
4. Generar el UUID del lote una sola vez y conservarlo en todos los reintentos.
5. Crear tablas locales de lotes y estados de sincronización separadas de comprobacion_local. Definir sus migraciones y recuperación después de reinicios.
6. Implementar envío, reintento y confirmación. Marcar sincronizado solo cuando el servidor confirme el registro; conservar errores y conflictos para revisión.
7. Mostrar resultado de evaluación, motivo de rechazo y trazabilidad de acuerdo con la respuesta del backend.

## Dependencias y coordinación
Sergio necesita que Patricio defina autenticación, catálogos, creación y consulta de lotes. Deben acordar nombres de campos, unidades, fechas, respuestas y códigos de error antes de conectar pantallas. Elías prepara datos ficticios para probar proveedores, vehículos, centros y tanques.
La interfaz puede validar campos para ayudar al operario, pero la autorización y la decisión de calidad deben verificarse en el servidor. No se deben usar las cuentas simuladas del prototipo como acceso real.

## Criterios de aceptación
La primera entrega móvil queda terminada cuando un operario autorizado accede y obtiene sus catálogos desde la API. La siguiente requiere registrar un lote desde el celular y verlo en el dashboard. La entrega offline exige registrar sin conexión, cerrar y reabrir, recuperar conexión y comprobar que existe exactamente un lote en el servidor, incluso después de reintentos.

## Cómo ejecutar y presentar
Iniciar el proyecto con Iniciar.cmd. Conectar Android con depuración USB autorizada, ejecutar scripts/Conectar-Android.ps1 y después Abrir_Movil.cmd. Esperar que Metro esté listo y pulsar a. Mostrar la comprobación de API y SQLite y explicar que el flujo de negocio se implementará sobre esta base.
