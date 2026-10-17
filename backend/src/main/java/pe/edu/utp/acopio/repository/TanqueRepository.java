package pe.edu.utp.acopio.repository;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.DTO.tanque.*;
import pe.edu.utp.acopio.model.*;

@Repository
public class TanqueRepository {
  @jakarta.persistence.PersistenceContext private EntityManager em;

  public record LoteDestino(UUID id, BigDecimal volumen, String estado, Long tanque) {}

  private TanqueDto dto(Tanque t) {
    return new TanqueDto(
        t.getId(),
        t.getCodigo(),
        t.getEstado(),
        t.getCapacidadLitros(),
        t.getVolumenAsignadoLitros(),
        t.getCapacidadLitros().subtract(t.getVolumenAsignadoLitros()));
  }

  public Optional<LoteDestino> bloquearLote(Long centro, UUID id) {
    return em.createQuery(
            "select l from LoteLeche l where l.centro.id=:centro and l.id=:id", LoteLeche.class)
        .setParameter("centro", centro)
        .setParameter("id", id)
        .setLockMode(LockModeType.PESSIMISTIC_WRITE)
        .getResultStream()
        .findFirst()
        .flatMap(
            l ->
                em.createQuery(
                        "select r.estadoEvaluacion from RegistroCalidad r where r.lote.id=:id",
                        String.class)
                    .setParameter("id", id)
                    .getResultStream()
                    .findFirst()
                    .map(
                        estado ->
                            new LoteDestino(
                                l.getId(),
                                l.getVolumenLitros(),
                                estado,
                                l.getTanque() == null ? null : l.getTanque().getId())));
  }

  public Optional<TanqueDto> bloquearTanque(Long centro, Long id) {
    return em.createQuery(
            "select t from Tanque t where t.centro.id=:centro and t.id=:id", Tanque.class)
        .setParameter("centro", centro)
        .setParameter("id", id)
        .setLockMode(LockModeType.PESSIMISTIC_WRITE)
        .getResultStream()
        .findFirst()
        .map(this::dto);
  }

  public Pagina<TanqueDto> listar(Long centro, boolean disponibles, int pagina, int tamano) {
    String where =
        " from Tanque t where t.centro.id=:centro"
            + (disponibles
                ? " and t.estado='DISPONIBLE' and t.volumenAsignadoLitros<t.capacidadLitros"
                : "");
    long total =
        em.createQuery("select count(t)" + where, Long.class)
            .setParameter("centro", centro)
            .getSingleResult();
    var rows =
        em
            .createQuery("select t" + where + " order by t.codigo,t.id", Tanque.class)
            .setParameter("centro", centro)
            .setFirstResult(pagina * tamano)
            .setMaxResults(tamano)
            .getResultList()
            .stream()
            .map(this::dto)
            .toList();
    return new Pagina<>(rows, total, pagina, tamano);
  }

  public void asignar(UUID id, Long tanque, Long usuario) {
    var lote = em.find(LoteLeche.class, id);
    if (lote == null || lote.getTanque() != null)
      throw new IllegalStateException("No se pudo confirmar la asignacion");
    lote.setTanque(em.getReference(Tanque.class, tanque));
    lote.setUsuarioAsigna(em.getReference(Usuario.class, usuario));
    lote.setAsignadoEn(OffsetDateTime.now(java.time.ZoneOffset.UTC));
    em.flush(); // Existing trigger reserves tank volume; never increment it in Java.
    em.clear();
  }

  public AsignacionDto resultado(Long centro, UUID id, boolean idempotente) {
    var l =
        em.createQuery(
                "select l from LoteLeche l join fetch l.tanque where l.centro.id=:centro and"
                    + " l.id=:id",
                LoteLeche.class)
            .setParameter("centro", centro)
            .setParameter("id", id)
            .getSingleResult();
    return new AsignacionDto(
        l.getId(),
        l.getTanque().getId(),
        l.getTanque().getCodigo(),
        l.getVolumenLitros(),
        l.getAsignadoEn(),
        l.getUsuarioAsigna().getId(),
        idempotente);
  }
}
