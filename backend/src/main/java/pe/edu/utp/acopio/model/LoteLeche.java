package pe.edu.utp.acopio.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

/** Entidad persistente; se expone al cliente mediante DTO, nunca directamente. */
@Entity
@Table(name = "lote_leche", schema = "acopio")
public class LoteLeche {
  @Id
  @Column(name = "id_lote")
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "id_proveedor", nullable = false)
  private Proveedor proveedor;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "id_vehiculo", nullable = false)
  private Vehiculo vehiculo;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "id_usuario", nullable = false)
  private Usuario usuario;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "id_centro", nullable = false)
  private CentroAcopio centro;

  @Column(name = "fecha_hora", nullable = false)
  private OffsetDateTime fechaHora;

  @Column(name = "recibido_en", nullable = false, insertable = false, updatable = false)
  private OffsetDateTime recibidoEn;

  @Column(name = "volumen_litros", precision = 12, scale = 2, nullable = false)
  private BigDecimal volumenLitros;

  @Column(name = "huella_solicitud", length = 64, nullable = false)
  private String huellaSolicitud;

  @Column(name = "codigo_qr", length = 80, insertable = false, updatable = false)
  private String codigoQr;

  @ManyToOne(fetch = FetchType.LAZY, optional = true)
  @JoinColumn(name = "id_tanque", nullable = true)
  private Tanque tanque;

  @Column(name = "asignado_en")
  private OffsetDateTime asignadoEn;

  @ManyToOne(fetch = FetchType.LAZY, optional = true)
  @JoinColumn(name = "id_usuario_asigna", nullable = true)
  private Usuario usuarioAsigna;

  public LoteLeche() {}

  public UUID getId() {
    return id;
  }

  public Proveedor getProveedor() {
    return proveedor;
  }

  public void setProveedor(Proveedor value) {
    proveedor = value;
  }

  public Vehiculo getVehiculo() {
    return vehiculo;
  }

  public void setVehiculo(Vehiculo value) {
    vehiculo = value;
  }

  public Usuario getUsuario() {
    return usuario;
  }

  public void setUsuario(Usuario value) {
    usuario = value;
  }

  public CentroAcopio getCentro() {
    return centro;
  }

  public void setCentro(CentroAcopio value) {
    centro = value;
  }

  public OffsetDateTime getFechaHora() {
    return fechaHora;
  }

  public void setFechaHora(OffsetDateTime value) {
    fechaHora = value;
  }

  public OffsetDateTime getRecibidoEn() {
    return recibidoEn;
  }

  public void setRecibidoEn(OffsetDateTime value) {
    recibidoEn = value;
  }

  public BigDecimal getVolumenLitros() {
    return volumenLitros;
  }

  public void setVolumenLitros(BigDecimal value) {
    volumenLitros = value;
  }

  public String getHuellaSolicitud() {
    return huellaSolicitud;
  }

  public void setHuellaSolicitud(String value) {
    huellaSolicitud = value;
  }

  public String getCodigoQr() {
    return codigoQr;
  }

  public void setCodigoQr(String value) {
    codigoQr = value;
  }

  public Tanque getTanque() {
    return tanque;
  }

  public void setTanque(Tanque value) {
    tanque = value;
  }

  public OffsetDateTime getAsignadoEn() {
    return asignadoEn;
  }

  public void setAsignadoEn(OffsetDateTime value) {
    asignadoEn = value;
  }

  public Usuario getUsuarioAsigna() {
    return usuarioAsigna;
  }

  public void setUsuarioAsigna(Usuario value) {
    usuarioAsigna = value;
  }
}
