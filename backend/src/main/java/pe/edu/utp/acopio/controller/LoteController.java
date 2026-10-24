package pe.edu.utp.acopio.controller;

import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import pe.edu.utp.acopio.service.ConsultaLoteService;
import pe.edu.utp.acopio.DTO.consulta.*;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import pe.edu.utp.acopio.DTO.lote.LoteRecepcionRequest;
import pe.edu.utp.acopio.security.OperarioPrincipal;
import pe.edu.utp.acopio.service.LoteService;

@RestController
@RequestMapping("/api/lotes")
/** Expone recepción y consultas de lotes bajo /api/lotes. Obtiene usuario y centro de la identidad autenticada, no del cuerpo recibido. */
public class LoteController {
    private final LoteService lotes;
    private final ConsultaLoteService consultas;
    public LoteController(LoteService lotes, ConsultaLoteService consultas) {
        this.lotes = lotes; this.consultas = consultas;
    }
    @GetMapping
    public Pagina<LoteDetalleDto> listar(@AuthenticationPrincipal OperarioPrincipal usuario,
        @RequestParam(required=false) String estado,
        @RequestParam(required=false) @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate desde,
        @RequestParam(required=false) @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate hasta,
        @RequestParam(defaultValue="") String buscar,
        @RequestParam(defaultValue="0") int pagina, @RequestParam(defaultValue="25") int tamano) {
        return consultas.listar(usuario.idCentro(),estado,desde,hasta,buscar,pagina,tamano);
    }
    @GetMapping("/por-qr")
    public LoteDetalleDto porQr(@AuthenticationPrincipal OperarioPrincipal usuario, @RequestParam String codigo) {
        return consultas.porQr(usuario.idCentro(),codigo);
    }
    @GetMapping("/{id}")
    public LoteDetalleDto detalle(@AuthenticationPrincipal OperarioPrincipal usuario, @PathVariable UUID id) {
        return consultas.detalle(usuario.idCentro(),id);
    }

    @PostMapping
    public ResponseEntity<?> recibirLote(@Valid @RequestBody LoteRecepcionRequest request,
                                        @AuthenticationPrincipal OperarioPrincipal usuario) {
        var resultado = lotes.registrarLote(request, usuario.idUsuario(), usuario.idCentro());
        return ResponseEntity.status(resultado.idempotente() ? HttpStatus.OK : HttpStatus.CREATED).body(resultado);
    }
}
