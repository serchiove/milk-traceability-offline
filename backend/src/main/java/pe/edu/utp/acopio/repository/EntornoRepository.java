package pe.edu.utp.acopio.repository;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
@Repository
public class EntornoRepository {
 private final JdbcTemplate jdbc;
 public EntornoRepository(JdbcTemplate jdbc) { this.jdbc=jdbc; }
 public Integer tablas() { return jdbc.queryForObject("SELECT count(*) FROM information_schema.tables WHERE table_schema='acopio' AND table_type='BASE TABLE'", Integer.class); }
 public List<Map<String,Object>> centros() { return jdbc.queryForList("SELECT id_centro, nombre, region, capacidad_litros FROM acopio.centro_acopio WHERE activo ORDER BY id_centro"); }
}
