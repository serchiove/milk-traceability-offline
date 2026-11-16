package pe.edu.utp.acopio.report;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import net.sf.jasperreports.engine.*;
import net.sf.jasperreports.engine.data.JRMapCollectionDataSource;
import net.sf.jasperreports.engine.export.ooxml.JRPptxExporter;
import net.sf.jasperreports.export.SimpleExporterInput;
import net.sf.jasperreports.export.SimpleOutputStreamExporterOutput;
import org.springframework.stereotype.Component;
import pe.edu.utp.acopio.service.ReporteService.Reporte;

/** Llena las plantillas académicas PDF y PPTX con el conjunto autorizado, sin consultas adicionales. */
@Component
public class ExportadorPdf {
  private static final ZoneId LIMA = ZoneId.of("America/Lima");
  private static final DateTimeFormatter FECHA = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
  private final JasperReport plantillaPdf = compilar("01_PDF_academico.jrxml");
  private final JasperReport plantillaPptx = compilar("03_PowerPoint_academico.jrxml");

  private JasperReport compilar(String nombre) {
    try (var input = getClass().getResourceAsStream("/reports/academicas/" + nombre)) {
      if (input == null) throw new IllegalStateException("Falta la plantilla " + nombre);
      return JasperCompileManager.compileReport(input);
    } catch (JRException | IOException e) {
      throw new IllegalStateException("No se pudo compilar la plantilla " + nombre, e);
    }
  }

  public byte[] exportar(Reporte reporte, Long centro, String estado,
      LocalDate desde, LocalDate hasta, String buscar) {
    try {
      return JasperExportManager.exportReportToPdf(llenar(plantillaPdf, reporte, centro, estado, desde, hasta, buscar));
    } catch (JRException e) {
      throw new IllegalStateException("No se pudo generar el reporte PDF", e);
    }
  }

  public byte[] exportarPptx(Reporte reporte, Long centro, String estado,
      LocalDate desde, LocalDate hasta, String buscar) {
    try (var salida = new ByteArrayOutputStream()) {
      var documento = llenar(plantillaPptx, reporte, centro, estado, desde, hasta, buscar);
      var exporter = new JRPptxExporter();
      exporter.setExporterInput(new SimpleExporterInput(documento));
      exporter.setExporterOutput(new SimpleOutputStreamExporterOutput(salida));
      exporter.exportReport();
      return salida.toByteArray();
    } catch (JRException | IOException e) {
      throw new IllegalStateException("No se pudo generar el reporte PowerPoint", e);
    }
  }

  private JasperPrint llenar(JasperReport plantilla, Reporte reporte, Long centro, String estado,
      LocalDate desde, LocalDate hasta, String buscar) throws JRException {
    Map<String, Object> parametros = new HashMap<>();
    parametros.put(JRParameter.REPORT_LOCALE, Locale.forLanguageTag("es-PE"));
    parametros.put("centro", "Centro " + centro + (reporte.registros().isEmpty() ? "" : " · " + reporte.registros().get(0).centro()));
    parametros.put("filtros", "Estado: " + (estado == null || estado.isBlank() ? "Todos" : estado)
        + " | Desde: " + (desde == null ? "Sin límite" : desde)
        + " | Hasta: " + (hasta == null ? "Sin límite" : hasta)
        + " | Buscar: " + (buscar == null || buscar.isBlank() ? "Todos" : buscar));
    parametros.put("generado", "Generado: " + FECHA.format(ZonedDateTime.now(LIMA)) + " (Lima)");
    List<Map<String, ?>> filas = new ArrayList<>();
    for (var lote : reporte.registros()) {
      Map<String, Object> fila = new HashMap<>();
      fila.put("lote", lote.idLote().toString());
      fila.put("fecha", FECHA.format(lote.fechaHora().atZoneSameInstant(LIMA)));
      fila.put("proveedor", texto(lote.proveedor()));
      fila.put("placa", texto(lote.placa()));
      fila.put("volumen", lote.volumenLitros());
      fila.put("temperatura", lote.temperaturaC());
      fila.put("estado", texto(lote.estadoEvaluacion()));
      fila.put("tanque", texto(lote.tanque()));
      fila.put("motivo", lote.motivo() == null ? "" : lote.motivo());
      filas.add(fila);
    }
    // El JRDataSource explícito sustituye la consulta CSV utilizada únicamente por Preview en Studio.
    return JasperFillManager.fillReport(plantilla, parametros, new JRMapCollectionDataSource(filas));
  }

  private static String texto(Object valor) { return valor == null ? "-" : valor.toString(); }
}
