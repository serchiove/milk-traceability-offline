package pe.edu.utp.acopio.repository;

import jakarta.persistence.EntityManager;
import java.util.Optional;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.utp.acopio.model.Usuario;

@Repository
@Transactional(readOnly = true)
public class UsuarioRepository {
  @jakarta.persistence.PersistenceContext private EntityManager em;

  public Optional<Usuario> buscarPorEmail(String email) {
    return em.createQuery(
            "select u from Usuario u join fetch u.rolEntidad join fetch u.centroEntidad where"
                + " lower(u.email)=lower(:email)",
            Usuario.class)
        .setParameter("email", email.trim())
        .getResultStream()
        .findFirst();
  }
}
