package pe.edu.utp.acopio.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.DTO.lote.LoteRecepcionRequest;

//import java.sql.Timestamp;
import java.time.OffsetDateTime;
//import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class LoteRepository {

    private final JdbcTemplate jdbcTemplate;

    public LoteRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public record EstadoLoteBD(
        UUID idLote,
        String huellaSolicitud,
        String codigoQr,
        OffsetDateTime recibidoEn,
        String estadoEvaluacion,
        String versionReglas,
        String motivo,
        OffsetDateTime fechaEvaluacion
    ) {}

    private final RowMapper<EstadoLoteBD> estadoLoteMapper = (rs, rowNum) -> new EstadoLoteBD(
        UUID.fromString(rs.getString("id_lote")),
        rs.getString("huella_solicitud"),
        rs.getString("codigo_qr"),
        rs.getObject("recibido_en", OffsetDateTime.class),
        rs.getString("estado_evaluacion"),
        rs.getString("version_reglas"),
        rs.getString("motivo"),
        rs.getObject("fecha_evaluacion", OffsetDateTime.class)
    );

    public boolean insertarLoteSiNoExiste(LoteRecepcionRequest req, Long idUsuario, Long idCentro, String huella) {
        String sql = """
            INSERT INTO acopio.lote_leche (
                id_lote, id_proveedor, id_vehiculo, id_usuario, id_centro,
                fecha_hora, volumen_litros, huella_solicitud
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT (id_lote) DO NOTHING
            """;
        int filas = jdbcTemplate.update(
            sql,
            req.idLote(),
            req.idProveedor(),
            req.idVehiculo(),
            idUsuario,
            idCentro,
            req.fechaHora(),
            req.volumenLitros(),
            huella
        );
        return filas > 0;
    }

    public void insertarRegistroCalidadPendiente(LoteRecepcionRequest req) {
        String sql = """
            INSERT INTO acopio.registro_calidad (
                id_lote, temperatura_c, acidez_dornic, densidad_g_ml, estado_evaluacion
            ) VALUES (?, ?, ?, ?, 'PENDIENTE')
            ON CONFLICT (id_lote) DO NOTHING
            """;
        jdbcTemplate.update(
            sql,
            req.idLote(),
            req.mediciones().temperaturaC(),
            req.mediciones().acidezDornic(),
            req.mediciones().densidadGml()
        );
    }

    public int actualizarEvaluacionCalidad(UUID idLote, String estado, String versionReglas, String motivo) {
        String sql = """
            UPDATE acopio.registro_calidad
            SET estado_evaluacion = ?,
                fecha_evaluacion = CURRENT_TIMESTAMP,
                version_reglas = ?,
                motivo = ?
            WHERE id_lote = ? AND estado_evaluacion = 'PENDIENTE'
            """;
        return jdbcTemplate.update(sql, estado, versionReglas, motivo, idLote);
    }

    public Optional<EstadoLoteBD> buscarEstadoLote(UUID idLote) {
        String sql = """
            SELECT l.id_lote,
                   l.huella_solicitud,
                   l.codigo_qr,
                   l.recibido_en,
                   r.estado_evaluacion,
                   r.version_reglas,
                   r.motivo,
                   r.fecha_evaluacion
            FROM acopio.lote_leche l
            INNER JOIN acopio.registro_calidad r ON l.id_lote = r.id_lote
            WHERE l.id_lote = ?
            """;
        List<EstadoLoteBD> lista = jdbcTemplate.query(sql, estadoLoteMapper, idLote);
        return lista.stream().findFirst();
    }
}
