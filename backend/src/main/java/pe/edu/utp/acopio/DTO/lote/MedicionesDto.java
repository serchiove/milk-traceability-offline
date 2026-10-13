package pe.edu.utp.acopio.dto.lote;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record MedicionesDto(
    @NotNull(message = "La temperatura es obligatoria")
    @DecimalMin(value = "-273.15", message = "Temperatura física inválida")
    BigDecimal temperaturaC,

    @NotNull(message = "La acidez es obligatoria")
    @DecimalMin(value = "0.0", message = "La acidez no puede ser negativa")
    BigDecimal acidezDornic,

    @NotNull(message = "La densidad es obligatoria")
    @DecimalMin(value = "0.1", message = "Densidad inválida")
    BigDecimal densidadGml
) {}