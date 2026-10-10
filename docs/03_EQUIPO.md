# Trabajo del equipo

Distribución acordada: Sergio desarrolla la aplicación móvil.

| Integrante | Responsabilidad | Primera entrega |
|---|---|---|
| Sergio | Aplicación móvil | Inicio de sesión de operario, captura de lotes, SQLite y sincronización |
| Fernando | Dashboard web | Inicio de sesión de jefatura, consulta de lotes, indicadores, alertas y reportes |
| Patricio | Backend | Autenticación, permisos y contrato de API compartido |
| Elías | Base y pruebas | Datos ficticios, migraciones acordadas y casos de prueba |

Sergio trabaja en `mobile/` y coordina con Patricio los contratos de la API. Fernando trabaja en `dashboard/`; Patricio, en `backend/`; Elías coordina las migraciones de PostgreSQL y las pruebas con Patricio. Estas responsabilidades incluyen funciones pendientes de implementar.

## Antes de iniciar cada función
Acordar campos, unidades, roles autorizados, ruta de API, respuesta y errores. Ejemplo: acidez debe conservar la unidad acordada en el informe y el modelo; no intercambiar °D con porcentajes.
Patricio y Elías coordinan las migraciones: reservar el siguiente número entre ambos para no crear versiones duplicadas.
Los clientes no deben inventar una respuesta de éxito si el servidor falló. Los datos de ejemplo deben identificarse como ficticios.

## Git e integración
Repositorio del equipo: https://github.com/serchiove/milk-traceability-offline. La rama principal es `main`; trabajar en ramas por función para cambios posteriores.
Usar una rama por función, por ejemplo `feature/login-movil`; revisar los cambios antes de integrarlos. Conservar los archivos lock y no copiar node_modules.
Antes de integrar: ejecutar las comprobaciones pertinentes y describir qué funciona, cómo probarlo y qué queda pendiente.
No compartir `.local`, claves ni datos personales. Cada integrante prepara su entorno con `Preparar.ps1`.

## Una entrega está terminada cuando
El recorrido funciona contra la API real, valida entradas y permisos, muestra errores claros y tiene una comprobación reproducible. Una pantalla visual por sí sola no completa una función.
