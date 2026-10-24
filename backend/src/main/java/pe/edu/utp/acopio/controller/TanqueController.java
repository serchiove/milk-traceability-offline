package pe.edu.utp.acopio.controller;

import java.util.UUID;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.DTO.tanque.*;
import pe.edu.utp.acopio.security.OperarioPrincipal;
import pe.edu.utp.acopio.service.TanqueService;

@RestController
@RequestMapping("/api")
/** Expone la consulta de tanques y la asignación de destino. Devuelve 201 al asignar y 200 cuando se confirma el mismo destino por reintento. */
public class TanqueController {
    private final TanqueService tanques;
    public TanqueController(TanqueService tanques) {this.tanques=tanques;}
    @GetMapping("/tanques")
    public Pagina<TanqueDto> listar(@AuthenticationPrincipal OperarioPrincipal usuario,
        @RequestParam(defaultValue="false") boolean disponibles,
        @RequestParam(defaultValue="0") int pagina,@RequestParam(defaultValue="25") int tamano) {
        return tanques.listar(usuario.idCentro(),disponibles,pagina,tamano);
    }
    @PostMapping("/lotes/{id}/asignacion-tanque")
    public ResponseEntity<AsignacionDto> asignar(@AuthenticationPrincipal OperarioPrincipal usuario,
        @PathVariable UUID id,@Valid @RequestBody AsignacionRequest request) {
        var resultado=tanques.asignar(usuario.idCentro(),usuario.idUsuario(),id,request.idTanque());
        return ResponseEntity.status(resultado.idempotente()?200:201).body(resultado);
    }
}
