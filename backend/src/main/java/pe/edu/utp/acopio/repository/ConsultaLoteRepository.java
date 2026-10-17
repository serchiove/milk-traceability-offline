package pe.edu.utp.acopio.repository;

import java.time.OffsetDateTime;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.DTO.consulta.*;

@Repository
public class ConsultaLoteRepository {
    private final JdbcTemplate db;
    public ConsultaLoteRepository(JdbcTemplate db) {this.db = db;}
    private static final String SELECT = """
        SELECT t.*,l.id_proveedor,l.id_vehiculo,l.id_usuario,l.id_tanque
        FROM acopio.v_trazabilidad t JOIN acopio.lote_leche l USING(id_lote)
        """;
    private final RowMapper<LoteDetalleDto> mapper = (rs,n) -> new LoteDetalleDto(
        rs.getObject("id_lote",UUID.class),rs.getLong("id_centro"),rs.getString("centro"),
        rs.getLong("id_proveedor"),rs.getString("proveedor"),rs.getLong("id_vehiculo"),rs.getString("placa"),
        rs.getLong("id_usuario"),rs.getString("operario"),rs.getObject("fecha_hora",OffsetDateTime.class),
        rs.getObject("recibido_en",OffsetDateTime.class),rs.getBigDecimal("volumen_litros"),
        rs.getBigDecimal("temperatura_c"),rs.getBigDecimal("acidez_dornic"),rs.getBigDecimal("densidad_g_ml"),
        rs.getString("estado_evaluacion"),rs.getString("version_reglas"),rs.getString("motivo"),
        rs.getObject("fecha_evaluacion",OffsetDateTime.class),rs.getString("codigo_qr"),
        rs.getObject("id_tanque",Long.class),rs.getString("tanque"),rs.getObject("asignado_en",OffsetDateTime.class));

    public Optional<LoteDetalleDto> detalle(Long centro, UUID id) {
        return db.query(SELECT + " WHERE t.id_centro=? AND t.id_lote=?",mapper,centro,id).stream().findFirst();
    }
    public Pagina<LoteDetalleDto> listar(Long centro, String estado, OffsetDateTime desde, OffsetDateTime hasta,
                                         String buscar, int pagina, int tamano) {
        StringBuilder filtro = new StringBuilder(" WHERE t.id_centro=?");
        List<Object> parametros = new ArrayList<>(); parametros.add(centro);
        if (estado != null) {filtro.append(" AND t.estado_evaluacion=?"); parametros.add(estado);}
        if (desde != null) {filtro.append(" AND t.fecha_hora>=?"); parametros.add(desde);}
        if (hasta != null) {filtro.append(" AND t.fecha_hora<?"); parametros.add(hasta);}
        if (!buscar.isEmpty()) {
            filtro.append(" AND position(lower(?) in lower(t.proveedor || ' ' || t.placa || ' ' || t.id_lote::text))>0");
            parametros.add(buscar);
        }
        long total = db.queryForObject("SELECT count(*) FROM acopio.v_trazabilidad t" + filtro,Long.class,parametros.toArray());
        parametros.add(tamano); parametros.add((long)pagina*tamano);
        var elementos = db.query(SELECT + filtro + " ORDER BY t.fecha_hora DESC,t.id_lote DESC LIMIT ? OFFSET ?",mapper,parametros.toArray());
        return new Pagina<>(elementos,total,pagina,tamano);
    }
}
