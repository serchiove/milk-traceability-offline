package pe.edu.utp.acopio.repository;

import jakarta.persistence.EntityManager;
import java.util.Optional;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.DTO.catalogo.*;
import pe.edu.utp.acopio.DTO.consulta.Pagina;

@Repository
public class CatalogoRepository {
  @jakarta.persistence.PersistenceContext private EntityManager em;

  public Pagina<ProveedorDto> proveedores(String buscar, int pagina, int tamano) {
    String where =
        " from Proveedor p where p.activo=true and"
            + " locate(lower(:buscar),lower(concat(p.razonSocial,' ',p.numeroDocumento)))>0";
    var rows =
        em.createQuery(
                "select new"
                    + " pe.edu.utp.acopio.DTO.catalogo.ProveedorDto(p.id,p.tipoDocumento,p.numeroDocumento,p.razonSocial,p.estadoCert)"
                    + where
                    + " order by p.razonSocial,p.id",
                ProveedorDto.class)
            .setParameter("buscar", buscar)
            .setFirstResult(pagina * tamano)
            .setMaxResults(tamano)
            .getResultList();
    long total =
        em.createQuery("select count(p)" + where, Long.class)
            .setParameter("buscar", buscar)
            .getSingleResult();
    return new Pagina<>(rows, total, pagina, tamano);
  }

  public Pagina<VehiculoDto> vehiculos(String buscar, int pagina, int tamano) {
    String where =
        " from Vehiculo v where v.activo=true and locate(lower(:buscar),lower(v.placa))>0";
    var rows =
        em.createQuery(
                "select new"
                    + " pe.edu.utp.acopio.DTO.catalogo.VehiculoDto(v.id,v.placa,v.capacidadLitros)"
                    + where
                    + " order by v.placa,v.id",
                VehiculoDto.class)
            .setParameter("buscar", buscar)
            .setFirstResult(pagina * tamano)
            .setMaxResults(tamano)
            .getResultList();
    long total =
        em.createQuery("select count(v)" + where, Long.class)
            .setParameter("buscar", buscar)
            .getSingleResult();
    return new Pagina<>(rows, total, pagina, tamano);
  }

  public Optional<CentroDto> centro(Long id) {
    return em.createQuery(
            "select new"
                + " pe.edu.utp.acopio.DTO.catalogo.CentroDto(c.id,c.nombre,c.region,c.capacidadLitros)"
                + " from CentroAcopio c where c.id=:id and c.activo=true",
            CentroDto.class)
        .setParameter("id", id)
        .getResultStream()
        .findFirst();
  }
}
