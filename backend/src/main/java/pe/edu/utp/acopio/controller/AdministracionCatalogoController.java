package pe.edu.utp.acopio.controller;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import pe.edu.utp.acopio.DTO.catalogo.AdministracionCatalogo.*;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.service.AdministracionCatalogoService;

@RestController
@RequestMapping("/api/administracion/catalogos")
public class AdministracionCatalogoController {
    private final AdministracionCatalogoService service;
    public AdministracionCatalogoController(AdministracionCatalogoService service){this.service=service;}
    @GetMapping("/proveedores") public Pagina<Proveedor> proveedores(@RequestParam(defaultValue="") String buscar,@RequestParam(defaultValue="0") int pagina,@RequestParam(defaultValue="25") int tamano){return service.proveedores(buscar,pagina,tamano);}
    @GetMapping("/vehiculos") public Pagina<Vehiculo> vehiculos(@RequestParam(defaultValue="") String buscar,@RequestParam(defaultValue="0") int pagina,@RequestParam(defaultValue="25") int tamano){return service.vehiculos(buscar,pagina,tamano);}
    @PostMapping("/proveedores") public ResponseEntity<Proveedor> crearProveedor(@Valid @RequestBody ProveedorRequest r){return ResponseEntity.status(201).body(service.crear(r));}
    @PostMapping("/vehiculos") public ResponseEntity<Vehiculo> crearVehiculo(@Valid @RequestBody VehiculoRequest r){return ResponseEntity.status(201).body(service.crear(r));}
    @PutMapping("/proveedores/{id}") public Proveedor editarProveedor(@PathVariable long id,@Valid @RequestBody ProveedorRequest r){return service.editar(id,r);}
    @PutMapping("/vehiculos/{id}") public Vehiculo editarVehiculo(@PathVariable long id,@Valid @RequestBody VehiculoRequest r){return service.editar(id,r);}
    @PatchMapping("/proveedores/{id}/estado") public Proveedor estadoProveedor(@PathVariable long id,@Valid @RequestBody EstadoRequest r){return service.estadoProveedor(id,r.activo());}
    @PatchMapping("/vehiculos/{id}/estado") public Vehiculo estadoVehiculo(@PathVariable long id,@Valid @RequestBody EstadoRequest r){return service.estadoVehiculo(id,r.activo());}
}
