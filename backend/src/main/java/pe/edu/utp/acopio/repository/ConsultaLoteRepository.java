package pe.edu.utp.acopio.repository;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.*;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.DTO.consulta.*;

@Repository
/** Proyecta lotes y mediciones a DTO sin serializar relaciones JPA. Todas las consultas se restringen al centro indicado por el servicio. */
public class ConsultaLoteRepository {
  @jakarta.persistence.PersistenceContext private EntityManager em;

  private static final String FROM =
      " from LoteLeche l join l.proveedor p join l.vehiculo v join l.usuario u join l.centro c left"
          + " join RegistroCalidad r on r.lote=l left join l.tanque t";
  private static final String SELECT =
      "select new"
          + " pe.edu.utp.acopio.DTO.consulta.LoteDetalleDto(l.id,c.id,c.nombre,p.id,p.razonSocial,v.id,v.placa,u.id,u.nombre,l.fechaHora,l.recibidoEn,l.volumenLitros,r.temperaturaC,r.acidezDornic,r.densidadGml,coalesce(r.estadoEvaluacion,'PENDIENTE'),r.versionReglas,r.motivo,r.fechaEvaluacion,l.codigoQr,t.id,t.codigo,l.asignadoEn)";

  public Optional<LoteDetalleDto> detalle(Long centro, UUID id) {
    return em.createQuery(SELECT + FROM + " where c.id=:centro and l.id=:id", LoteDetalleDto.class)
        .setParameter("centro", centro)
        .setParameter("id", id)
        .getResultStream()
        .findFirst();
  }

  public Pagina<LoteDetalleDto> listar(
      Long centro,
      String estado,
      OffsetDateTime desde,
      OffsetDateTime hasta,
      String buscar,
      int pagina,
      int tamano) {
    StringBuilder where = new StringBuilder(" where c.id=:centro");
    Map<String, Object> params = new HashMap<>();
    params.put("centro", centro);
    if (estado != null) {
      where.append(" and coalesce(r.estadoEvaluacion,'PENDIENTE')=:estado");
      params.put("estado", estado);
    }
    if (desde != null) {
      where.append(" and l.fechaHora>=:desde");
      params.put("desde", desde);
    }
    if (hasta != null) {
      where.append(" and l.fechaHora<:hasta");
      params.put("hasta", hasta);
    }
    if (!buscar.isEmpty()) {
      where.append(
          " and locate(lower(:buscar),lower(concat(p.razonSocial,' ',v.placa,' ',cast(l.id as"
              + " string))))>0");
      params.put("buscar", buscar);
    }
    var count = em.createQuery("select count(l)" + FROM + where, Long.class);
    params.forEach(count::setParameter);
    var query =
        em.createQuery(
            SELECT + FROM + where + " order by l.fechaHora desc,l.id desc", LoteDetalleDto.class);
    params.forEach(query::setParameter);
    return new Pagina<>(
        query.setFirstResult(pagina * tamano).setMaxResults(tamano).getResultList(),
        count.getSingleResult(),
        pagina,
        tamano);
  }
}
