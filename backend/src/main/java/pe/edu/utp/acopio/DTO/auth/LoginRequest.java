<<<<<<< HEAD
<<<<<<< HEAD
package pe.edu.utp.acopio.DTO.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
    @NotBlank(message = "El email no puede estar vacío")
    @Email(message = "Debe ser un formato de correo válido")
    String email,

    @NotBlank(message = "La contraseña no puede estar vacía")
    String password
=======
package pe.edu.utp.acopio.dto.auth;
=======
package pe.edu.utp.acopio.DTO.auth;
>>>>>>> bbbf73f (feat: implementar seguridad JWT, login con Postgres y recepcion de lotes)

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
    @NotBlank(message = "El email no puede estar vacío")
    @Email(message = "Debe ser un formato de correo válido")
    String email,

    @NotBlank(message = "La contraseña no puede estar vacía")
    String password
>>>>>>> ba7c9f4 (feat(mobile): initialize mobile app with Expo and SQLite integration)
) {}