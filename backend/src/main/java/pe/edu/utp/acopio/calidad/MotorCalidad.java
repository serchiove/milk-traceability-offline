package pe.edu.utp.acopio.calidad;

import org.springframework.stereotype.Component;
import pe.edu.utp.acopio.DTO.lote.MedicionesDto;
import java.util.List;
//import java.util.Optional;
import java.util.stream.Collectors;

@Component
/** Evalúa las mediciones con las reglas inyectadas. Devuelve APROBADO si no encuentra incumplimientos o RECHAZADO con los motivos y la versión aplicada. */
public class MotorCalidad {

    private final String versionReglas;
    private final List<ReglaCalidad> reglas;

    public MotorCalidad(List<ReglaCalidad> reglas,
                        @org.springframework.beans.factory.annotation.Value("${app.calidad.version:DEMO-1}") String versionReglas) {
        if (versionReglas.isBlank() || versionReglas.length() > 40) throw new IllegalArgumentException("Version de reglas invalida");
        this.versionReglas = versionReglas;
        this.reglas = reglas;
    }

    /**
     * Aplica todas las reglas y conserva sus motivos de incumplimiento.
     * Los umbrales DEMO-1 son académicos y no certifican calidad comercial.
     * @param mediciones temperatura, acidez y densidad ya validadas
     * @return decisión con estado, versión y motivo opcional
     */
    public ResultadoEvaluacion evaluar(MedicionesDto mediciones) {
        List<String> incumplimientos = reglas.stream()
            .map(regla -> regla.evaluar(mediciones))
            .filter(opt -> opt.isPresent())
            .map(opt -> opt.get())
            .collect(Collectors.toList());

        if (incumplimientos.isEmpty()) {
            return new ResultadoEvaluacion("APROBADO", versionReglas, null);
        } else {
            String motivo = String.join("; ", incumplimientos);
            return new ResultadoEvaluacion("RECHAZADO", versionReglas, motivo);
        }
    }

    public record ResultadoEvaluacion(
        String estadoEvaluacion,
        String versionReglas,
        String motivo
    ) {}
}
