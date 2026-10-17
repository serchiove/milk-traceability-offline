# Integración móvil

Estado actualizado y recorrido completo: [Alineación con el informe oficial](12_ALINEACION_INFORME_OFICIAL.md).

El acceso usa POST /api/auth/login, los catálogos se descargan a SQLite y la sesión se conserva en SecureStore hasta su vencimiento. La captura ya selecciona IDs oficiales y guarda responsable/centro en la misma transacción del lote. No hay captura nueva anónima.

Desde el detalle se envía manualmente conservando UUID, contenido y huella SHA-256. Perfil incluye consulta central de calidad, lectura/generación visual de QR y asignación de tanques. El backend expone reportes CSV e indicadores para que los consuma el dashboard existente de jefatura, cuya interfaz no se modifica.

EXPO_PUBLIC_API_URL configura el backend; por USB, scripts/Conectar-Android.ps1 redirige el puerto 18080 y el puerto 8081 de Expo. Reiniciar Expo después de instalar dependencias o cambiar variables. El backend debe recompilarse para exponer las rutas nuevas.
