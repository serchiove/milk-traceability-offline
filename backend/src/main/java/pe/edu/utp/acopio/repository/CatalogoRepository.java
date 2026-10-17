package pe.edu.utp.acopio.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.DTO.catalogo.*;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import java.util.Optional;

@Repository
public class CatalogoRepository {
    private final JdbcTemplate db;
    public CatalogoRepository(JdbcTemplate db) {this.db = db;}

    public Pagina<ProveedorDto> proveedores(String buscar, int pagina, int tamano) {
        String filtro = " FROM acopio.proveedor WHERE activo AND position(lower(?) in lower(razon_social || ' ' || numero_documento)) > 0";
        long total = db.queryForObject("SELECT count(*)" + filtro, Long.class, buscar);
        var elementos = db.query("SELECT id_proveedor,tipo_documento,numero_documento,razon_social,estado_cert" + filtro +
            " ORDER BY razon_social,id_proveedor LIMIT ? OFFSET ?", (rs, n) -> new ProveedorDto(
                rs.getLong("id_proveedor"),rs.getString("tipo_documento"),rs.getString("numero_documento"),
                rs.getString("razon_social"),rs.getString("estado_cert")), buscar,tamano,(long)pagina*tamano);
        return new Pagina<>(elementos,total,pagina,tamano);
    }
    public Pagina<VehiculoDto> vehiculos(String buscar, int pagina, int tamano) {
        String filtro = " FROM acopio.vehiculo WHERE activo AND position(lower(?) in lower(placa)) > 0";
        long total = db.queryForObject("SELECT count(*)" + filtro,Long.class,buscar);
        var elementos = db.query("SELECT id_vehiculo,placa,capacidad_litros" + filtro +
            " ORDER BY placa,id_vehiculo LIMIT ? OFFSET ?",(rs,n) -> new VehiculoDto(
                rs.getLong("id_vehiculo"),rs.getString("placa"),rs.getBigDecimal("capacidad_litros")),buscar,tamano,(long)pagina*tamano);
        return new Pagina<>(elementos,total,pagina,tamano);
    }
    public Optional<CentroDto> centro(Long idCentro) {
        return db.query("SELECT id_centro,nombre,region,capacidad_litros FROM acopio.centro_acopio WHERE id_centro=? AND activo",
            (rs,n) -> new CentroDto(rs.getLong("id_centro"),rs.getString("nombre"),rs.getString("region"),
                rs.getBigDecimal("capacidad_litros")),idCentro).stream().findFirst();
    }
}
