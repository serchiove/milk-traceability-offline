package pe.edu.utp.acopio.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Isolation;
import pe.edu.utp.acopio.DTO.consulta.LoteDetalleDto;

@Service
public class ReporteService {
    private final ConsultaLoteService consultas;
    private final org.springframework.jdbc.core.JdbcTemplate db;
    public ReporteService(ConsultaLoteService consultas,org.springframework.jdbc.core.JdbcTemplate db) { this.consultas=consultas;this.db=db; }
    public record Incidencia(UUID idLote, long id, String tipo, String descripcion, java.time.OffsetDateTime fecha) {}
    public record Reporte(List<LoteDetalleDto> registros, long total, BigDecimal volumenLitros,
                          long aprobados, long rechazados, long pendientes, double tasaAprobacion, double porcentajeLotesConIncidencia, List<Incidencia> incidencias,
                          BigDecimal volumenAprobadoLitros, BigDecimal volumenRechazadoLitros, BigDecimal volumenPendienteLitros,
                          double porcentajeVolumenAprobado, double porcentajeVolumenRechazado) {}
    @Transactional(readOnly=true, isolation=Isolation.REPEATABLE_READ)
    public Reporte consultar(Long centro, String estado, LocalDate desde, LocalDate hasta, String buscar) {
        var primera=consultas.listar(centro,estado,desde,hasta,buscar,0,100);
        if(primera.total()>10000) throw new IllegalArgumentException("Reduce el periodo: maximo 10000 registros por reporte");
        List<LoteDetalleDto> filas=new ArrayList<>(primera.elementos());
        for(int pagina=1;filas.size()<primera.total();pagina++)
            filas.addAll(consultas.listar(centro,estado,desde,hasta,buscar,pagina,100).elementos());
        long aprobados=filas.stream().filter(f->"APROBADO".equals(f.estadoEvaluacion())).count();
        long rechazados=filas.stream().filter(f->"RECHAZADO".equals(f.estadoEvaluacion())).count();
        BigDecimal volumen=filas.stream().map(LoteDetalleDto::volumenLitros).reduce(BigDecimal.ZERO,BigDecimal::add);
        BigDecimal volumenAprobado=filas.stream().filter(f->"APROBADO".equals(f.estadoEvaluacion())).map(LoteDetalleDto::volumenLitros).reduce(BigDecimal.ZERO,BigDecimal::add);
        BigDecimal volumenRechazado=filas.stream().filter(f->"RECHAZADO".equals(f.estadoEvaluacion())).map(LoteDetalleDto::volumenLitros).reduce(BigDecimal.ZERO,BigDecimal::add);
        String ids=filas.stream().map(f->f.idLote().toString()).collect(java.util.stream.Collectors.joining(",","{","}"));
        List<Incidencia> incidencias=db.query("SELECT r.id_lote,i.id_incidencia,i.tipo_alerta,i.descripcion,i.fecha_hora FROM acopio.incidencia i JOIN acopio.registro_calidad r USING(id_registro) JOIN acopio.lote_leche l USING(id_lote) WHERE l.id_centro=? AND l.id_lote=ANY(?::uuid[]) ORDER BY i.fecha_hora DESC,i.id_incidencia DESC",(rs,n)->new Incidencia(rs.getObject(1,UUID.class),rs.getLong(2),rs.getString(3),rs.getString(4),rs.getObject(5,java.time.OffsetDateTime.class)),centro,ids);
        long lotesConIncidencia=incidencias.stream().map(Incidencia::idLote).distinct().count();
        return new Reporte(List.copyOf(filas),filas.size(),volumen,aprobados,rechazados,filas.size()-aprobados-rechazados,
            filas.isEmpty()?0:100.0*aprobados/filas.size(),filas.isEmpty()?0:100.0*lotesConIncidencia/filas.size(),incidencias,
            volumenAprobado,volumenRechazado,volumen.subtract(volumenAprobado).subtract(volumenRechazado),
            volumen.signum()==0?0:100.0*volumenAprobado.doubleValue()/volumen.doubleValue(),
            volumen.signum()==0?0:100.0*volumenRechazado.doubleValue()/volumen.doubleValue());
    }
    public String csv(Reporte reporte) {
        StringBuilder csv=new StringBuilder("\ufeffUUID,Fecha captura,Centro,Proveedor,Placa,Operario,Volumen L,Temperatura C,Acidez D,Densidad g mL,Estado,Motivo,Reglas,Tanque,QR\r\n");
        for(var f:reporte.registros()) {
            Object[] valores={f.idLote(),f.fechaHora(),f.centro(),f.proveedor(),f.placa(),f.operario(),f.volumenLitros(),f.temperaturaC(),f.acidezDornic(),f.densidadGml(),f.estadoEvaluacion(),f.motivo(),f.versionReglas(),f.tanque(),f.codigoQr()};
            csv.append(Arrays.stream(valores).map(ReporteService::celda).collect(java.util.stream.Collectors.joining(","))).append("\r\n");
        }
        return csv.toString();
    }
    public static String celda(Object valor) {
        String texto=valor==null?"":valor.toString();
        // Prevent spreadsheet formula execution while keeping numeric measurements numeric.
        if(valor instanceof String && !texto.stripLeading().isEmpty() && "=+@-".indexOf(texto.stripLeading().charAt(0))>=0) texto="'"+texto;
        if(valor instanceof String && (texto.startsWith("\t") || texto.startsWith("\r") || texto.startsWith("\n"))) texto="'"+texto;
        return "\""+texto.replace("\"","\"\"")+"\"";
    }
}
