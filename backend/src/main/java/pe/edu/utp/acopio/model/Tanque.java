package pe.edu.utp.acopio.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

/** Entidad persistente; se expone al cliente mediante DTO, nunca directamente. */
@Entity
@Table(name = "tanque", schema = "acopio")
public class Tanque {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "id_tanque")
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "id_centro", nullable = false)
  private CentroAcopio centro;

  @Column(name = "codigo", length = 30, nullable = false)
  private String codigo;

  @Column(name = "capacidad_litros", precision = 12, scale = 2, nullable = false)
  private BigDecimal capacidadLitros;

  @Column(
      name = "volumen_asignado_litros",
      precision = 12,
      scale = 2,
      nullable = false,
      insertable = false,
      updatable = false)
  private BigDecimal volumenAsignadoLitros;

  @Column(name = "estado", length = 15, nullable = false)
  private String estado;

  public Tanque() {}

  public Long getId() {
    return id;
  }

  public CentroAcopio getCentro() {
    return centro;
  }

  public void setCentro(CentroAcopio value) {
    centro = value;
  }

  public String getCodigo() {
    return codigo;
  }

  public void setCodigo(String value) {
    codigo = value;
  }

  public BigDecimal getCapacidadLitros() {
    return capacidadLitros;
  }

  public void setCapacidadLitros(BigDecimal value) {
    capacidadLitros = value;
  }

  public BigDecimal getVolumenAsignadoLitros() {
    return volumenAsignadoLitros;
  }

  public void setVolumenAsignadoLitros(BigDecimal value) {
    volumenAsignadoLitros = value;
  }

  public String getEstado() {
    return estado;
  }

  public void setEstado(String value) {
    estado = value;
  }
}
