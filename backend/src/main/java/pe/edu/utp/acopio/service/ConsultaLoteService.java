package pe.edu.utp.acopio.service;

import java.time.*;
import java.util.Set;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.utp.acopio.DTO.consulta.*;
import pe.edu.utp.acopio.repository.ConsultaLoteRepository;

@Service
@Transactional(readOnly = true)
/** Aplica paginación, filtros y aislamiento por centro. Convierte fechas locales inclusivas a un intervalo temporal de consulta. */
public class ConsultaLoteService {
    private final ConsultaLoteRepository lotes;
    private final ZoneId zona;
    public ConsultaLoteService(ConsultaLoteRepository lotes, @Value("${app.consultas.zona:America/Lima}") String zona) {
        this.lotes = lotes; this.zona = ZoneId.of(zona);
    }
    public LoteDetalleDto detalle(Long centro, UUID id) {
        // A foreign center's record is indistinguishable from a missing record.
        return lotes.detalle(centro,id).orElseThrow(RecursoNoEncontradoException::new);
    }
    public LoteDetalleDto porQr(Long centro, String codigo) {
        if (!codigo.startsWith("ACOPIO:") || codigo.length() != 43) throw new IllegalArgumentException("Codigo QR invalido");
        LoteDetalleDto lote = detalle(centro,UUID.fromString(codigo.substring(7)));
        if (!codigo.equals(lote.codigoQr())) throw new RecursoNoEncontradoException();
        return lote;
    }
    public Pagina<LoteDetalleDto> listar(Long centro, String estado, LocalDate desde, LocalDate hasta,
                                         String buscar, int pagina, int tamano) {
        buscar = buscar.trim(); Pagina.validar(pagina,tamano,buscar);
        if (estado != null && !Set.of("PENDIENTE","APROBADO","RECHAZADO").contains(estado))
            throw new IllegalArgumentException("Estado invalido");
        if (desde != null && hasta != null && desde.isAfter(hasta)) throw new IllegalArgumentException("Fechas invertidas");
        try {
            return lotes.listar(centro,estado,desde == null ? null : desde.atStartOfDay(zona).toOffsetDateTime(),
                hasta == null ? null : hasta.plusDays(1).atStartOfDay(zona).toOffsetDateTime(),buscar,pagina,tamano);
        } catch (DateTimeException error) {throw new IllegalArgumentException("Fecha invalida",error);}
    }
}
