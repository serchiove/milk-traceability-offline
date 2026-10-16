package pe.edu.utp.acopio.DTO.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
    @NotBlank(message = "El email no puede estar vacío")
    @Email(message = "Debe ser un formato de correo válido")
    String email,

    @NotBlank(message = "La contraseña no puede estar vacía")
    String password
) {}