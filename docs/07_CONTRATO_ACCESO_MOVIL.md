# Contrato de acceso móvil

## Backend implementado

`POST /api/auth/login`, con JSON `email` y `password`.
Consulta `acopio.usuario`, `acopio.rol` y `acopio.centro_acopio`. Comprueba BCrypt, usuario activo y centro activo. Una contraseña incorrecta, usuario inexistente o cuenta/centro inactivo devuelve 401 sin distinguir cuál falló.

Respuesta 200 compatible con `mobile/src/services/authService.ts`:

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

Los IDs son ejemplos; se obtienen de la base. El backend admite cuentas de OPERARIO y JEFATURA; la app móvil acepta únicamente OPERARIO.

## Estado de la app

El acceso móvil usa `/api/auth/login` por defecto. La dirección base se configura con `EXPO_PUBLIC_API_URL`. Perfil → Catálogos consulta proveedores, vehículos y centro con el token de la sesión. El token se conserva en Expo SecureStore hasta la expiración del JWT y la contraseña se limpia después del intento. La sesión vigente se restaura al reiniciar si existen los catálogos locales. Véase docs/12_ALINEACION_INFORME_OFICIAL.md.

Los borradores SQLite siguen siendo compartidos por dispositivo. Un login no los convierte en recepciones del usuario autenticado ni los envía. Antes de implementar sincronización deben resolverse referencias oficiales de proveedor/vehículo y la asociación de borradores al usuario/centro.

## Autorización

`POST /api/lotes` requiere `Authorization: Bearer TOKEN` y rol OPERARIO. Los IDs de usuario y centro se toman de la identidad autenticada, no del JSON enviado por el móvil. Cada petición con token comprueba que la cuenta y centro sigan activos y que no hayan cambiado rol o centro respecto del token.

401 indica autenticación ausente, inválida, vencida o invalidada por cambio de cuenta; 403 indica que el rol autenticado no permite esa operación. El backend no implementa todavía limitación de intentos/429 ni recuperación de contraseña.

## Configuración

`JWT_SECRET` es obligatorio y debe tener al menos 32 bytes. `scripts/Dev.ps1` genera una clave aleatoria por PC en `.local/jwt-secret.txt` cuando no se suministra por entorno. No debe publicarse ese archivo. `JWT_EXPIRATION_MS` es configurable y vale 86400000 por defecto. Al cambiar la clave se invalidan los tokens anteriores.

Para despliegue deben usarse HTTPS y credenciales propias; las cuentas de V3/V4 son solo demostración.
