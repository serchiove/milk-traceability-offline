package pe.edu.utp.acopio;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest
class AcopioApplicationTests {
  @Autowired JdbcTemplate jdbc;
  @Autowired jakarta.persistence.EntityManagerFactory entities;
  @Autowired org.springframework.transaction.PlatformTransactionManager transactions;

  @Test
  void hibernateMapsAllNineEntitiesAndUsesJpaTransactions() {
    assertThat(entities.unwrap(org.hibernate.SessionFactory.class)).isNotNull();
    assertThat(transactions).isInstanceOf(org.springframework.orm.jpa.JpaTransactionManager.class);
    assertThat(entities.getMetamodel().getEntities())
        .extracting(jakarta.persistence.metamodel.EntityType::getName)
        .containsExactlyInAnyOrder(
            "Rol",
            "CentroAcopio",
            "Usuario",
            "Proveedor",
            "Vehiculo",
            "Tanque",
            "LoteLeche",
            "RegistroCalidad",
            "Incidencia");
    assertThat(entities.getProperties().get("hibernate.hbm2ddl.auto")).isEqualTo("validate");
  }

  @Test
  void aplicaModeloFisicoCompleto() {
    assertThat(
            jdbc.queryForObject(
                "SELECT count(*) FROM information_schema.tables WHERE table_schema='acopio' AND"
                    + " table_type='BASE TABLE'",
                Integer.class))
        .isEqualTo(9);
    assertThat(
            jdbc.queryForObject(
                "SELECT count(*) FROM information_schema.columns WHERE table_schema='acopio' AND"
                    + " table_name IN (SELECT table_name FROM information_schema.tables WHERE"
                    + " table_schema='acopio' AND table_type='BASE TABLE')",
                Integer.class))
        .isEqualTo(59);
    assertThat(
            jdbc.queryForObject(
                "SELECT count(*) FROM public.flyway_schema_history WHERE success", Integer.class))
        .isEqualTo(4);
  }
}
