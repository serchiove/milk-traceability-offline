package pe.edu.utp.acopio.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

/** Entidad persistente; se expone al cliente mediante DTO, nunca directamente. */
@Entity
@Table(name = "centro_acopio", schema = "acopio")
public class CentroAcopio {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "id_centro")
  private Long id;

  @Column(name = "nombre", length = 120, nullable = false)
  private String nombre;

  @Column(name = "region", length = 100, nullable = false)
  private String region;

  @Column(name = "capacidad_litros", precision = 12, scale = 2, nullable = false)
  private BigDecimal capacidadLitros;

  @Column(name = "activo", nullable = false)
  private boolean activo;

  public CentroAcopio() {}

  public Long getId() {
    return id;
  }

  public String getNombre() {
    return nombre;
  }

  public void setNombre(String value) {
    nombre = value;
  }

  public String getRegion() {
    return region;
  }

  public void setRegion(String value) {
    region = value;
  }

  public BigDecimal getCapacidadLitros() {
    return capacidadLitros;
  }

  public void setCapacidadLitros(BigDecimal value) {
    capacidadLitros = value;
  }

  public boolean getActivo() {
    return activo;
  }

  public void setActivo(boolean value) {
    activo = value;
  }
}
