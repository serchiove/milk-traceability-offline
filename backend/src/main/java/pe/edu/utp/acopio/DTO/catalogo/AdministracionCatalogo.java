package pe.edu.utp.acopio.DTO.catalogo;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public final class AdministracionCatalogo {
    private AdministracionCatalogo() {}
    public record ProveedorRequest(
        @NotBlank @Pattern(regexp="DNI|RUC") String tipoDocumento,
        @NotBlank @Pattern(regexp="[0-9]{8}|[0-9]{11}") String numeroDocumento,
        @NotBlank @Size(max=180) String razonSocial,
        @NotBlank @Pattern(regexp="PENDIENTE|VIGENTE|VENCIDO") String estadoCert) {}
    public record VehiculoRequest(
        @NotBlank @Size(max=12) String placa,
        @NotNull @DecimalMin("0.01") @Digits(integer=10,fraction=2) BigDecimal capacidadLitros) {}
    public record EstadoRequest(@NotNull Boolean activo) {}
    public record Proveedor(long id,String tipoDocumento,String numeroDocumento,String razonSocial,String estadoCert,boolean activo) {}
    public record Vehiculo(long id,String placa,BigDecimal capacidadLitros,boolean activo) {}
}
