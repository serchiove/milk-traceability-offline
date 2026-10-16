package pe.edu.utp.acopio.calidad;

import pe.edu.utp.acopio.DTO.lote.MedicionesDto;
import java.util.Optional;

public interface ReglaCalidad {
    Optional<String> evaluar(MedicionesDto mediciones);
}