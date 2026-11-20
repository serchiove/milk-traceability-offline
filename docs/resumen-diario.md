# Resumen diario por correo

Disponible en Dashboard > Resumen diario, y mediante el acceso de Reportes, para JEFATURA.
El resumen se carga automáticamente al entrar o cambiar de fecha y muestra remitente,
destinatario autorizado y estado de configuración de Gmail. Descargar PDF o pulsar **Enviar resumen por correo**. No hay envío automático.
El destinatario se configura por centro en el servidor (`app.mail.centros.ID.destinatario`).
Si no hay configuración, se usa el email de la cuenta autenticada. No se acepta un destinatario
ni un centro enviados por el navegador. Una cuenta ficticia necesita un destinatario real configurado.

## Qué incluye

- Capturas de la fecha elegida (00:00 a 00:00 siguiente, America/Lima) que ya están en el backend.
- Conteos y litros totales, aprobados, rechazados y pendientes.
- Motivos de rechazo agrupados y litros de esas recepciones por tanque (incluye sin asignar).
- Detalle de lote, fecha, productor, operario, litros, estado y tanque.
- Fecha/hora de corte de la consulta. No incluye capturas todavía offline. Una sincronización
  tardía puede cambiar un resumen de una fecha pasada. Las evaluaciones y asignaciones son
  las actuales al consultar; no se reconstruye su estado histórico al cierre del día.

Los filtros de la tabla de reportes operativos no afectan al resumen diario. Vista previa,
descarga y envío consultan por separado; el PDF/correo puede incorporar nuevas sincronizaciones.
No es un reporte de inventario ni de ocupación acumulada de tanques. Máximo 10.000 recepciones.
Se admiten días sin registros y se rechazan fechas futuras. CSV, Excel y PPTX no cambian.

## Configuración Gmail

1. En Google activa verificación en dos pasos y genera una **contraseña de aplicación**:
   https://support.google.com/accounts/answer/185833?hl=es . Algunas cuentas institucionales
   no lo permiten; en ese caso se necesita OAuth2 o un SMTP autorizado por su administrador.
2. Desde la raíz del repositorio ejecuta:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Configurar-Correo.ps1
   ```

3. Introduce remitente, centro, destinatario y contraseña de aplicación en tu equipo.
   Si ya están preparados en el archivo local, solo solicita la contraseña. No enviarlos por chat.
   Se guardan en `.local/mail.properties`, ignorado por Git. No subir ni compartir esa carpeta.
4. Reinicia el backend con Detener.cmd / Iniciar.cmd. El proceso debe tener `backend` como
   directorio de trabajo, como ya hace Dev.ps1. La configuración se carga desde `../.local/mail.properties`.
5. Inicia sesión con una cuenta JEFATURA del centro configurado. Preparar
   resumen, revisar centro/fecha/destinatario y pulsar enviar. Revisar bandeja de entrada y Spam.

No hace falta que el destinatario sea Gmail. Debe estar autorizado para recibir datos de ese centro.
No cambies el destinatario directamente en el frontend ni edites usuarios sin respetar sus roles/centros.
Para deshabilitar envíos, poner `app.mail.enabled=false` en el archivo local y reiniciar.

Si se configura manualmente, usar `spring.mail.host=smtp.gmail.com`, puerto 587,
`spring.mail.username`, `spring.mail.password`, `mail.smtp.auth=true` y STARTTLS obligatorio.
No activar “aplicaciones poco seguras”: es una instrucción antigua del material de clase.
Los timeouts SMTP están limitados. Un fallo del servidor devuelve un mensaje sin credenciales.
SMTP aceptado no garantiza entrega; comprobar la bandeja antes de reintentar tras errores de red.
El envío se limita a un intento por minuto por destinatario, en memoria (se reinicia con el backend).

## API y plantilla

- `GET /api/reportes/diario?fecha=2026-11-18`: vista previa y disponibilidad de configuración SMTP.
- `GET /api/reportes/diario/pdf?fecha=2026-11-18`: PDF JasperReports.
- `POST /api/reportes/diario/correo`, JSON `{"fecha":"2026-11-18"}`: envío al destinatario autorizado del centro.
- Todas requieren JWT JEFATURA. Correo no configurado: 503; error SMTP: 502;
  reenvío antes de un minuto: 429. No se comprueba la conexión Gmail en la vista previa.

Editar `docs/plantillas-academicas/04_Resumen_diario.jrxml` en Jaspersoft Studio y recompilar
el backend con `backend/mvnw.cmd` antes de reiniciar. Los informes académicos existentes
usan sus propias plantillas y se conservan.

## Puerto PostgreSQL local

Dev.ps1 admite `ACOPIO_DB_PORT` o `.local/db-port.txt` y conserva 55440 como valor
predeterminado. Si Windows reserva ese puerto (`netsh interface ipv4 show excludedportrange protocol=tcp`),
elegir uno libre sin cambiar las reservas del sistema. En este equipo se usa 55430;
al conectar pgAdmin usar ese puerto. Las credenciales y la base existentes se conservan.
