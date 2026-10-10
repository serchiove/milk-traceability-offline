package pe.edu.utp.acopio;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import static org.assertj.core.api.Assertions.assertThat;
@SpringBootTest
class AcopioApplicationTests {
 @Autowired JdbcTemplate jdbc;
 @Test void aplicaModeloFisicoCompleto() {
  assertThat(jdbc.queryForObject("SELECT count(*) FROM information_schema.tables WHERE table_schema='acopio' AND table_type='BASE TABLE'",Integer.class)).isEqualTo(9);
  assertThat(jdbc.queryForObject("SELECT count(*) FROM information_schema.columns WHERE table_schema='acopio' AND table_name IN (SELECT table_name FROM information_schema.tables WHERE table_schema='acopio' AND table_type='BASE TABLE')",Integer.class)).isEqualTo(59);
  assertThat(jdbc.queryForObject("SELECT count(*) FROM public.flyway_schema_history WHERE success",Integer.class)).isEqualTo(2);
 }
}
