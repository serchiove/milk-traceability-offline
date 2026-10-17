package pe.edu.utp.acopio.repository;

import jakarta.persistence.EntityManager;
import java.time.OffsetDateTime;
import java.util.*;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.DTO.lote.LoteRecepcionRequest;
import pe.edu.utp.acopio.model.*;

@Repository
public class LoteRepository {
  @jakarta.persistence.PersistenceContext private EntityManager em;

  public record EstadoLoteBD(
      UUID idLote,
      String huellaSolicitud,
      String codigoQr,
      OffsetDateTime recibidoEn,
      String estadoEvaluacion,
      String versionReglas,
      String motivo,
      OffsetDateTime fechaEvaluacion) {}

  public boolean referenciasActivas(Long proveedor, Long vehiculo, Long usuario, Long centro) {
    long p =
        em.createQuery(
                "select count(p) from Proveedor p where p.id=:id and p.activo=true", Long.class)
            .setParameter("id", proveedor)
            .getSingleResult();
    long v =
        em.createQuery(
                "select count(v) from Vehiculo v where v.id=:id and v.activo=true", Long.class)
            .setParameter("id", vehiculo)
            .getSingleResult();
    long u =
        em.createQuery(
                "select count(u) from Usuario u where u.id=:id and u.centroEntidad.id=:centro and"
                    + " u.activo=true and u.centroEntidad.activo=true and"
                    + " u.rolEntidad.nombre='OPERARIO'",
                Long.class)
            .setParameter("id", usuario)
            .setParameter("centro", centro)
            .getSingleResult();
    return p == 1 && v == 1 && u == 1;
  }

  public boolean insertarLoteSiNoExiste(
      LoteRecepcionRequest r, Long usuario, Long centro, String huella) {
    // PostgreSQL resolves concurrent UUID retries without aborting the transaction.
    return em.createNativeQuery(
                "INSERT INTO"
                    + " acopio.lote_leche(id_lote,id_proveedor,id_vehiculo,id_usuario,id_centro,fecha_hora,volumen_litros,huella_solicitud)"
                    + " VALUES (:id,:proveedor,:vehiculo,:usuario,:centro,:fecha,:volumen,:huella)"
                    + " ON CONFLICT (id_lote) DO NOTHING")
            .setParameter("id", r.idLote())
            .setParameter("proveedor", r.idProveedor())
            .setParameter("vehiculo", r.idVehiculo())
            .setParameter("usuario", usuario)
            .setParameter("centro", centro)
            .setParameter("fecha", r.fechaHora())
            .setParameter("volumen", r.volumenLitros())
            .setParameter("huella", huella)
            .executeUpdate()
        == 1;
  }

  public void insertarRegistroCalidadPendiente(LoteRecepcionRequest r) {
    var calidad = new RegistroCalidad();
    calidad.setLote(em.getReference(LoteLeche.class, r.idLote()));
    calidad.setTemperaturaC(r.mediciones().temperaturaC());
    calidad.setAcidezDornic(r.mediciones().acidezDornic());
    calidad.setDensidadGml(r.mediciones().densidadGml());
    calidad.setEstadoEvaluacion("PENDIENTE");
    em.persist(calidad);
    em.flush();
  }

  public int actualizarEvaluacionCalidad(UUID id, String estado, String version, String motivo) {
    // Bulk JPQL plus clear prevents stale entities after the QR/incidence trigger.
    em.flush();
    int rows =
        em.createQuery(
                "update RegistroCalidad r set"
                    + " r.estadoEvaluacion=:estado,r.fechaEvaluacion=:fecha,r.versionReglas=:version,r.motivo=:motivo"
                    + " where r.lote.id=:id and r.estadoEvaluacion='PENDIENTE'")
            .setParameter("estado", estado)
            .setParameter("fecha", OffsetDateTime.now(java.time.ZoneOffset.UTC))
            .setParameter("version", version)
            .setParameter("motivo", motivo)
            .setParameter("id", id)
            .executeUpdate();
    em.clear();
    return rows;
  }

  public Optional<EstadoLoteBD> buscarEstadoLote(UUID id) {
    return em.createQuery(
            "select new"
                + " pe.edu.utp.acopio.repository.LoteRepository$EstadoLoteBD(l.id,l.huellaSolicitud,l.codigoQr,l.recibidoEn,r.estadoEvaluacion,r.versionReglas,r.motivo,r.fechaEvaluacion)"
                + " from RegistroCalidad r join r.lote l where l.id=:id",
            EstadoLoteBD.class)
        .setParameter("id", id)
        .getResultStream()
        .findFirst();
  }
}
