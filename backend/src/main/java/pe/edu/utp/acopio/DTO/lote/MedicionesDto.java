<<<<<<< HEAD
<<<<<<< HEAD
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
=======
package pe.edu.utp.acopio.dto.lote;
=======
package pe.edu.utp.acopio.DTO.lote;
>>>>>>> bbbf73f (feat: implementar seguridad JWT, login con Postgres y recepcion de lotes)

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
>>>>>>> ba7c9f4 (feat(mobile): initialize mobile app with Expo and SQLite integration)
) {}