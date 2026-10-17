package pe.edu.utp.acopio.DTO.lote;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Digits;
import java.math.BigDecimal;

public record MedicionesDto(
    @NotNull(message = "La temperatura es obligatoria")
    @DecimalMin("-273.15")
    @Digits(integer = 4, fraction = 2)
    BigDecimal temperaturaC,

    @NotNull(message = "La acidez es obligatoria")
    @DecimalMin(value = "0.0", message = "La acidez no puede ser negativa")
    @Digits(integer = 4, fraction = 2)
    BigDecimal acidezDornic,

    @NotNull(message = "La densidad es obligatoria")
    @DecimalMin(value = "0.0001", message = "La densidad debe ser mayor a 0")
    @Digits(integer = 3, fraction = 4)
    BigDecimal densidadGml
) {}