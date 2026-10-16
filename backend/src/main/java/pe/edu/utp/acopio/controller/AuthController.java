<<<<<<< HEAD
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
=======
package pe.edu.utp.acopio.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import pe.edu.utp.acopio.dto.auth.LoginRequest;
import pe.edu.utp.acopio.dto.auth.LoginResponse;
import pe.edu.utp.acopio.security.JwtTokenProvider;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final JwtTokenProvider tokenProvider;
    private final PasswordEncoder passwordEncoder;

    public AuthController(JwtTokenProvider tokenProvider, PasswordEncoder passwordEncoder) {
        this.tokenProvider = tokenProvider;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        
        // TODO: En el siguiente paso, moveremos esta lógica al AuthService para validar 
        // contra la tabla 'usuario' de PostgreSQL usando el EntornoRepository/UsuarioRepository.
        
        // --- SIMULACIÓN TEMPORAL (Solo para probar el flujo JWT hoy) ---
        String emailCargadoEnBD = "operario@gloria.com.pe";
        // "123456" encriptado con BCrypt
        String hashEnBD = "$2a$10$W2neF9.6Agi6kAKVq8q3fec5dHW8KUA.b0VSIGdIZyUawGceP6yGq"; 

        if (loginRequest.email().equals(emailCargadoEnBD) && 
            passwordEncoder.matches(loginRequest.password(), hashEnBD)) {
            
            // Si la clave coincide, generamos el Token
            Long idUsuarioFicticio = 1L;
            Long idCentroFicticio = 1L; // Planta Arequipa
            String rolFicticio = "OPERARIO";
            
            String jwt = tokenProvider.generarToken(loginRequest.email(), idUsuarioFicticio, idCentroFicticio, rolFicticio);
            
            LoginResponse response = new LoginResponse(jwt, idUsuarioFicticio, idCentroFicticio, rolFicticio, "Juan Pérez");
            return ResponseEntity.ok(response);
            
        } else {
            return ResponseEntity.status(401).body("Credenciales incorrectas");
        }
    }
>>>>>>> ba7c9f4 (feat(mobile): initialize mobile app with Expo and SQLite integration)
}