package pe.edu.utp.acopio.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import pe.edu.utp.acopio.DTO.auth.LoginRequest;
import pe.edu.utp.acopio.DTO.auth.LoginResponse;
import pe.edu.utp.acopio.DTO.auth.UsuarioDto;
import pe.edu.utp.acopio.model.Usuario;
import pe.edu.utp.acopio.repository.UsuarioRepository;
import pe.edu.utp.acopio.security.JwtTokenProvider;

import java.util.Optional;

@Service
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;

    public AuthService(UsuarioRepository usuarioRepository,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider) {
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
    }

    public Optional<LoginResponse> autenticar(LoginRequest request) {
        Optional<Usuario> usuarioOpt = usuarioRepository.buscarPorEmail(request.email());

        if (usuarioOpt.isEmpty()) {
            return Optional.empty();
        }

        Usuario usuario = usuarioOpt.get();

        if (!usuario.activo()) {
            return Optional.empty();
        }

        // Verifica la contraseña contra el hash BCrypt almacenado en PostgreSQL
        if (!passwordEncoder.matches(request.password(), usuario.passwordHash())) {
            return Optional.empty();
        }

        String token = tokenProvider.generarToken(
            usuario.email(),
            usuario.idUsuario(),
            usuario.idCentro(),
            usuario.rol()
        );

        UsuarioDto usuarioDto = new UsuarioDto(
            usuario.idUsuario(),
            usuario.idCentro(),
            usuario.rol(),
            usuario.nombre(),
            usuario.centro()
        );

        return Optional.of(new LoginResponse(token, usuarioDto));
    }
}
