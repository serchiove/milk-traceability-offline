package pe.edu.utp.acopio.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

/** Entidad persistente; se expone al cliente mediante DTO, nunca directamente. */
@Entity
@Table(name = "registro_calidad", schema = "acopio")
public class RegistroCalidad {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "id_registro")
  private Long id;

  @OneToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "id_lote", nullable = false)
  private LoteLeche lote;

  @Column(name = "temperatura_c", precision = 6, scale = 2, nullable = false)
  private BigDecimal temperaturaC;

  @Column(name = "acidez_dornic", precision = 6, scale = 2, nullable = false)
  private BigDecimal acidezDornic;

  @Column(name = "densidad_g_ml", precision = 7, scale = 4, nullable = false)
  private BigDecimal densidadGml;

  @Column(name = "estado_evaluacion", length = 10, nullable = false)
  private String estadoEvaluacion;

  @Column(name = "fecha_evaluacion")
  private OffsetDateTime fechaEvaluacion;

  @Column(name = "version_reglas", length = 40)
  private String versionReglas;

  @Column(name = "motivo", columnDefinition = "text")
  private String motivo;

  public RegistroCalidad() {}

  public Long getId() {
    return id;
  }

  public LoteLeche getLote() {
    return lote;
  }

  public void setLote(LoteLeche value) {
    lote = value;
  }

  public BigDecimal getTemperaturaC() {
    return temperaturaC;
  }

  public void setTemperaturaC(BigDecimal value) {
    temperaturaC = value;
  }

  public BigDecimal getAcidezDornic() {
    return acidezDornic;
  }

  public void setAcidezDornic(BigDecimal value) {
    acidezDornic = value;
  }

  public BigDecimal getDensidadGml() {
    return densidadGml;
  }

  public void setDensidadGml(BigDecimal value) {
    densidadGml = value;
  }

  public String getEstadoEvaluacion() {
    return estadoEvaluacion;
  }

  public void setEstadoEvaluacion(String value) {
    estadoEvaluacion = value;
  }

  public OffsetDateTime getFechaEvaluacion() {
    return fechaEvaluacion;
  }

  public void setFechaEvaluacion(OffsetDateTime value) {
    fechaEvaluacion = value;
  }

  public String getVersionReglas() {
    return versionReglas;
  }

  public void setVersionReglas(String value) {
    versionReglas = value;
  }

  public String getMotivo() {
    return motivo;
  }

  public void setMotivo(String value) {
    motivo = value;
  }
}
