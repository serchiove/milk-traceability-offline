package pe.edu.utp.acopio.calidad;

import org.springframework.stereotype.Component;
import pe.edu.utp.acopio.DTO.lote.MedicionesDto;
import java.math.BigDecimal;
import java.util.Optional;

@Component
public class ReglaTemperatura implements ReglaCalidad {
    private static final BigDecimal MIN = new BigDecimal("2.00");
    private static final BigDecimal MAX = new BigDecimal("8.00");

    @Override
    public Optional<String> evaluar(MedicionesDto m) {
        if (m.temperaturaC().compareTo(MIN) < 0 || m.temperaturaC().compareTo(MAX) > 0) {
            return Optional.of("Temperatura fuera de rango permitido (2.00 °C - 8.00 °C): " + m.temperaturaC() + " °C");
        }
        return Optional.empty();
    }
}
