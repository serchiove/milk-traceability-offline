package pe.edu.utp.acopio.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.utp.acopio.DTO.catalogo.*;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.repository.CatalogoRepository;

@Service
@Transactional(readOnly = true)
public class CatalogoService {
    private final CatalogoRepository catalogos;
    public CatalogoService(CatalogoRepository catalogos) {this.catalogos = catalogos;}
    public Pagina<ProveedorDto> proveedores(String buscar, int pagina, int tamano) {
        buscar = buscar.trim(); Pagina.validar(pagina,tamano,buscar);
        return catalogos.proveedores(buscar,pagina,tamano);
    }
    public Pagina<VehiculoDto> vehiculos(String buscar, int pagina, int tamano) {
        buscar = buscar.trim(); Pagina.validar(pagina,tamano,buscar);
        return catalogos.vehiculos(buscar,pagina,tamano);
    }
    public CentroDto centro(Long idCentro) {
        return catalogos.centro(idCentro).orElseThrow(RecursoNoEncontradoException::new);
    }
}
