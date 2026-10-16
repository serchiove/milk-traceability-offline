package pe.edu.utp.acopio.model;

public record Usuario(
    Long idUsuario,
    Long idCentro,
    String nombre,
    String dni,
    String email,
    String passwordHash,
    String rol,
    boolean activo
) {}
