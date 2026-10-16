package pe.edu.utp.acopio.DTO.auth;

public record UsuarioDto(
    Long idUsuario,
    Long idCentro,
    String rol,
    String nombre
) {}
