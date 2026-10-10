# Repositorio del equipo

Repositorio: https://github.com/serchiove/milk-traceability-offline
Rama principal: main.

## Obtener el proyecto en otra computadora

```powershell
git clone https://github.com/serchiove/milk-traceability-offline.git
cd milk-traceability-offline
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Preparar.ps1
```

Preparar.ps1 requiere Java 17, Maven 3.9+, Node 24 LTS, Git y PostgreSQL 18 instalados. Ver docs/01_INICIO_RAPIDO.md.

## Trabajar en una función nueva

Con el árbol de trabajo limpio:

```powershell
git switch main
git pull --ff-only origin main
git switch -c feature/login-movil
```

Cambiar el nombre de rama según la función. Revisar git diff, ejecutar comprobaciones pertinentes, agregar solo los archivos de esa función y crear el commit. Publicar la rama y solicitar revisión antes de integrar en main.
No usar force push sobre main ni compartir credenciales. GitHub debe autenticar a cada integrante con su propia cuenta y acceso al repositorio.

## Qué se publica
Código fuente, archivos lock, migraciones, lanzadores y documentación. Se excluyen .local, contraseñas, archivos de entorno privados, dependencias instaladas y compilaciones. Las variables de ejemplo no contienen la contraseña real.
La carpeta del repositorio en GitHub es directamente la raíz del proyecto: backend, mobile y dashboard no están dentro de otra carpeta acopio-app.
