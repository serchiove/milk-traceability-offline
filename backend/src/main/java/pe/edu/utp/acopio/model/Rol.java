package pe.edu.utp.acopio.model;

import jakarta.persistence.*;

/** Entidad persistente; se expone al cliente mediante DTO, nunca directamente. */
@Entity
@Table(name = "rol", schema = "acopio")
public class Rol {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "id_rol")
  private Long id;

  @Column(name = "nombre", length = 40, nullable = false)
  private String nombre;

  @Column(name = "descripcion", columnDefinition = "text", nullable = false)
  private String descripcion;

  public Rol() {}

  public Long getId() {
    return id;
  }

  public String getNombre() {
    return nombre;
  }

  public void setNombre(String value) {
    nombre = value;
  }

  public String getDescripcion() {
    return descripcion;
  }

  public void setDescripcion(String value) {
    descripcion = value;
  }
}
