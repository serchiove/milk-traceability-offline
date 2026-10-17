package pe.edu.utp.acopio.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

/** Entidad persistente; se expone al cliente mediante DTO, nunca directamente. */
@Entity
@Table(name = "vehiculo", schema = "acopio")
public class Vehiculo {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "id_vehiculo")
  private Long id;

  @Column(name = "placa", length = 12, nullable = false)
  private String placa;

  @Column(name = "capacidad_litros", precision = 12, scale = 2, nullable = false)
  private BigDecimal capacidadLitros;

  @Column(name = "activo", nullable = false)
  private boolean activo;

  public Vehiculo() {}

  public Long getId() {
    return id;
  }

  public String getPlaca() {
    return placa;
  }

  public void setPlaca(String value) {
    placa = value;
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
