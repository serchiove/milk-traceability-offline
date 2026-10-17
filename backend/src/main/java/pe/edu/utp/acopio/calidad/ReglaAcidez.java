package pe.edu.utp.acopio.calidad;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import pe.edu.utp.acopio.DTO.lote.MedicionesDto;
import java.math.BigDecimal;
import java.util.Optional;

/** Rangos configurables de demostracion, no una certificacion normativa. */
@Component
public class ReglaAcidez implements ReglaCalidad {
    private final BigDecimal minimo;
    private final BigDecimal maximo;
    public ReglaAcidez(@Value("${app.calidad.acidez.min:14.00}") BigDecimal minimo,
                          @Value("${app.calidad.acidez.max:18.00}") BigDecimal maximo) {
        if (minimo.compareTo(maximo) > 0) throw new IllegalArgumentException("Rango de acidez invalido");
        this.minimo = minimo;
        this.maximo = maximo;
    }
    @Override public Optional<String> evaluar(MedicionesDto mediciones) {
        BigDecimal valor = mediciones.acidezDornic();
        if (valor.compareTo(minimo) < 0 || valor.compareTo(maximo) > 0) {
            return Optional.of("Acidez fuera del rango configurado (" + minimo + " - " + maximo + " °D): " + valor);
        }
        return Optional.empty();
    }
}
