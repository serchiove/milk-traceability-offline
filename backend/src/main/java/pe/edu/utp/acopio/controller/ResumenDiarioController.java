package pe.edu.utp.acopio.controller;

import java.time.LocalDate;
import java.util.Map;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import pe.edu.utp.acopio.security.OperarioPrincipal;
import pe.edu.utp.acopio.repository.UsuarioRepository;
import pe.edu.utp.acopio.report.ExportadorResumenDiario;
import pe.edu.utp.acopio.service.*;

/** Resumen diario y envío manual, exclusivamente para JEFATURA del centro autenticado. */
@RestController
@RequestMapping("/api/reportes/diario")
public class ResumenDiarioController {
  private final ResumenDiarioService resumenes;
  private final ExportadorResumenDiario pdf;
  private final CorreoResumenService correo;
  private final UsuarioRepository usuarios;
  public ResumenDiarioController(ResumenDiarioService resumenes, ExportadorResumenDiario pdf,
      CorreoResumenService correo, UsuarioRepository usuarios) {
    this.resumenes = resumenes; this.pdf = pdf; this.correo = correo; this.usuarios = usuarios;
  }
  public record Solicitud(@NotNull LocalDate fecha) {}
  private ResumenDiarioService.Resumen resumen(OperarioPrincipal usuario, LocalDate fecha) {
    var cuenta = usuarios.buscarPorEmail(usuario.email()).orElseThrow(RecursoNoEncontradoException::new);
    return resumenes.consultar(usuario, fecha, cuenta.centro());
  }
  @GetMapping public ResponseEntity<?> consultar(@AuthenticationPrincipal OperarioPrincipal usuario,
      @RequestParam @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate fecha) {
    return ResponseEntity.ok().header("Cache-Control", "no-store")
        .body(Map.of("resumen", resumen(usuario, fecha), "correoDisponible", correo.disponible(),
            "remitente", correo.remitente()));
  }
  @GetMapping(value="/pdf", produces="application/pdf")
  public ResponseEntity<byte[]> descargar(@AuthenticationPrincipal OperarioPrincipal usuario,
      @RequestParam @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate fecha) {
    return ResponseEntity.ok().header("Cache-Control", "no-store")
        .header("Content-Disposition", "attachment; filename=acopio-resumen-" + fecha + ".pdf")
        .body(pdf.pdf(resumen(usuario, fecha)));
  }
  @PostMapping("/correo") public ResponseEntity<?> enviar(@AuthenticationPrincipal OperarioPrincipal usuario,
      @Valid @RequestBody Solicitud solicitud) {
    var resumen = resumen(usuario, solicitud.fecha());
    correo.enviar(resumen, pdf.pdf(resumen));
    return ResponseEntity.ok().header("Cache-Control", "no-store").body(Map.of(
        "mensaje", "Gmail aceptó el correo para envío. Revisa también Spam.",
        "destinatario", resumen.destinatario(), "corte", resumen.corte().toString()));
  }
}
