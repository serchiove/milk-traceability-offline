package pe.edu.utp.acopio.repository;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.DTO.tanque.*;

@Repository
public class TanqueRepository {
    private final JdbcTemplate db;
    public TanqueRepository(JdbcTemplate db) {this.db=db;}
    private final RowMapper<TanqueDto> mapper=(rs,n)->new TanqueDto(rs.getLong("id_tanque"),rs.getString("codigo"),
        rs.getString("estado"),rs.getBigDecimal("capacidad_litros"),rs.getBigDecimal("volumen_asignado_litros"),
        rs.getBigDecimal("capacidad_litros").subtract(rs.getBigDecimal("volumen_asignado_litros")));
    public record LoteDestino(UUID id, BigDecimal volumen, String estado, Long tanque) {}
    public Optional<LoteDestino> bloquearLote(Long centro, UUID id) {
        return db.query("""
            SELECT l.id_lote,l.volumen_litros,l.id_tanque,r.estado_evaluacion
            FROM acopio.lote_leche l JOIN acopio.registro_calidad r USING(id_lote)
            WHERE l.id_centro=? AND l.id_lote=? FOR UPDATE OF l
            """,(rs,n)->new LoteDestino(rs.getObject("id_lote",UUID.class),rs.getBigDecimal("volumen_litros"),
                rs.getString("estado_evaluacion"),rs.getObject("id_tanque",Long.class)),centro,id).stream().findFirst();
    }
    public Optional<TanqueDto> bloquearTanque(Long centro, Long id) {
        return db.query("SELECT * FROM acopio.tanque WHERE id_centro=? AND id_tanque=? FOR UPDATE",mapper,centro,id).stream().findFirst();
    }
    public Pagina<TanqueDto> listar(Long centro, boolean disponibles, int pagina, int tamano) {
        String filtro=" FROM acopio.tanque WHERE id_centro=?" +
            (disponibles ? " AND estado='DISPONIBLE' AND volumen_asignado_litros<capacidad_litros" : "");
        long total=db.queryForObject("SELECT count(*)"+filtro,Long.class,centro);
        var elementos=db.query("SELECT *"+filtro+" ORDER BY codigo,id_tanque LIMIT ? OFFSET ?",mapper,centro,tamano,(long)pagina*tamano);
        return new Pagina<>(elementos,total,pagina,tamano);
    }
    public void asignar(UUID lote, Long tanque, Long usuario) {
        // The existing database trigger reserves capacity exactly once in this transaction.
        int filas=db.update("""
            UPDATE acopio.lote_leche SET id_tanque=?,asignado_en=CURRENT_TIMESTAMP,id_usuario_asigna=?
            WHERE id_lote=? AND id_tanque IS NULL
            """,tanque,usuario,lote);
        if(filas!=1) throw new IllegalStateException("No se pudo confirmar la asignacion");
    }
    public AsignacionDto resultado(Long centro, UUID lote, boolean idempotente) {
        return db.queryForObject("""
            SELECT l.id_lote,l.id_tanque,t.codigo,l.volumen_litros,l.asignado_en,l.id_usuario_asigna
            FROM acopio.lote_leche l JOIN acopio.tanque t USING(id_tanque)
            WHERE l.id_centro=? AND l.id_lote=?
            """,(rs,n)->new AsignacionDto(rs.getObject("id_lote",UUID.class),rs.getLong("id_tanque"),
                rs.getString("codigo"),rs.getBigDecimal("volumen_litros"),rs.getObject("asignado_en",OffsetDateTime.class),
                rs.getLong("id_usuario_asigna"),idempotente),centro,lote);
    }
}
