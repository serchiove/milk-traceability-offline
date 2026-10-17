package pe.edu.utp.acopio.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import pe.edu.utp.acopio.DTO.catalogo.*;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.security.OperarioPrincipal;
import pe.edu.utp.acopio.service.CatalogoService;

@RestController
@RequestMapping("/api/catalogos")
public class CatalogoController {
    private final CatalogoService catalogos;
    public CatalogoController(CatalogoService catalogos) {this.catalogos = catalogos;}
    @GetMapping("/proveedores")
    public Pagina<ProveedorDto> proveedores(@RequestParam(defaultValue="") String buscar,
        @RequestParam(defaultValue="0") int pagina, @RequestParam(defaultValue="25") int tamano) {
        return catalogos.proveedores(buscar,pagina,tamano);
    }
    @GetMapping("/vehiculos")
    public Pagina<VehiculoDto> vehiculos(@RequestParam(defaultValue="") String buscar,
        @RequestParam(defaultValue="0") int pagina, @RequestParam(defaultValue="25") int tamano) {
        return catalogos.vehiculos(buscar,pagina,tamano);
    }
    @GetMapping("/centro")
    public CentroDto centro(@AuthenticationPrincipal OperarioPrincipal usuario) {
        return catalogos.centro(usuario.idCentro());
    }
}
