package pe.edu.utp.acopio.model;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

/** Entidad persistente; se expone al cliente mediante DTO, nunca directamente. */
@Entity
@Table(name = "incidencia", schema = "acopio")
public class Incidencia {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "id_incidencia")
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "id_registro", nullable = false)
  private RegistroCalidad registro;

  @Column(name = "tipo_alerta", length = 30, nullable = false)
  private String tipoAlerta;

  @Column(name = "descripcion", columnDefinition = "text", nullable = false)
  private String descripcion;

  @Column(name = "fecha_hora", nullable = false, insertable = false, updatable = false)
  private OffsetDateTime fechaHora;

  public Incidencia() {}

  public Long getId() {
    return id;
  }

  public RegistroCalidad getRegistro() {
    return registro;
  }

  public void setRegistro(RegistroCalidad value) {
    registro = value;
  }

  public String getTipoAlerta() {
    return tipoAlerta;
  }

  public void setTipoAlerta(String value) {
    tipoAlerta = value;
  }

  public String getDescripcion() {
    return descripcion;
  }

  public void setDescripcion(String value) {
    descripcion = value;
  }

  public OffsetDateTime getFechaHora() {
    return fechaHora;
  }

  public void setFechaHora(OffsetDateTime value) {
    fechaHora = value;
  }
}
