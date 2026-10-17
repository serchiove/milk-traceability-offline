package pe.edu.utp.acopio.model;

import jakarta.persistence.*;

/** Entidad persistente; se expone al cliente mediante DTO, nunca directamente. */
@Entity
@Table(name = "usuario", schema = "acopio")
public class Usuario {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "id_usuario")
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "id_rol", nullable = false)
  private Rol rolEntidad;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "id_centro", nullable = false)
  private CentroAcopio centroEntidad;

  @Column(name = "nombre", length = 150, nullable = false)
  private String nombre;

  @Column(name = "dni", length = 8, nullable = false)
  private String dni;

  @Column(name = "email", length = 150, nullable = false)
  private String email;

  @Column(name = "password_hash", length = 255, nullable = false)
  private String passwordHash;

  @Column(name = "activo", nullable = false)
  private boolean activo;

  public Usuario() {}

  public Long getId() {
    return id;
  }

  public Rol getRolEntidad() {
    return rolEntidad;
  }

  public void setRolEntidad(Rol value) {
    rolEntidad = value;
  }

  public CentroAcopio getCentroEntidad() {
    return centroEntidad;
  }

  public void setCentroEntidad(CentroAcopio value) {
    centroEntidad = value;
  }

  public String getNombre() {
    return nombre;
  }

  public void setNombre(String value) {
    nombre = value;
  }

  public String getDni() {
    return dni;
  }

  public void setDni(String value) {
    dni = value;
  }

  public String getEmail() {
    return email;
  }

  public void setEmail(String value) {
    email = value;
  }

  public String getPasswordHash() {
    return passwordHash;
  }

  public void setPasswordHash(String value) {
    passwordHash = value;
  }

  public boolean getActivo() {
    return activo;
  }

  public void setActivo(boolean value) {
    activo = value;
  }

  public Long idUsuario() {
    return id;
  }

  public Long idCentro() {
    return centroEntidad.getId();
  }

  public String rol() {
    return rolEntidad.getNombre();
  }

  public String centro() {
    return centroEntidad.getNombre();
  }

  public boolean activo() {
    return activo && centroEntidad.getActivo();
  }

  public String nombre() {
    return nombre;
  }

  public String dni() {
    return dni;
  }

  public String email() {
    return email;
  }

  public String passwordHash() {
    return passwordHash;
  }
}
