package pe.edu.utp.acopio.service;

import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import pe.edu.utp.acopio.security.OperarioPrincipal;

/** Resumen de capturas de una fecha de Lima presentes en la consulta del servidor. */
@Service
public class ResumenDiarioService {
  private final ReporteService reportes;
  private final Clock clock;
  @org.springframework.beans.factory.annotation.Autowired
  private org.springframework.core.env.Environment environment;
  @Autowired public ResumenDiarioService(ReporteService reportes) {
    this(reportes, Clock.system(ZoneId.of("America/Lima")));
  }
  public ResumenDiarioService(ReporteService reportes, Clock clock) {
    this.reportes = reportes;
    this.clock = clock;
  }
  public record Grupo(String nombre, long recepciones, BigDecimal litros) {}
  public record Resumen(LocalDate fecha, OffsetDateTime corte, String centro, String destinatario,
      ReporteService.Reporte reporte, List<Grupo> motivosRechazo, List<Grupo> tanques) {}

  public Resumen consultar(OperarioPrincipal usuario, LocalDate fecha, String centro) {
    if (fecha == null || fecha.isAfter(LocalDate.now(clock)))
      throw new IllegalArgumentException("Selecciona una fecha hasta hoy");
    // Sin filtros de estado/búsqueda: el resumen abarca todas las capturas del día del centro.
    var reporte = reportes.consultar(usuario.idCentro(), null, fecha, fecha, "");
    var motivos = new TreeMap<String, List<pe.edu.utp.acopio.DTO.consulta.LoteDetalleDto>>();
    var tanques = new TreeMap<String, List<pe.edu.utp.acopio.DTO.consulta.LoteDetalleDto>>();
    for (var lote : reporte.registros()) {
      if ("RECHAZADO".equals(lote.estadoEvaluacion()))
        motivos.computeIfAbsent(texto(lote.motivo(), "Sin motivo registrado"), k -> new ArrayList<>()).add(lote);
      tanques.computeIfAbsent(texto(lote.tanque(), "Sin tanque asignado"), k -> new ArrayList<>()).add(lote);
    }
    String destinatario = environment == null ? usuario.email()
        : environment.getProperty("app.mail.centros." + usuario.idCentro() + ".destinatario", usuario.email());
    return new Resumen(fecha, OffsetDateTime.now(clock), centro, destinatario, reporte,
        grupos(motivos), grupos(tanques));
  }
  private static List<Grupo> grupos(Map<String, List<pe.edu.utp.acopio.DTO.consulta.LoteDetalleDto>> mapa) {
    return mapa.entrySet().stream().map(e -> new Grupo(e.getKey(), e.getValue().size(),
        e.getValue().stream().map(l -> l.volumenLitros()).reduce(BigDecimal.ZERO, BigDecimal::add))).toList();
  }
  private static String texto(String valor, String defecto) {
    return valor == null || valor.isBlank() ? defecto : valor;
  }
}
