package pe.edu.utp.acopio;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.ByteArrayInputStream;
import java.io.StringReader;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.apache.commons.csv.CSVFormat;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import pe.edu.utp.acopio.DTO.consulta.LoteDetalleDto;
import pe.edu.utp.acopio.report.ExportadorReporte;
import pe.edu.utp.acopio.service.ReporteService.Reporte;

class ExportadorReporteTests {
  private final ExportadorReporte exportador = new ExportadorReporte();

  private Reporte reporte(String proveedor) {
    var fecha = OffsetDateTime.parse("2026-10-15T10:30:00-05:00");
    var lote = new LoteDetalleDto(UUID.fromString("11111111-1111-4111-8111-111111111111"),
        1L, "Centro ficticio", 2L, proveedor, 3L, "ABC-123", 4L, "Operario ficticio",
        fecha, fecha, new BigDecimal("120.50"), new BigDecimal("-5.00"), new BigDecimal("16.00"),
        new BigDecimal("1.0300"), "RECHAZADO", "DEMO-1", "Temperatura fuera de rango",
        fecha, null, null, null, null);
    return new Reporte(List.of(lote), 1, lote.volumenLitros(), 0, 1, 0, 0, 100,
        List.of(), BigDecimal.ZERO, lote.volumenLitros(), BigDecimal.ZERO, 0, 100);
  }

  @Test void csvRoundTripPreservesCommasQuotesNewlinesAndNumericPrecision() throws Exception {
    String proveedor = "Lechería, \"Sur\"\nArequipa";
    String csv = exportador.csv(reporte(proveedor));
    assertThat(csv).startsWith("\ufeff").endsWith("\r\n");
    try (var parser = CSVFormat.DEFAULT.builder().setHeader().setSkipHeaderRecord(true).get()
        .parse(new StringReader(csv.substring(1)))) {
      var filas = parser.getRecords();
      assertThat(filas).hasSize(1);
      assertThat(filas.get(0).get("Proveedor")).isEqualTo(proveedor);
      assertThat(filas.get(0).get("Volumen L")).isEqualTo("120.50");
      assertThat(filas.get(0).get("Temperatura C")).isEqualTo("-5.00");
      assertThat(filas.get(0).get("QR")).isEmpty();
    }
  }

  @Test void csvNeutralizesFormulaPrefixesButExcelPreservesLiteralText() throws Exception {
    for (String texto : List.of("=SUM(1,2)", "+1", "-1", "@funcion", "  =1", "\ttexto", "\ntexto")) {
      var reporte = reporte(texto);
      try (var parser = CSVFormat.DEFAULT.builder().setHeader().setSkipHeaderRecord(true).get()
          .parse(new StringReader(exportador.csv(reporte).substring(1)))) {
        assertThat(parser.getRecords().get(0).get("Proveedor")).isEqualTo("'" + texto);
      }
      try (var book = new XSSFWorkbook(new ByteArrayInputStream(exportador.xlsx(reporte)))) {
        var celda = book.getSheet("Recepciones").getRow(1).getCell(3);
        assertThat(celda.getCellType()).isEqualTo(CellType.STRING);
        assertThat(celda.getStringCellValue()).isEqualTo(texto);
      }
    }
  }

  @Test void excelAndCsvExposeTheSameColumnsAndReceipts() throws Exception {
    var reporte = reporte("Proveedor de prueba");
    try (var parser = CSVFormat.DEFAULT.builder().setHeader().setSkipHeaderRecord(true).get()
            .parse(new StringReader(exportador.csv(reporte).substring(1)));
        var book = new XSSFWorkbook(new ByteArrayInputStream(exportador.xlsx(reporte)))) {
      var sheet = book.getSheet("Recepciones");
      var filaCsv = parser.getRecords().get(0);
      for (int i = 0; i < parser.getHeaderNames().size(); i++)
        assertThat(sheet.getRow(0).getCell(i).getStringCellValue()).isEqualTo(parser.getHeaderNames().get(i));
      assertThat(sheet.getRow(1).getCell(0).getStringCellValue()).isEqualTo(filaCsv.get("UUID"));
      assertThat(sheet.getRow(1).getCell(6).getCellType()).isEqualTo(CellType.NUMERIC);
      assertThat(sheet.getRow(1).getCell(6).getNumericCellValue()).isEqualTo(120.5);
      assertThat(sheet.getRow(1).getCell(9).getNumericCellValue()).isEqualTo(1.03);
    }
  }
}
