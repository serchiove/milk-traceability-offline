package pe.edu.utp.acopio.DTO.tanque;
import java.math.BigDecimal;
public record TanqueDto(Long id, String codigo, String estado, BigDecimal capacidadLitros,
                        BigDecimal volumenAsignadoLitros, BigDecimal disponibleLitros) {}
