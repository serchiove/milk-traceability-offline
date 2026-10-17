package pe.edu.utp.acopio.service;

import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.utp.acopio.DTO.catalogo.AdministracionCatalogo.*;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.repository.AdministracionCatalogoRepository;

@Service
@Transactional
public class AdministracionCatalogoService {
    private final AdministracionCatalogoRepository repo;
    public AdministracionCatalogoService(AdministracionCatalogoRepository repo){this.repo=repo;}
    public static class Conflicto extends RuntimeException {public Conflicto(String mensaje){super(mensaje);}}
    @Transactional(readOnly=true) public Pagina<Proveedor> proveedores(String buscar,int pagina,int tamano){buscar=buscar.trim();Pagina.validar(pagina,tamano,buscar);return repo.proveedores(buscar,pagina,tamano);}
    @Transactional(readOnly=true) public Pagina<Vehiculo> vehiculos(String buscar,int pagina,int tamano){buscar=buscar.trim();Pagina.validar(pagina,tamano,buscar);return repo.vehiculos(buscar,pagina,tamano);}
    private ProveedorRequest normalizar(ProveedorRequest r){
        if(r.numeroDocumento().length()!=(r.tipoDocumento().equals("DNI")?8:11))throw new IllegalArgumentException("Longitud de documento incorrecta");
        return new ProveedorRequest(r.tipoDocumento(),r.numeroDocumento(),r.razonSocial().strip(),r.estadoCert());
    }
    private VehiculoRequest normalizar(VehiculoRequest r){
        String placa=r.placa().strip().toUpperCase(Locale.ROOT);
        if(!placa.matches("[A-Z0-9][A-Z0-9 -]{0,11}"))throw new IllegalArgumentException("Placa invalida");
        return new VehiculoRequest(placa,r.capacidadLitros());
    }
    public Proveedor crear(ProveedorRequest r){return repo.crear(normalizar(r));}
    public Vehiculo crear(VehiculoRequest r){return repo.crear(normalizar(r));}
    public Proveedor editar(long id,ProveedorRequest r){
        r=normalizar(r);var actual=repo.proveedor(id);
        if(!actual.tipoDocumento().equals(r.tipoDocumento())||!actual.numeroDocumento().equals(r.numeroDocumento()))throw new Conflicto("El documento identifica al proveedor y no puede cambiarse. Desactiva y crea otro proveedor.");
        return repo.editar(id,r);
    }
    public Vehiculo editar(long id,VehiculoRequest r){
        r=normalizar(r);var actual=repo.vehiculo(id);
        if(!actual.placa().equals(r.placa()))throw new Conflicto("La placa identifica al vehiculo y no puede cambiarse. Desactiva y crea otro vehiculo.");
        return repo.editar(id,r);
    }
    public Proveedor estadoProveedor(long id,boolean activo){return repo.estadoProveedor(id,activo);}
    public Vehiculo estadoVehiculo(long id,boolean activo){return repo.estadoVehiculo(id,activo);}
}
