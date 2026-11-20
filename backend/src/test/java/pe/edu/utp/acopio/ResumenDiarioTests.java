package pe.edu.utp.acopio;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mail.MailSendException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.web.server.ResponseStatusException;
import pe.edu.utp.acopio.DTO.consulta.LoteDetalleDto;
import pe.edu.utp.acopio.report.ExportadorResumenDiario;
import pe.edu.utp.acopio.security.OperarioPrincipal;
import pe.edu.utp.acopio.service.*;

class ResumenDiarioTests {
  private final LocalDate fecha = LocalDate.of(2026, 11, 18);
  private final OperarioPrincipal usuario = new OperarioPrincipal(1L, 42L, "jefe@example.com", "JEFATURA");
  private final Clock clock = Clock.fixed(Instant.parse("2026-11-19T03:30:00Z"), ZoneId.of("America/Lima"));
  private ReporteService.Reporte reporte() {
    var tiempo = OffsetDateTime.parse("2026-11-18T14:00:00-05:00");
    var filas = new ArrayList<LoteDetalleDto>();
    for (String estado : List.of("APROBADO", "RECHAZADO", "PENDIENTE")) {
      filas.add(new LoteDetalleDto(UUID.randomUUID(), 42L, "Centro Ñandú", 2L, "Productor Pérez", 3L,
          "ABC-123", 1L, "Operario", tiempo, tiempo, new BigDecimal("100.25"),
          new BigDecimal("4"), new BigDecimal("16"), new BigDecimal("1.03"), estado,
          "DEMO-1", "RECHAZADO".equals(estado) ? "Temperatura fuera de rango" : null,
          tiempo, null, "APROBADO".equals(estado) ? 4L : null,
          "APROBADO".equals(estado) ? "TQ-01" : null, null));
    }
    return new ReporteService.Reporte(filas, 3, new BigDecimal("300.75"), 1, 1, 1, 33.3, 33.3,
        List.of(), new BigDecimal("100.25"), new BigDecimal("100.25"), new BigDecimal("100.25"), 33.3, 33.3);
  }
  private ResumenDiarioService.Resumen resumen() {
    var reportes = mock(ReporteService.class);
    when(reportes.consultar(42L, null, fecha, fecha, "")).thenReturn(reporte());
    return new ResumenDiarioService(reportes, clock).consultar(usuario, fecha, "Centro Ñandú");
  }
  @Test void dailyScopeUsesAuthenticatedCenterAllStatusesAndLimaDay() {
    var reportes = mock(ReporteService.class);
    when(reportes.consultar(42L, null, fecha, fecha, "")).thenReturn(reporte());
    var service = new ResumenDiarioService(reportes, clock);
    var resumen = service.consultar(usuario, fecha, "Centro Ñandú");
    verify(reportes).consultar(42L, null, fecha, fecha, "");
    assertThat(resumen.corte().getOffset()).isEqualTo(ZoneOffset.ofHours(-5));
    assertThat(resumen.destinatario()).isEqualTo(usuario.email());
    assertThat(resumen.motivosRechazo()).containsExactly(new ResumenDiarioService.Grupo("Temperatura fuera de rango", 1, new BigDecimal("100.25")));
    assertThat(resumen.tanques()).extracting(ResumenDiarioService.Grupo::litros)
        .containsExactly(new BigDecimal("200.50"), new BigDecimal("100.25"));
    assertThatThrownBy(() -> service.consultar(usuario, fecha.plusDays(1), "Centro"))
        .isInstanceOf(IllegalArgumentException.class);
  }
  @Test void pdfContainsMetricsRejectionTankDetailsAndEmptyDay() throws Exception {
    var exportador = new ExportadorResumenDiario();
    byte[] bytes = exportador.pdf(resumen());
    try (var doc = org.apache.pdfbox.Loader.loadPDF(bytes)) {
      assertThat(new org.apache.pdfbox.text.PDFTextStripper().getText(doc)).contains(
          "RESUMEN DIARIO", "Centro Ñandú", "18/11/2026", "300.75", "100.25",
          "Temperatura fuera de rango", "TQ-01", "Productor Pérez", "pendientes en los teléfonos");
    }
    java.nio.file.Files.write(java.nio.file.Path.of("target/resumen-diario-muestra.pdf"), bytes);
    var vacio = new ReporteService.Reporte(List.of(), 0, BigDecimal.ZERO, 0, 0, 0, 0, 0,
        List.of(), BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0, 0);
    var resumen = new ResumenDiarioService.Resumen(fecha, OffsetDateTime.now(clock), "Centro vacío", usuario.email(), vacio, List.of(), List.of());
    byte[] empty = exportador.pdf(resumen);
    try (var doc = org.apache.pdfbox.Loader.loadPDF(empty)) {
      assertThat(new org.apache.pdfbox.text.PDFTextStripper().getText(doc)).contains("Recepciones: 0", "Sin rechazos", "Sin recepciones");
    }
    java.nio.file.Files.write(java.nio.file.Path.of("target/resumen-diario-vacio.pdf"), empty);
  }
  @Test void recipientOverrideIsScopedToTheAuthenticatedCenter() {
    var reportes = mock(ReporteService.class);
    when(reportes.consultar(42L, null, fecha, fecha, "")).thenReturn(reporte());
    var service = new ResumenDiarioService(reportes, clock);
    var env = new org.springframework.mock.env.MockEnvironment()
        .withProperty("app.mail.centros.42.destinatario", "autorizado@example.com")
        .withProperty("app.mail.centros.99.destinatario", "otro@example.com");
    org.springframework.test.util.ReflectionTestUtils.setField(service, "environment", env);
    assertThat(service.consultar(usuario, fecha, "Centro").destinatario()).isEqualTo("autorizado@example.com");
    env.getPropertySources().remove("mockProperties");
    assertThat(service.consultar(usuario, fecha, "Centro").destinatario()).isEqualTo(usuario.email());
  }
  @SuppressWarnings("unchecked")
  private CorreoResumenService correo(JavaMailSender sender, boolean enabled) {
    var provider = mock(ObjectProvider.class);
    when(provider.getIfAvailable()).thenReturn(sender);
    return new CorreoResumenService(provider, enabled, "remitente@gmail.com");
  }
  @Test void mimeHasOnlyAuthenticatedRecipientPdfAndBlocksImmediateResend() throws Exception {
    var sender = mock(JavaMailSender.class);
    var mime = new MimeMessage(Session.getInstance(new Properties()));
    when(sender.createMimeMessage()).thenReturn(mime);
    var correo = correo(sender, true);
    correo.enviar(resumen(), "%PDF-prueba".getBytes(java.nio.charset.StandardCharsets.UTF_8));
    mime.saveChanges();
    verify(sender).send(mime);
    assertThat(mime.getAllRecipients()).hasSize(1);
    assertThat(mime.getAllRecipients()[0].toString()).isEqualTo("jefe@example.com");
    assertThat(mime.getSubject()).contains("2026-11-18", "Centro Ñandú");
    var out = new java.io.ByteArrayOutputStream(); mime.writeTo(out);
    assertThat(out.toString(java.nio.charset.StandardCharsets.UTF_8)).contains("application/pdf", "acopio-resumen-2026-11-18.pdf");
    assertThatThrownBy(() -> correo.enviar(resumen(), new byte[0]))
        .isInstanceOfSatisfying(ResponseStatusException.class, e -> assertThat(e.getStatusCode().value()).isEqualTo(429));
    verify(sender, times(1)).send(mime);
  }
  @Test void disabledSmtpNeverSendsAndFailuresDoNotExposeSecrets() {
    var sender = mock(JavaMailSender.class);
    assertThat(correo(sender, false).disponible()).isFalse();
    assertThatThrownBy(() -> correo(sender, false).enviar(resumen(), new byte[0]))
        .isInstanceOfSatisfying(ResponseStatusException.class, e -> assertThat(e.getStatusCode().value()).isEqualTo(503));
    verifyNoInteractions(sender);
    var mime = new MimeMessage(Session.getInstance(new Properties()));
    when(sender.createMimeMessage()).thenReturn(mime);
    doThrow(new MailSendException("contraseña-privada")).when(sender).send(mime);
    assertThatThrownBy(() -> correo(sender, true).enviar(resumen(), new byte[0]))
        .isInstanceOfSatisfying(ResponseStatusException.class, e -> {
          assertThat(e.getStatusCode().value()).isEqualTo(502);
          assertThat(e.getReason()).doesNotContain("contraseña-privada");
        });
  }
}
