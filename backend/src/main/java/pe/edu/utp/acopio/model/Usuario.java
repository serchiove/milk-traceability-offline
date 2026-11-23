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
<<<<<<< HEAD
) {}
=======
) {}
>>>>>>> bbbf73f (feat: implementar seguridad JWT, login con Postgres y recepcion de lotes)
