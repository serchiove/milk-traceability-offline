package pe.edu.utp.acopio.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.utp.acopio.DTO.consulta.LoteDetalleDto;

@Service
/** Consulta un conjunto filtrado y consistente por centro para indicadores, CSV y XLSX. Limita la exportación a 10000 registros. */
public class ReporteService {
  private final ConsultaLoteService consultas;
  private final pe.edu.utp.acopio.report.ExportadorReporte exportador;
  @jakarta.persistence.PersistenceContext private jakarta.persistence.EntityManager em;

  public ReporteService(ConsultaLoteService consultas, pe.edu.utp.acopio.report.ExportadorReporte exportador) {
    this.consultas = consultas;
    this.exportador = exportador;
  }

  public record Incidencia(
      UUID idLote, long id, String tipo, String descripcion, java.time.OffsetDateTime fecha) {}

  public record Reporte(
      List<LoteDetalleDto> registros,
      long total,
      BigDecimal volumenLitros,
      long aprobados,
      long rechazados,
      long pendientes,
      double tasaAprobacion,
      double porcentajeLotesConIncidencia,
      List<Incidencia> incidencias,
      BigDecimal volumenAprobadoLitros,
      BigDecimal volumenRechazadoLitros,
      BigDecimal volumenPendienteLitros,
      double porcentajeVolumenAprobado,
      double porcentajeVolumenRechazado) {}

  /**
   * Reúne páginas, totales e incidencias en una lectura consistente.
   * @param centro centro de la identidad autenticada
   * @param estado estado de calidad o null para todos
   * @param desde primera fecha local inclusiva, opcional
   * @param hasta última fecha local inclusiva, opcional
   * @param buscar texto de búsqueda; cadena vacía para no restringir
   * @return registros y métricas calculados con los mismos filtros
   * @throws IllegalArgumentException si los filtros son inválidos o excede 10000 lotes
   */
  @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
  public Reporte consultar(
      Long centro, String estado, LocalDate desde, LocalDate hasta, String buscar) {
    var primera = consultas.listar(centro, estado, desde, hasta, buscar, 0, 100);
    if (primera.total() > 10000)
      throw new IllegalArgumentException("Reduce el periodo: maximo 10000 registros por reporte");
    List<LoteDetalleDto> filas = new ArrayList<>(primera.elementos());
    for (int pagina = 1; filas.size() < primera.total(); pagina++)
      filas.addAll(consultas.listar(centro, estado, desde, hasta, buscar, pagina, 100).elementos());
    long aprobados = filas.stream().filter(f -> "APROBADO".equals(f.estadoEvaluacion())).count();
    long rechazados = filas.stream().filter(f -> "RECHAZADO".equals(f.estadoEvaluacion())).count();
    BigDecimal volumen =
        filas.stream().map(LoteDetalleDto::volumenLitros).reduce(BigDecimal.ZERO, BigDecimal::add);
    BigDecimal volumenAprobado =
        filas.stream()
            .filter(f -> "APROBADO".equals(f.estadoEvaluacion()))
            .map(LoteDetalleDto::volumenLitros)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    BigDecimal volumenRechazado =
        filas.stream()
            .filter(f -> "RECHAZADO".equals(f.estadoEvaluacion()))
            .map(LoteDetalleDto::volumenLitros)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    List<Incidencia> incidencias =
        filas.isEmpty()
            ? List.of()
            : em.createQuery(
                    "select new"
                        + " pe.edu.utp.acopio.service.ReporteService$Incidencia(l.id,i.id,i.tipoAlerta,i.descripcion,i.fechaHora)"
                        + " from Incidencia i join i.registro r join r.lote l where"
                        + " l.centro.id=:centro and l.id in :ids order by i.fechaHora desc,i.id"
                        + " desc",
                    Incidencia.class)
                .setParameter("centro", centro)
                .setParameter("ids", filas.stream().map(LoteDetalleDto::idLote).toList())
                .getResultList();
    long lotesConIncidencia = incidencias.stream().map(Incidencia::idLote).distinct().count();
    return new Reporte(
        List.copyOf(filas),
        filas.size(),
        volumen,
        aprobados,
        rechazados,
        filas.size() - aprobados - rechazados,
        filas.isEmpty() ? 0 : 100.0 * aprobados / filas.size(),
        filas.isEmpty() ? 0 : 100.0 * lotesConIncidencia / filas.size(),
        incidencias,
        volumenAprobado,
        volumenRechazado,
        volumen.subtract(volumenAprobado).subtract(volumenRechazado),
        volumen.signum() == 0 ? 0 : 100.0 * volumenAprobado.doubleValue() / volumen.doubleValue(),
        volumen.signum() == 0 ? 0 : 100.0 * volumenRechazado.doubleValue() / volumen.doubleValue());
  }

  /**
   * Exporta el resultado autorizado sin volver a consultar ni cambiar sus filtros.
   * @param reporte resultado de consultar
   * @return CSV con encabezados y texto protegido
   */
  public String csv(Reporte reporte) {
    return exportador.csv(reporte);
  }

  /**
   * Exporta el mismo conjunto autorizado con mediciones numéricas en Excel.
   * @param reporte resultado de consultar
   * @return libro XLSX
   */
  public byte[] xlsx(Reporte reporte) {
    return exportador.xlsx(reporte);
  }
}
