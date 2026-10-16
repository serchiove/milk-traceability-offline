package pe.edu.utp.acopio.controller;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import pe.edu.utp.acopio.DTO.lote.LoteRecepcionRequest;
import pe.edu.utp.acopio.DTO.lote.LoteRecepcionResponse;
import pe.edu.utp.acopio.security.JwtTokenProvider;
import pe.edu.utp.acopio.service.LoteService;

import java.util.Map;

@RestController
@RequestMapping("/api/lotes")
public class LoteController {

    private final LoteService loteService;
    private final JwtTokenProvider tokenProvider;

    public LoteController(LoteService loteService, JwtTokenProvider tokenProvider) {
        this.loteService = loteService;
        this.tokenProvider = tokenProvider;
    }

    @PostMapping
    public ResponseEntity<?> recibirLote(
            @Valid @RequestBody LoteRecepcionRequest request,
            HttpServletRequest httpRequest) {

        String bearer = httpRequest.getHeader("Authorization");
        String token = bearer.substring(7);

        Long idUsuario = tokenProvider.getIdUsuarioFromToken(token);
        Long idCentro = tokenProvider.getIdCentroFromToken(token);

        try {
            LoteRecepcionResponse response = loteService.registrarLote(request, idUsuario, idCentro);
            HttpStatus status = response.idempotente() ? HttpStatus.OK : HttpStatus.CREATED;
            return ResponseEntity.status(status).body(response);
        } catch (LoteService.ConflictoHuellaException ex) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("mensaje", ex.getMessage()));
        }
    }
}
