package pe.edu.utp.acopio.DTO.lote;

import java.time.OffsetDateTime;
import java.util.UUID;

public record LoteRecepcionResponse(
    UUID idLote,
    String estadoEvaluacion,
    String versionReglas,
    String motivo,
    String codigoQr,
    String huellaSolicitud,
    OffsetDateTime recibidoEn,
    OffsetDateTime fechaEvaluacion,
    boolean idempotente
) {}