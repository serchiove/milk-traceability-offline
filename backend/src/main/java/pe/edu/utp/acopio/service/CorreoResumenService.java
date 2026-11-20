package pe.edu.utp.acopio.service;

import java.nio.charset.StandardCharsets;
import java.time.*;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.*;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import jakarta.mail.MessagingException;

/** SMTP solo desde el backend; el destinatario siempre procede de la sesión autenticada. */
@Service
public class CorreoResumenService {
  private final JavaMailSender sender;
  private final boolean habilitado;
  private final String remitente;
  private final ConcurrentHashMap<String, Instant> intentos = new ConcurrentHashMap<>();
  public CorreoResumenService(ObjectProvider<JavaMailSender> proveedor,
      @Value("${app.mail.enabled:false}") boolean habilitado,
      @Value("${spring.mail.username:}") String remitente) {
    this.sender = proveedor.getIfAvailable();
    this.habilitado = habilitado;
    this.remitente = remitente;
  }
  public boolean disponible() { return habilitado && sender != null && !remitente.isBlank(); }
  public String remitente() { return remitente; }
  public void enviar(ResumenDiarioService.Resumen resumen, byte[] pdf) {
    if (!disponible()) throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
        "Configura Gmail en el servidor antes de enviar correos");
    String destino = resumen.destinatario();
    try { new jakarta.mail.internet.InternetAddress(destino, true).validate(); }
    catch (jakarta.mail.internet.AddressException e) { throw new IllegalArgumentException("Correo de cuenta inválido", e); }
    var ahora = Instant.now();
    intentos.compute(destino, (key, anterior) -> {
      if (anterior != null && anterior.plusSeconds(60).isAfter(ahora))
        throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Espera un minuto antes de reenviar");
      return ahora;
    });
    try {
      var mensaje = sender.createMimeMessage();
      var helper = new MimeMessageHelper(mensaje, true, StandardCharsets.UTF_8.name());
      helper.setFrom(remitente);
      helper.setTo(destino);
      helper.setSubject("ACOPIO | Resumen diario | " + resumen.fecha() + " | " + resumen.centro());
      var r = resumen.reporte();
      helper.setText("Resumen diario de ACOPIO\nCentro: " + resumen.centro() + "\nFecha de captura: " + resumen.fecha()
          + "\nCorte de consulta: " + resumen.corte() + " (Lima)\n\n"
          + "Recepciones: " + r.total() + "\nVolumen recibido: " + r.volumenLitros() + " L\n"
          + "Aprobadas: " + r.aprobados() + " — " + r.volumenAprobadoLitros() + " L\n"
          + "Rechazadas: " + r.rechazados() + " — " + r.volumenRechazadoLitros() + " L\n"
          + "Pendientes: " + r.pendientes() + " — " + r.volumenPendienteLitros() + " L\n\n"
          + "Se adjunta el PDF. Incluye capturas de esa fecha sincronizadas al servidor al consultar. "
          + "No incluye registros pendientes de sincronizar en los teléfonos.\n");
      helper.addAttachment("acopio-resumen-" + resumen.fecha() + ".pdf", new ByteArrayResource(pdf), "application/pdf");
      sender.send(mensaje);
    } catch (MessagingException | MailException e) {
      // No devolver credenciales ni detalles SMTP al navegador.
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
          "Gmail no confirmó el envío. Revisa la configuración y la bandeja antes de reintentar");
    }
  }
}
