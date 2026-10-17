package pe.edu.utp.acopio.model;

import jakarta.persistence.*;

/** Entidad persistente; se expone al cliente mediante DTO, nunca directamente. */
@Entity
@Table(name = "proveedor", schema = "acopio")
public class Proveedor {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "id_proveedor")
  private Long id;

  @Column(name = "tipo_documento", length = 3, nullable = false)
  private String tipoDocumento;

  @Column(name = "numero_documento", length = 11, nullable = false)
  private String numeroDocumento;

  @Column(name = "razon_social", length = 180, nullable = false)
  private String razonSocial;

  @Column(name = "estado_cert", length = 12, nullable = false)
  private String estadoCert;

  @Column(name = "activo", nullable = false)
  private boolean activo;

  public Proveedor() {}

  public Long getId() {
    return id;
  }

  public String getTipoDocumento() {
    return tipoDocumento;
  }

  public void setTipoDocumento(String value) {
    tipoDocumento = value;
  }

  public String getNumeroDocumento() {
    return numeroDocumento;
  }

  public void setNumeroDocumento(String value) {
    numeroDocumento = value;
  }

  public String getRazonSocial() {
    return razonSocial;
  }

  public void setRazonSocial(String value) {
    razonSocial = value;
  }

  public String getEstadoCert() {
    return estadoCert;
  }

  public void setEstadoCert(String value) {
    estadoCert = value;
  }

  public boolean getActivo() {
    return activo;
  }

  public void setActivo(boolean value) {
    activo = value;
  }
}
