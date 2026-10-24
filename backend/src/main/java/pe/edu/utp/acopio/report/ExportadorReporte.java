package pe.edu.utp.acopio.report;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.StringWriter;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.csv.QuoteMode;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Component;
import pe.edu.utp.acopio.DTO.consulta.LoteDetalleDto;
import pe.edu.utp.acopio.service.ReporteService.Reporte;

/**
 * Serializa el mismo reporte autorizado en CSV o XLSX, sin consultar la base de datos.
 * Los campos de texto de Excel se escriben como cadenas, nunca como fórmulas.
 */
@Component
public class ExportadorReporte {
  private static final String[] COLUMNAS = {
    "UUID", "Fecha captura", "Centro", "Proveedor", "Placa", "Operario", "Volumen L",
    "Temperatura C", "Acidez D", "Densidad g mL", "Estado", "Motivo", "Reglas", "Tanque", "QR"
  };

  /**
   * Genera CSV UTF-8 con BOM, finales CRLF y protección de texto para hojas de cálculo.
   *
   * @param reporte resultado filtrado por el servicio y el centro autenticado
   * @return contenido CSV con encabezados, incluso si no existen recepciones
   * @throws IllegalStateException si no se puede construir la salida
   */
  public String csv(Reporte reporte) {
    var formato = CSVFormat.DEFAULT.builder().setHeader(COLUMNAS)
        .setRecordSeparator("\r\n").setQuoteMode(QuoteMode.ALL).get();
    try (var salida = new StringWriter(); var csv = new CSVPrinter(salida, formato)) {
      for (var lote : reporte.registros()) {
        Object[] fila = valores(lote);
        for (int i = 0; i < fila.length; i++)
          if (fila[i] instanceof String texto) fila[i] = textoSeguroCsv(texto);
        csv.printRecord(fila);
      }
      csv.flush();
      return "\ufeff" + salida;
    } catch (IOException error) {
      throw new IllegalStateException("No se pudo generar el archivo CSV", error);
    }
  }

  /**
   * Genera un libro con mediciones numéricas, texto literal, filtros y cabecera inmovilizada.
   *
   * @param reporte resultado autorizado; se conserva el orden de sus registros
   * @return bytes del archivo XLSX con una hoja Recepciones
   * @throws IllegalStateException si no se puede escribir el libro
   */
  public byte[] xlsx(Reporte reporte) {
    try (var libro = new XSSFWorkbook(); var salida = new ByteArrayOutputStream()) {
      var hoja = libro.createSheet("Recepciones");
      var fuente = libro.createFont();
      fuente.setBold(true);
      var estiloCabecera = libro.createCellStyle();
      estiloCabecera.setFont(fuente);
      var decimal = libro.createCellStyle();
      decimal.setDataFormat(libro.createDataFormat().getFormat("0.00"));
      var densidad = libro.createCellStyle();
      densidad.setDataFormat(libro.createDataFormat().getFormat("0.0000"));
      var cabecera = hoja.createRow(0);
      for (int i = 0; i < COLUMNAS.length; i++) {
        var celda = cabecera.createCell(i);
        celda.setCellValue(COLUMNAS[i]);
        celda.setCellStyle(estiloCabecera);
        hoja.setColumnWidth(i, (i == 0 || i == 1 || i == 11 ? 38 : 22) * 256);
      }
      int numero = 1;
      for (var lote : reporte.registros()) {
        var fila = hoja.createRow(numero++);
        Object[] valores = valores(lote);
        for (int i = 0; i < valores.length; i++) {
          var celda = fila.createCell(i);
          Object valor = valores[i];
          if (valor instanceof Number medida) {
            celda.setCellValue(medida.doubleValue());
            celda.setCellStyle(i == 9 ? densidad : decimal);
          } else if (valor != null) {
            celda.setCellValue(valor.toString());
          }
        }
      }
      hoja.createFreezePane(0, 1);
      hoja.setAutoFilter(new CellRangeAddress(0, Math.max(0, numero - 1), 0, COLUMNAS.length - 1));
      libro.write(salida);
      return salida.toByteArray();
    } catch (IOException error) {
      throw new IllegalStateException("No se pudo generar el archivo Excel", error);
    }
  }

  private static Object[] valores(LoteDetalleDto lote) {
    return new Object[] {lote.idLote(), lote.fechaHora(), lote.centro(), lote.proveedor(),
        lote.placa(), lote.operario(), lote.volumenLitros(), lote.temperaturaC(), lote.acidezDornic(),
        lote.densidadGml(), lote.estadoEvaluacion(), lote.motivo(), lote.versionReglas(),
        lote.tanque(), lote.codigoQr()};
  }

  private static String textoSeguroCsv(String texto) {
    String sinEspacios = texto.stripLeading();
    if ((!sinEspacios.isEmpty() && "=+@-".indexOf(sinEspacios.charAt(0)) >= 0)
        || texto.startsWith("\t") || texto.startsWith("\r") || texto.startsWith("\n"))
      return "'" + texto;
    return texto;
  }
}
