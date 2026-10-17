package pe.edu.utp.acopio.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.model.Usuario;

import java.util.List;
import java.util.Optional;

@Repository
public class UsuarioRepository {

    private final JdbcTemplate jdbcTemplate;

    public UsuarioRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Usuario> usuarioRowMapper = (rs, rowNum) -> new Usuario(
        rs.getLong("id_usuario"),
        rs.getLong("id_centro"),
        rs.getString("nombre"),
        rs.getString("dni"),
        rs.getString("email"),
        rs.getString("password_hash"),
        rs.getString("rol"),
        rs.getString("centro"),
        rs.getBoolean("activo")
    );

    public Optional<Usuario> buscarPorEmail(String email) {
        String sql = """
            SELECT u.id_usuario,
                   u.id_centro,
                   u.nombre,
                   u.dni,
                   u.email,
                   u.password_hash,
                   r.nombre AS rol,
                   c.nombre AS centro,
                   (u.activo AND c.activo) AS activo
            FROM acopio.usuario u
            INNER JOIN acopio.rol r ON u.id_rol = r.id_rol
            INNER JOIN acopio.centro_acopio c ON c.id_centro = u.id_centro
            WHERE LOWER(u.email) = LOWER(?)
            """;
        List<Usuario> resultados = jdbcTemplate.query(sql, usuarioRowMapper, email.trim());
        return resultados.stream().findFirst();
    }
}