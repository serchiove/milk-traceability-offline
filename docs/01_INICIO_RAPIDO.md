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
