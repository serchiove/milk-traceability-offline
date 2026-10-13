package pe.edu.utp.acopio.dto.lote;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record LoteRecepcionRequest(
    @NotNull(message = "El ID del lote es obligatorio")
    UUID idLote,

    @NotNull(message = "El ID del proveedor es obligatorio")
    Long idProveedor,

    @NotNull(message = "El ID del vehículo es obligatorio")
    Long idVehiculo,

    @NotNull(message = "El volumen es obligatorio")
    @DecimalMin(value = "0.1", message = "El volumen debe ser mayor a 0")
    BigDecimal volumenLitros,

    @NotNull(message = "La fecha y hora de captura es obligatoria")
    OffsetDateTime fechaHora,

    @NotBlank(message = "La huella de solicitud (SHA256) es obligatoria")
    String huellaSolicitud,

    @Valid
    @NotNull(message = "Las mediciones de calidad son obligatorias")
    MedicionesDto mediciones
) {}