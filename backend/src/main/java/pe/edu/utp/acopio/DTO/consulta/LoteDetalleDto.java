package pe.edu.utp.acopio.DTO.consulta;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record LoteDetalleDto(
    UUID idLote, Long idCentro, String centro, Long idProveedor, String proveedor,
    Long idVehiculo, String placa, Long idUsuario, String operario,
    OffsetDateTime fechaHora, OffsetDateTime recibidoEn, BigDecimal volumenLitros,
    BigDecimal temperaturaC, BigDecimal acidezDornic, BigDecimal densidadGml,
    String estadoEvaluacion, String versionReglas, String motivo,
    OffsetDateTime fechaEvaluacion, String codigoQr, Long idTanque, String tanque,
    OffsetDateTime asignadoEn
) {}
