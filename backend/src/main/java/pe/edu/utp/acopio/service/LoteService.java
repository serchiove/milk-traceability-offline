package pe.edu.utp.acopio.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.utp.acopio.calidad.MotorCalidad;
import pe.edu.utp.acopio.DTO.lote.LoteRecepcionRequest;
import pe.edu.utp.acopio.DTO.lote.LoteRecepcionResponse;
import pe.edu.utp.acopio.repository.LoteRepository;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.ZoneOffset;
import java.util.HexFormat;

@Service
public class LoteService {

    private final LoteRepository loteRepository;
    private final MotorCalidad motorCalidad;

    public LoteService(LoteRepository loteRepository, MotorCalidad motorCalidad) {
        this.loteRepository = loteRepository;
        this.motorCalidad = motorCalidad;
    }

    public static class ConflictoHuellaException extends RuntimeException {
        public ConflictoHuellaException(String mensaje) {
            super(mensaje);
        }
    }

    @Transactional
    public LoteRecepcionResponse registrarLote(LoteRecepcionRequest req, Long idUsuario, Long idCentro) {
        String huellaCalculada = calcularHuellaSha256(req, idUsuario, idCentro);
        if (req.huellaSolicitud() != null && !huellaCalculada.equals(req.huellaSolicitud()))
            throw new IllegalArgumentException("La huella enviada no coincide con los datos recibidos");

        // Preserve historical idempotent retries even if a supplier/vehicle was later deactivated.
        if (loteRepository.buscarEstadoLote(req.idLote()).isEmpty() &&
            !loteRepository.referenciasActivas(req.idProveedor(), req.idVehiculo(), idUsuario, idCentro)) {
            throw new IllegalArgumentException("Referencias inactivas o inexistentes");
        }
        // 1. Intentar insertar lote y registro_calidad PENDIENTE en la misma transacción
        boolean esNuevo = loteRepository.insertarLoteSiNoExiste(req, idUsuario, idCentro, huellaCalculada);
        if (esNuevo) {
            loteRepository.insertarRegistroCalidadPendiente(req);
        }

        // 2. Consultar estado actual y comparar huella_solicitud
        LoteRepository.EstadoLoteBD estadoActual = loteRepository.buscarEstadoLote(req.idLote())
                .orElseThrow(() -> new IllegalStateException("No se encontró el lote tras el registro"));

        if (!estadoActual.huellaSolicitud().equals(huellaCalculada)) {
            throw new ConflictoHuellaException(
                "El idLote ya fue registrado previamente con datos distintos (conflicto de huella SHA-256)"
            );
        }

        // 3. Si sigue PENDIENTE, evaluar con el MotorCalidad y actualizar
        if ("PENDIENTE".equals(estadoActual.estadoEvaluacion())) {
            MotorCalidad.ResultadoEvaluacion resultado = motorCalidad.evaluar(req.mediciones());
            int filasAfectadas = loteRepository.actualizarEvaluacionCalidad(
                req.idLote(),
                resultado.estadoEvaluacion(),
                resultado.versionReglas(),
                resultado.motivo()
            );
            if (filasAfectadas != 1) {
                throw new IllegalStateException("No se pudo actualizar la evaluación PENDIENTE del lote");
            }
            // Volver a consultar para obtener el codigo_qr generado por el trigger tr_resultado
            estadoActual = loteRepository.buscarEstadoLote(req.idLote()).orElseThrow();
        }

        return new LoteRecepcionResponse(
            estadoActual.idLote(),
            estadoActual.estadoEvaluacion(),
            estadoActual.versionReglas(),
            estadoActual.motivo(),
            estadoActual.codigoQr(),
            estadoActual.huellaSolicitud(),
            estadoActual.recibidoEn(),
            estadoActual.fechaEvaluacion(),
            !esNuevo
        );
    }

    private String calcularHuellaSha256(LoteRecepcionRequest req, Long idUsuario, Long idCentro) {
        String cadenaCanonica = String.format(
            "%s|%d|%d|%d|%d|%s|%s|%s|%s|%s",
            req.idLote(),
            req.idProveedor(),
            req.idVehiculo(),
            idUsuario,
            idCentro,
            req.fechaHora().withOffsetSameInstant(ZoneOffset.UTC).toInstant().toString(),
            req.volumenLitros().stripTrailingZeros().toPlainString(),
            req.mediciones().temperaturaC().stripTrailingZeros().toPlainString(),
            req.mediciones().acidezDornic().stripTrailingZeros().toPlainString(),
            req.mediciones().densidadGml().stripTrailingZeros().toPlainString()
        );

        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(cadenaCanonica.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hashBytes); // 64 caracteres hex en minúsculas
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("Algoritmo SHA-256 no disponible", e);
        }
    }
}
