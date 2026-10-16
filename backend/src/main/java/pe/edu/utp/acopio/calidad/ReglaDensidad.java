package pe.edu.utp.acopio.calidad;

import org.springframework.stereotype.Component;
import pe.edu.utp.acopio.DTO.lote.MedicionesDto;
import java.math.BigDecimal;
import java.util.Optional;

@Component
public class ReglaDensidad implements ReglaCalidad {
    private static final BigDecimal MIN = new BigDecimal("1.0280");
    private static final BigDecimal MAX = new BigDecimal("1.0340");

    @Override
    public Optional<String> evaluar(MedicionesDto m) {
        if (m.densidadGml().compareTo(MIN) < 0 || m.densidadGml().compareTo(MAX) > 0) {
            return Optional.of("Densidad fuera de rango permitido (1.0280 g/mL - 1.0340 g/mL): " + m.densidadGml() + " g/mL");
        }
        return Optional.empty();
    }
}
