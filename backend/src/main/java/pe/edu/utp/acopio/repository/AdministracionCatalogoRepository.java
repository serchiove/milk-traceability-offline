package pe.edu.utp.acopio.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import pe.edu.utp.acopio.DTO.catalogo.AdministracionCatalogo.*;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.service.RecursoNoEncontradoException;

@Repository
public class AdministracionCatalogoRepository {
    private final JdbcTemplate db;
    public AdministracionCatalogoRepository(JdbcTemplate db){this.db=db;}
    private static final RowMapper<Proveedor> PROVEEDOR=(r,n)->new Proveedor(r.getLong("id_proveedor"),r.getString("tipo_documento"),r.getString("numero_documento"),r.getString("razon_social"),r.getString("estado_cert"),r.getBoolean("activo"));
    private static final RowMapper<Vehiculo> VEHICULO=(r,n)->new Vehiculo(r.getLong("id_vehiculo"),r.getString("placa"),r.getBigDecimal("capacidad_litros"),r.getBoolean("activo"));
    public Pagina<Proveedor> proveedores(String buscar,int pagina,int tamano){
        String where=" FROM acopio.proveedor WHERE position(lower(?) in lower(razon_social || ' ' || numero_documento))>0";
        return new Pagina<>(db.query("SELECT *"+where+" ORDER BY id_proveedor LIMIT ? OFFSET ?",PROVEEDOR,buscar,tamano,(long)pagina*tamano),db.queryForObject("SELECT count(*)"+where,Long.class,buscar),pagina,tamano);
    }
    public Pagina<Vehiculo> vehiculos(String buscar,int pagina,int tamano){
        String where=" FROM acopio.vehiculo WHERE position(lower(?) in lower(placa))>0";
        return new Pagina<>(db.query("SELECT *"+where+" ORDER BY id_vehiculo LIMIT ? OFFSET ?",VEHICULO,buscar,tamano,(long)pagina*tamano),db.queryForObject("SELECT count(*)"+where,Long.class,buscar),pagina,tamano);
    }
    public Proveedor proveedor(long id){return db.query("SELECT * FROM acopio.proveedor WHERE id_proveedor=? FOR UPDATE",PROVEEDOR,id).stream().findFirst().orElseThrow(RecursoNoEncontradoException::new);}
    public Vehiculo vehiculo(long id){return db.query("SELECT * FROM acopio.vehiculo WHERE id_vehiculo=? FOR UPDATE",VEHICULO,id).stream().findFirst().orElseThrow(RecursoNoEncontradoException::new);}
    public Proveedor crear(ProveedorRequest r){return db.queryForObject("INSERT INTO acopio.proveedor(tipo_documento,numero_documento,razon_social,estado_cert) VALUES (?,?,?,?) RETURNING *",PROVEEDOR,r.tipoDocumento(),r.numeroDocumento(),r.razonSocial(),r.estadoCert());}
    public Vehiculo crear(VehiculoRequest r){return db.queryForObject("INSERT INTO acopio.vehiculo(placa,capacidad_litros) VALUES (?,?) RETURNING *",VEHICULO,r.placa(),r.capacidadLitros());}
    public Proveedor editar(long id,ProveedorRequest r){return db.queryForObject("UPDATE acopio.proveedor SET razon_social=?,estado_cert=? WHERE id_proveedor=? RETURNING *",PROVEEDOR,r.razonSocial(),r.estadoCert(),id);}
    public Vehiculo editar(long id,VehiculoRequest r){return db.queryForObject("UPDATE acopio.vehiculo SET capacidad_litros=? WHERE id_vehiculo=? RETURNING *",VEHICULO,r.capacidadLitros(),id);}
    public Proveedor estadoProveedor(long id,boolean activo){proveedor(id);return db.queryForObject("UPDATE acopio.proveedor SET activo=? WHERE id_proveedor=? RETURNING *",PROVEEDOR,activo,id);}
    public Vehiculo estadoVehiculo(long id,boolean activo){vehiculo(id);return db.queryForObject("UPDATE acopio.vehiculo SET activo=? WHERE id_vehiculo=? RETURNING *",VEHICULO,activo,id);}
}
