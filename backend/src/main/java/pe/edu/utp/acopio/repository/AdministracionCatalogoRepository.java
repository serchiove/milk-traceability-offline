package pe.edu.utp.acopio.repository;

import jakarta.persistence.*;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.DTO.catalogo.AdministracionCatalogo.*;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.service.RecursoNoEncontradoException;

@Repository
public class AdministracionCatalogoRepository {
  @jakarta.persistence.PersistenceContext private EntityManager em;

  private Proveedor dto(pe.edu.utp.acopio.model.Proveedor p) {
    return new Proveedor(
        p.getId(),
        p.getTipoDocumento(),
        p.getNumeroDocumento(),
        p.getRazonSocial(),
        p.getEstadoCert(),
        p.getActivo());
  }

  private Vehiculo dto(pe.edu.utp.acopio.model.Vehiculo v) {
    return new Vehiculo(v.getId(), v.getPlaca(), v.getCapacidadLitros(), v.getActivo());
  }

  private <T> T locked(Class<T> type, long id) {
    T row = em.find(type, id, LockModeType.PESSIMISTIC_WRITE);
    if (row == null) throw new RecursoNoEncontradoException();
    return row;
  }

  public Pagina<Proveedor> proveedores(String buscar, int pagina, int tamano) {
    String where =
        " from Proveedor p where locate(lower(:buscar),lower(concat(p.razonSocial,'"
            + " ',p.numeroDocumento)))>0";
    var rows =
        em
            .createQuery(
                "select p" + where + " order by p.id", pe.edu.utp.acopio.model.Proveedor.class)
            .setParameter("buscar", buscar)
            .setFirstResult(pagina * tamano)
            .setMaxResults(tamano)
            .getResultList()
            .stream()
            .map(this::dto)
            .toList();
    long total =
        em.createQuery("select count(p)" + where, Long.class)
            .setParameter("buscar", buscar)
            .getSingleResult();
    return new Pagina<>(rows, total, pagina, tamano);
  }

  public Pagina<Vehiculo> vehiculos(String buscar, int pagina, int tamano) {
    String where = " from Vehiculo v where locate(lower(:buscar),lower(v.placa))>0";
    var rows =
        em
            .createQuery(
                "select v" + where + " order by v.id", pe.edu.utp.acopio.model.Vehiculo.class)
            .setParameter("buscar", buscar)
            .setFirstResult(pagina * tamano)
            .setMaxResults(tamano)
            .getResultList()
            .stream()
            .map(this::dto)
            .toList();
    long total =
        em.createQuery("select count(v)" + where, Long.class)
            .setParameter("buscar", buscar)
            .getSingleResult();
    return new Pagina<>(rows, total, pagina, tamano);
  }

  public Proveedor proveedor(long id) {
    return dto(locked(pe.edu.utp.acopio.model.Proveedor.class, id));
  }

  public Vehiculo vehiculo(long id) {
    return dto(locked(pe.edu.utp.acopio.model.Vehiculo.class, id));
  }

  public Proveedor crear(ProveedorRequest r) {
    var p = new pe.edu.utp.acopio.model.Proveedor();
    p.setTipoDocumento(r.tipoDocumento());
    p.setNumeroDocumento(r.numeroDocumento());
    p.setRazonSocial(r.razonSocial());
    p.setEstadoCert(r.estadoCert());
    p.setActivo(true);
    em.persist(p);
    em.flush();
    return dto(p);
  }

  public Vehiculo crear(VehiculoRequest r) {
    var v = new pe.edu.utp.acopio.model.Vehiculo();
    v.setPlaca(r.placa());
    v.setCapacidadLitros(r.capacidadLitros());
    v.setActivo(true);
    em.persist(v);
    em.flush();
    return dto(v);
  }

  public Proveedor editar(long id, ProveedorRequest r) {
    var p = locked(pe.edu.utp.acopio.model.Proveedor.class, id);
    p.setRazonSocial(r.razonSocial());
    p.setEstadoCert(r.estadoCert());
    em.flush();
    return dto(p);
  }

  public Vehiculo editar(long id, VehiculoRequest r) {
    var v = locked(pe.edu.utp.acopio.model.Vehiculo.class, id);
    v.setCapacidadLitros(r.capacidadLitros());
    em.flush();
    return dto(v);
  }

  public Proveedor estadoProveedor(long id, boolean activo) {
    var p = locked(pe.edu.utp.acopio.model.Proveedor.class, id);
    p.setActivo(activo);
    em.flush();
    return dto(p);
  }

  public Vehiculo estadoVehiculo(long id, boolean activo) {
    var v = locked(pe.edu.utp.acopio.model.Vehiculo.class, id);
    v.setActivo(activo);
    em.flush();
    return dto(v);
  }
}
