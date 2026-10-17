package pe.edu.utp.acopio.calidad;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import pe.edu.utp.acopio.DTO.lote.MedicionesDto;
import java.math.BigDecimal;
import java.util.Optional;

/** Rangos configurables de demostracion, no una certificacion normativa. */
@Component
public class ReglaTemperatura implements ReglaCalidad {
    private final BigDecimal minimo;
    private final BigDecimal maximo;
    public ReglaTemperatura(@Value("${app.calidad.temperatura.min:2.00}") BigDecimal minimo,
                          @Value("${app.calidad.temperatura.max:8.00}") BigDecimal maximo) {
        if (minimo.compareTo(maximo) > 0) throw new IllegalArgumentException("Rango de temperatura invalido");
        this.minimo = minimo;
        this.maximo = maximo;
    }
    @Override public Optional<String> evaluar(MedicionesDto mediciones) {
        BigDecimal valor = mediciones.temperaturaC();
        if (valor.compareTo(minimo) < 0 || valor.compareTo(maximo) > 0) {
            return Optional.of("Temperatura fuera del rango configurado (" + minimo + " - " + maximo + " °C): " + valor);
        }
        return Optional.empty();
    }
}
