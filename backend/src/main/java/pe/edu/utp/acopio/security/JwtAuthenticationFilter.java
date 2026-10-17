package pe.edu.utp.acopio.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import pe.edu.utp.acopio.repository.UsuarioRepository;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final JwtTokenProvider tokens;
    private final UsuarioRepository usuarios;

    public JwtAuthenticationFilter(JwtTokenProvider tokens, UsuarioRepository usuarios) {
        this.tokens = tokens;
        this.usuarios = usuarios;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String bearer = request.getHeader("Authorization");
        if (bearer != null && bearer.startsWith("Bearer ")) {
            String jwt = bearer.substring(7);
            if (tokens.validarToken(jwt)) {
                String email = tokens.getEmailFromToken(jwt);
                Long usuarioId = tokens.getIdUsuarioFromToken(jwt);
                Long centroId = tokens.getIdCentroFromToken(jwt);
                String rol = tokens.getRolFromToken(jwt);
                // Revalidate current permissions: a signed token must not bypass a deactivated
                // account/center, role change or transfer to a different center.
                if (email != null) usuarios.buscarPorEmail(email).filter(u ->
                        u.activo() && u.idUsuario().equals(usuarioId) &&
                        u.idCentro().equals(centroId) && u.rol().equals(rol))
                    .ifPresent(u -> {
                        var principal = new OperarioPrincipal(u.idUsuario(), u.idCentro(), u.email(), u.rol());
                        var auth = new UsernamePasswordAuthenticationToken(principal, null,
                            List.of(new SimpleGrantedAuthority("ROLE_" + u.rol())));
                        SecurityContextHolder.getContext().setAuthentication(auth);
                    });
            }
        }
        chain.doFilter(request, response);
    }
}
