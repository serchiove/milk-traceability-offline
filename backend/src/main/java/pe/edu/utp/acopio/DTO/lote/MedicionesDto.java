package pe.edu.utp.acopio.DTO.lote;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record MedicionesDto(
    @NotNull(message = "La temperatura es obligatoria")
    BigDecimal temperaturaC,

    @NotNull(message = "La acidez es obligatoria")
    @DecimalMin(value = "0.0", message = "La acidez no puede ser negativa")
    BigDecimal acidezDornic,

    @NotNull(message = "La densidad es obligatoria")
    @DecimalMin(value = "0.0001", message = "La densidad debe ser mayor a 0")
    BigDecimal densidadGml
) {}