package pe.edu.utp.acopio.repository;

import jakarta.persistence.EntityManager;
import java.util.*;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.utp.acopio.model.CentroAcopio;

@Repository
@Transactional(readOnly = true)
public class EntornoRepository {
  @jakarta.persistence.PersistenceContext private EntityManager em;

  public Integer tablas() {
    return ((Number)
            em.createNativeQuery(
                    "SELECT count(*) FROM information_schema.tables WHERE table_schema='acopio' AND"
                        + " table_type='BASE TABLE'",
                    Long.class)
                .getSingleResult())
        .intValue();
  }

  public List<Map<String, Object>> centros() {
    return em
        .createQuery(
            "select c from CentroAcopio c where c.activo=true order by c.id", CentroAcopio.class)
        .getResultList()
        .stream()
        .map(
            c ->
                Map.<String, Object>of(
                    "id_centro",
                    c.getId(),
                    "nombre",
                    c.getNombre(),
                    "region",
                    c.getRegion(),
                    "capacidad_litros",
                    c.getCapacidadLitros()))
        .toList();
  }
}
