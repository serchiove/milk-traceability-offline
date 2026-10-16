package pe.edu.utp.acopio.DTO.auth;

public record LoginResponse(
    String accessToken,
    UsuarioDto usuario
) {}