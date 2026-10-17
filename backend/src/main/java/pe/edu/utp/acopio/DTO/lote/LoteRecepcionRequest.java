package pe.edu.utp.acopio.DTO.lote;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record LoteRecepcionRequest(
    @NotNull(message = "El ID del lote es obligatorio")
    UUID idLote,

    @NotNull(message = "El ID del proveedor es obligatorio")
    @Positive
    Long idProveedor,

    @NotNull(message = "El ID del vehículo es obligatorio")
    @Positive
    Long idVehiculo,

    @NotNull(message = "El volumen es obligatorio")
    @DecimalMin(value = "0.01", message = "El volumen debe ser mayor a 0")
    @Digits(integer = 10, fraction = 2)
    BigDecimal volumenLitros,

    @NotNull(message = "La fecha y hora de captura es obligatoria")
    OffsetDateTime fechaHora,

    @Valid
    @NotNull(message = "Las mediciones de calidad son obligatorias")
    MedicionesDto mediciones,
    @jakarta.validation.constraints.Pattern(regexp="[0-9a-f]{64}") String huellaSolicitud
) {}
