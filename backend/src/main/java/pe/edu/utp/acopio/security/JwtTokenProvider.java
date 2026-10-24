package pe.edu.utp.acopio.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Date;

@Component
/** Genera y valida los tokens firmados de acceso. La clave se configura fuera del repositorio y la expiración delimita el acceso offline del móvil. */
public class JwtTokenProvider {

    @Value("${app.jwt.secret}")
    private String jwtSecret;

    @Value("${app.jwt.expiration-ms}")
    private long jwtExpirationMs;

    @jakarta.annotation.PostConstruct
    void validarConfiguracion() {
        if (jwtExpirationMs <= 0) throw new IllegalStateException("JWT_EXPIRATION_MS debe ser positivo");
        getSigningKey();
    }

    private Key getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
    }

    public String generarToken(String email, Long idUsuario, Long idCentro, String rol) {
        Date ahora = new Date();
        Date expiracion = new Date(ahora.getTime() + jwtExpirationMs);

        return Jwts.builder()
                .setSubject(email)
                .claim("idUsuario", idUsuario)
                .claim("idCentro", idCentro)
                .claim("rol", rol)
                .setIssuedAt(ahora)
                .setExpiration(expiracion)
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    public boolean validarToken(String authToken) {
        try {
            Claims claims = obtenerClaims(authToken);
            Long usuario = getIdUsuarioFromToken(authToken);
            Long centro = getIdCentroFromToken(authToken);
            String rol = getRolFromToken(authToken);
            return claims.getSubject() != null && !claims.getSubject().isBlank() &&
                usuario != null && usuario > 0 && centro != null && centro > 0 &&
                ("OPERARIO".equals(rol) || "JEFATURA".equals(rol));
        } catch (JwtException | IllegalArgumentException e) {
            // Invalid/expired tokens are unauthenticated; never log their content.
            return false;
        }
    }

    private Claims obtenerClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public String getEmailFromToken(String token) {
        return obtenerClaims(token).getSubject();
    }

    public String getRolFromToken(String token) {
        return obtenerClaims(token).get("rol", String.class);
    }

    public Long getIdUsuarioFromToken(String token) {
        Number id = obtenerClaims(token).get("idUsuario", Number.class);
        return id != null ? id.longValue() : null;
    }

    public Long getIdCentroFromToken(String token) {
        Number id = obtenerClaims(token).get("idCentro", Number.class);
        return id != null ? id.longValue() : null;
    }
}