<<<<<<< HEAD
package pe.edu.utp.acopio.DTO.auth;

public record LoginResponse(
    String accessToken,
    UsuarioDto usuario
=======
package pe.edu.utp.acopio.dto.auth;

public record LoginResponse(
    String token,
    Long idUsuario,
    Long idCentro,
    String rol,
    String nombre
>>>>>>> ba7c9f4 (feat(mobile): initialize mobile app with Expo and SQLite integration)
) {}