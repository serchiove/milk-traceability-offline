# Contrato propuesto de acceso móvil

Propuesta para acordar entre Sergio y Patricio; no describe un endpoint ya implementado.

## Estado
La pantalla de acceso está preparada. Por defecto EXPO_PUBLIC_AUTH_PATH no está definida y el servicio no envía credenciales ni concede una sesión. El modo de borradores locales no autentica usuarios y conserva la funcionalidad local de desarrollo.

## Petición propuesta
POST a una ruta relativa del backend, por ejemplo /api/auth/login, solo después de que Patricio confirme su implementación. JSON con email y password.

## Respuesta propuesta

```json
{
  "accessToken": "TOKEN_GENERADO_POR_EL_BACKEND",
  "usuario": {
    "id": 1,
    "nombre": "Nombre del operario",
    "rol": "OPERARIO",
    "idCentro": 1,
    "centro": "Centro asignado"
  }
}
```

La etiqueta OPERARIO y los nombres de campos deben confirmarse entre ambos. La app rechaza una respuesta incompleta o un rol diferente. El backend debe comprobar usuario activo, contraseña protegida, rol y centro; las validaciones del cliente no sustituyen la autorización del servidor.

Errores previstos: 401 credenciales incorrectas, 403 sin acceso, 429 demasiados intentos, error de red o tiempo de espera. El token se mantiene solo en memoria y no se imprime ni se guarda en SQLite; la contraseña se limpia después del intento. La sesión no se restaura al reiniciar.

## Antes de habilitar acceso real
Acordar HTTPS para despliegue, vencimiento y revocación de sesión, protección de endpoints y envío del token a servicios de negocio. Resolver catálogos y asociación de borradores con usuario/centro. Los borradores actuales son compartidos por dispositivo y no deben enviarse automáticamente tras acceder con otra cuenta.

No habilitar EXPO_PUBLIC_AUTH_PATH como si fuera un sistema de autenticación terminado. Un inicio exitoso solo permite preparar la sesión en memoria; la sincronización, autorización de negocio y separación de registros por usuario aún deben implementarse.

## Continuar hoy
Abrir Expo y recargar. Se muestra acceso. Correo y contraseña se validan, pero un formulario válido informa que falta integrar la API. Continuar con borradores locales permite registrar y consultar en SQLite, sin acceso autenticado. Volver al acceso desmonta la pantalla de trabajo: guardar los campos antes de salir para no perder cambios sin guardar.
