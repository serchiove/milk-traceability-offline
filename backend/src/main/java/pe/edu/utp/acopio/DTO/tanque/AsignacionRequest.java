package pe.edu.utp.acopio.DTO.tanque;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
public record AsignacionRequest(@NotNull @Positive Long idTanque) {}
