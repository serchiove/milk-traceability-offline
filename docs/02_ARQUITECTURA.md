# Arquitectura y organización

```text
acopio-app/
├── backend/          API compartida Java / Spring Boot
├── dashboard/        Aplicación web React / Bootstrap
├── mobile/           Aplicación React Native / Expo
├── database/         SQL del informe como referencia
├── docs/             Guías del proyecto y del equipo
├── scripts/          Automatización del entorno Windows
├── Acopio.code-workspace  Acceso conjunto en VS Code
├── README.md         Entrada principal
└── .local/           Base, claves y logs privados (no compartir)
```

## Responsabilidades actuales
- Dashboard: `dashboard/src/main.jsx` presenta el diagnóstico y consulta la API; `style.css` define su aspecto.
- Móvil MVVM: `mobile/App.tsx` contiene la vista; `mobile/src/viewmodel/useEntornoViewModel.ts` maneja acciones/estado; `mobile/src/model/diagnosticoRepository.ts` accede a SQLite.
- Backend por capas: `backend/src/main/java/pe/edu/utp/acopio/controller` recibe solicitudes; `service` coordina operaciones; `repository` consulta PostgreSQL.
- Migraciones oficiales: `backend/src/main/resources/db/migration`. V1 y V2 ya aplicadas; cambios nuevos mediante V3, V4, etc.
- `database/modelo_original_informe.sql` es referencia, no una segunda vía de instalación.

La app móvil usa MVVM; el backend usa capas. Ambos clientes se comunican con el mismo backend. El dashboard no accede directamente a PostgreSQL. SQLite guarda actualmente comprobaciones técnicas; la cola de lotes y la sincronización están pendientes.

## Convención para ampliar el código
Crear carpetas cuando exista código para ellas, evitando carpetas vacías que aparenten funciones terminadas.
- Web: `src/features/auth`, `lotes`, `dashboard` para módulos; `src/services` para API; `src/components` para elementos compartidos.
- Móvil: mantener vista / ViewModel / modelo separados; añadir vistas en `src/view`, acceso remoto en `src/services` y repositorios locales en `src/model` según se implementen.
- Backend: continuar controller / service / repository; añadir DTOs en `dto` y modelos en `model` cuando sean necesarios. Las decisiones de calidad y permisos se verifican en el servidor.
- Cada pantalla nueva debe tener estados de carga, éxito, vacío y error.

Estas convenciones son propuestas para el desarrollo siguiente; no indican que esos módulos existan hoy.
