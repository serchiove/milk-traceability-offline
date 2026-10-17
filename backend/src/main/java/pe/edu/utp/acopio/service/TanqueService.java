package pe.edu.utp.acopio.service;

import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.utp.acopio.DTO.consulta.Pagina;
import pe.edu.utp.acopio.DTO.tanque.*;
import pe.edu.utp.acopio.repository.TanqueRepository;

@Service
public class TanqueService {
    private final TanqueRepository tanques;
    public TanqueService(TanqueRepository tanques) {this.tanques=tanques;}
    @Transactional(readOnly=true)
    public Pagina<TanqueDto> listar(Long centro, boolean disponibles, int pagina, int tamano) {
        Pagina.validar(pagina,tamano,"");
        return tanques.listar(centro,disponibles,pagina,tamano);
    }
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
