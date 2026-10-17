package pe.edu.utp.acopio.DTO.tanque;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;
public record AsignacionDto(UUID idLote, Long idTanque, String codigo, BigDecimal volumenLitros,
                            OffsetDateTime asignadoEn, Long idUsuarioAsigna, boolean idempotente) {}
