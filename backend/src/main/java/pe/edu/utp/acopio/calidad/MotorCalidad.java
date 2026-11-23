package pe.edu.utp.acopio.calidad;

import org.springframework.stereotype.Component;
import pe.edu.utp.acopio.DTO.lote.MedicionesDto;
import java.util.List;
<<<<<<< HEAD
//import java.util.Optional;
=======
import java.util.Optional;
>>>>>>> bbbf73f (feat: implementar seguridad JWT, login con Postgres y recepcion de lotes)
import java.util.stream.Collectors;

@Component
public class MotorCalidad {

    public static final String VERSION_REGLAS = "NTP-202.001-2026.1";
    private final List<ReglaCalidad> reglas;

    public MotorCalidad(List<ReglaCalidad> reglas) {
        this.reglas = reglas;
    }

    public ResultadoEvaluacion evaluar(MedicionesDto mediciones) {
        List<String> incumplimientos = reglas.stream()
            .map(regla -> regla.evaluar(mediciones))
<<<<<<< HEAD
            .filter(opt -> opt.isPresent())
            .map(opt -> opt.get())
            .collect(Collectors.toList());

=======
            .filter(Optional::isPresent)
            .map(Optional::get)
            .collect(Collectors.toList());
>>>>>>> bbbf73f (feat: implementar seguridad JWT, login con Postgres y recepcion de lotes)
        if (incumplimientos.isEmpty()) {
            return new ResultadoEvaluacion("APROBADO", VERSION_REGLAS, null);
        } else {
            String motivo = String.join("; ", incumplimientos);
            return new ResultadoEvaluacion("RECHAZADO", VERSION_REGLAS, motivo);
        }
    }

    public record ResultadoEvaluacion(
        String estadoEvaluacion,
        String versionReglas,
        String motivo
    ) {}
}
