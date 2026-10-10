# Inicio rápido

## Computadora de Sergio
1. Trabajar siempre en esta carpeta `acopio-app` de Documents; evitar mezclarla con la copia del Desktop.
2. Abrir `Iniciar.cmd`: inicia PostgreSQL, backend y dashboard.
3. Abrir http://127.0.0.1:5173 y pulsar «Comprobar conexión real».
4. Para Android, conectar USB con depuración autorizada y ejecutar desde PowerShell en esta carpeta:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Conectar-Android.ps1
```

5. Ejecutar `Abrir_Movil.cmd`, esperar que Metro esté listo y pulsar `a`.
6. Al terminar, ejecutar `Detener.cmd`.

| Archivo | Función |
|---|---|
| Iniciar.cmd | Arrancar base, backend y web |
| Abrir_Movil.cmd | Arrancar Expo para Android |
| Verificar.cmd | Consultar estado de servicios |
| Probar_Proyecto.cmd | Compilar backend/web y comprobar tipos del móvil |
| Detener.cmd | Detener los servicios del proyecto |

## Otra computadora
Requisitos: Java 17, Maven 3.9+, Node 24 LTS, PostgreSQL 18 y Git. Android requiere Expo Go compatible con SDK 57 y depuración USB, o emulador con ADB.
Descomprimir el paquete de código y ejecutar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Preparar.ps1
```

Después seguir los pasos de arranque. Cada computadora genera su propia base y contraseña; el paquete no incluye datos privados ni dependencias instaladas.
Los scripts buscan PostgreSQL en `C:\Program Files\PostgreSQL\18\bin`; usar `ACOPIO_PG_BIN` para otra ruta y `ACOPIO_NODE` para especificar Node.

## Puertos y errores
- Web: 5173. API: 18080. PostgreSQL: 55440. Metro: 8081.
- Diagnóstico: http://127.0.0.1:18080/api/estado.
- Logs locales: `.local/backend.log`, `.local/backend.error.log`, `.local/postgres.log`.
- Falta contraseña: preparar primero el entorno; no inventar un archivo de contraseña.
- Android no conecta: confirmar `adb devices`, volver a ejecutar Conectar-Android y mantener Metro abierto.
- No eliminar `.local/pgdata` ni ejecutar de nuevo el SQL del informe para reparar un error.
- `.env.example` es una referencia: los lanzadores usan la contraseña privada de `.local`, no cargan automáticamente ese archivo.


## Conectar PostgreSQL a pgAdmin

La base ya se crea en PostgreSQL mediante los scripts del proyecto. pgAdmin es una herramienta para administrarla; registrar la conexión permite ver la instancia existente.

1. Ejecutar Iniciar.cmd en la carpeta del proyecto y esperar a que los servicios estén disponibles.
2. Abrir pgAdmin. Hacer clic derecho en Servers, seleccionar Register y después Server.
3. En General, escribir Acopio Desarrollo como nombre.
4. En Connection, completar estos valores:

| Campo | Valor |
|---|---|
| Host name o address | 127.0.0.1 |
| Port | 55440 |
| Maintenance database | acopio_dev |
| Username | acopio_dev |
| Password | Contenido del archivo .local/db-password.txt de esta computadora |

5. Abrir el archivo de contraseña local y copiar su contenido sin espacios ni saltos de línea adicionales. No compartir esa contraseña ni incluirla en capturas, informes o GitHub. Cada computadora genera la suya.
6. Pulsar Save. Desplegar Servers → Acopio Desarrollo → Databases → acopio_dev → Schemas → acopio → Tables. Si es necesario, hacer clic derecho y seleccionar Refresh.
7. Deben aparecer nueve tablas: rol, centro_acopio, usuario, proveedor, vehiculo, tanque, lote_leche, registro_calidad e incidencia. Las tablas del proyecto están en acopio; public contiene el historial de migraciones de Flyway.

Si aparece connection timeout expired, confirmar que Iniciar.cmd terminó, revisar host 127.0.0.1 y puerto 55440 y ejecutar Verificar.cmd. Si continúa, revisar .local/postgres.log. Ese mensaje indica que no se alcanza el servidor; no exige recrear las tablas. Si aparece un error de autenticación, revisar usuario y contraseña local.
Al ejecutar Detener.cmd se detiene también esta instancia de PostgreSQL; para volver a conectarse desde pgAdmin, ejecutar Iniciar.cmd nuevamente. No confundir esta instancia con otros servidores de PostgreSQL que usen el puerto 5432.
