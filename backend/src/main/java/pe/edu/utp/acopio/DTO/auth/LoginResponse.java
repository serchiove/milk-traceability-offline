package pe.edu.utp.acopio.dto.auth;

public record LoginResponse(
    String token,
    Long idUsuario,
    Long idCentro,
    String rol,
    String nombre
) {}