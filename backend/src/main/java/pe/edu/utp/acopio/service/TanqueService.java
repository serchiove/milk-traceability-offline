package pe.edu.utp.acopio.service;

import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.DTO.tanque.*;
import pe.edu.utp.acopio.repository.TanqueRepository;

@Service
/** Valida la asignación de un lote aprobado a un tanque del mismo centro. El orden de bloqueo es lote y después tanque; los reintentos no reservan dos veces. */
public class TanqueService {
    private final TanqueRepository tanques;
    public TanqueService(TanqueRepository tanques) {this.tanques=tanques;}
    @Transactional(readOnly=true)
    public Pagina<TanqueDto> listar(Long centro, boolean disponibles, int pagina, int tamano) {
        Pagina.validar(pagina,tamano,"");
        return tanques.listar(centro,disponibles,pagina,tamano);
    }
    /**
     * Reserva capacidad para un lote aprobado y conserva la idempotencia del destino.
     * @param centro centro autorizado
     * @param usuario operario que realiza la asignación
     * @param idLote UUID del lote recibido
     * @param idTanque tanque de destino del mismo centro
     * @return asignación confirmada con indicador de reintento
     * @throws RecursoNoEncontradoException si el lote o tanque no es accesible
     * @throws ConflictoAsignacionException si no se puede reservar la capacidad
     */
    @Transactional
    public AsignacionDto asignar(Long centro, Long usuario, UUID idLote, Long idTanque) {
        // Lock order is always lot, then tank: serializes retries and reservations.
        var lote=tanques.bloquearLote(centro,idLote).orElseThrow(RecursoNoEncontradoException::new);
        if(lote.tanque()!=null) {
            if(lote.tanque().equals(idTanque)) return tanques.resultado(centro,idLote,true);
            throw new ConflictoAsignacionException("El lote ya tiene un tanque asignado; no se permiten reasignaciones");
        }
        if(!"APROBADO".equals(lote.estado())) throw new ConflictoAsignacionException("Solo se asignan lotes aprobados");
        var tanque=tanques.bloquearTanque(centro,idTanque).orElseThrow(RecursoNoEncontradoException::new);
        if(!"DISPONIBLE".equals(tanque.estado())) throw new ConflictoAsignacionException("Tanque no disponible");
        if(tanque.disponibleLitros().compareTo(lote.volumen())<0) throw new ConflictoAsignacionException("Capacidad insuficiente");
        tanques.asignar(idLote,idTanque,usuario);
        return tanques.resultado(centro,idLote,false);
    }
}
