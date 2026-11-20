package pe.edu.utp.acopio.report;

import java.io.IOException;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import net.sf.jasperreports.engine.*;
import net.sf.jasperreports.engine.data.JRMapCollectionDataSource;
import org.springframework.stereotype.Component;
import pe.edu.utp.acopio.service.ResumenDiarioService.Resumen;

/** Plantilla independiente del informe académico; editable en Jaspersoft Studio. */
@Component
public class ExportadorResumenDiario {
  private static final DateTimeFormatter FECHA = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
  private final JasperReport plantilla;
  public ExportadorResumenDiario() {
    try (var in = getClass().getResourceAsStream("/reports/academicas/04_Resumen_diario.jrxml")) {
      if (in == null) throw new IllegalStateException("Falta plantilla de resumen diario");
      plantilla = JasperCompileManager.compileReport(in);
    } catch (IOException | JRException e) { throw new IllegalStateException("No se pudo compilar el resumen diario", e); }
  }
  public byte[] pdf(Resumen resumen) {
    var r = resumen.reporte();
    Map<String, Object> p = new HashMap<>();
    p.put("centro", resumen.centro());
    p.put("fecha", resumen.fecha().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")));
    p.put("corte", FECHA.format(resumen.corte()) + " (Lima)");
    p.put("indicadores", "Recepciones: " + r.total() + "   |   Volumen recibido: " + r.volumenLitros() + " L\n"
        + "Aprobadas: " + r.aprobados() + " — " + r.volumenAprobadoLitros() + " L\n"
        + "Rechazadas: " + r.rechazados() + " — " + r.volumenRechazadoLitros() + " L\n"
        + "Pendientes de evaluación: " + r.pendientes() + " — " + r.volumenPendienteLitros() + " L");
    p.put("calidad", resumen.motivosRechazo().isEmpty() ? "Sin rechazos registrados."
        : resumen.motivosRechazo().stream().map(g -> g.nombre() + ": " + g.recepciones() + " recepción(es), " + g.litros() + " L").collect(java.util.stream.Collectors.joining("\n")));
    p.put("tanques", resumen.tanques().isEmpty() ? "Sin recepciones en esta fecha."
        : resumen.tanques().stream().map(g -> g.nombre() + ": " + g.litros() + " L").collect(java.util.stream.Collectors.joining("\n")));
    List<Map<String, ?>> filas = new ArrayList<>();
    for (var lote : r.registros()) {
      var fila = new HashMap<String, Object>();
      fila.put("detalle", "Lote: " + lote.idLote() + "\n"
          + FECHA.format(lote.fechaHora().atZoneSameInstant(ZoneId.of("America/Lima")))
          + " | Productor: " + lote.proveedor() + " | Operario: " + lote.operario() + "\n"
          + lote.volumenLitros() + " L | " + lote.estadoEvaluacion() + " | Tanque: "
          + (lote.tanque() == null ? "Sin asignar" : lote.tanque()));
      filas.add(fila);
    }
    try { return JasperExportManager.exportReportToPdf(JasperFillManager.fillReport(plantilla, p, new JRMapCollectionDataSource(filas))); }
    catch (JRException e) { throw new IllegalStateException("No se pudo generar el resumen diario", e); }
  }
}
