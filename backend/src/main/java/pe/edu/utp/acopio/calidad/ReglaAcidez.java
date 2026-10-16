package pe.edu.utp.acopio.calidad;

import org.springframework.stereotype.Component;
import pe.edu.utp.acopio.DTO.lote.MedicionesDto;
import java.math.BigDecimal;
import java.util.Optional;

@Component
public class ReglaAcidez implements ReglaCalidad {
    private static final BigDecimal MIN = new BigDecimal("14.00");
    private static final BigDecimal MAX = new BigDecimal("18.00");

    @Override
    public Optional<String> evaluar(MedicionesDto m) {
        if (m.acidezDornic().compareTo(MIN) < 0 || m.acidezDornic().compareTo(MAX) > 0) {
            return Optional.of("Acidez fuera de rango permitido (14.00 °D - 18.00 °D): " + m.acidezDornic() + " °D");
        }
        return Optional.empty();
    }
}
