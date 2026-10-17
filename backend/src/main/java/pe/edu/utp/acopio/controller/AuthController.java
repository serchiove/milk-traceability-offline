package pe.edu.utp.acopio.controller;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import pe.edu.utp.acopio.DTO.auth.LoginRequest;
import pe.edu.utp.acopio.DTO.auth.LoginResponse;
import pe.edu.utp.acopio.service.AuthService;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        Optional<LoginResponse> response = authService.autenticar(loginRequest);

        if (response.isPresent()) {
            return ResponseEntity.ok(response.get());
        } else {
            return ResponseEntity.status(401).body(Map.of("mensaje", "Credenciales incorrectas o usuario inactivo"));
        }
    }
}