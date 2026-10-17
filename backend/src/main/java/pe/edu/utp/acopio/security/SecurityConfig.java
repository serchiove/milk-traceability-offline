package pe.edu.utp.acopio.security;

import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
//import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> {})
            .csrf(csrf -> csrf.disable()) // Desactivar CSRF (API REST)
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)) // Sin sesiones
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/administracion/catalogos/**").hasRole("JEFATURA")
                .requestMatchers(HttpMethod.POST, "/api/auth/login").permitAll()    // Rutas públicas de Login
                .requestMatchers("/api/estado").permitAll()     // Ruta pública de Diagnóstico
                .requestMatchers("/actuator/health").permitAll() // Ruta pública de Actuator
                .requestMatchers(HttpMethod.POST, "/api/lotes", "/api/lotes/*/asignacion-tanque").hasRole("OPERARIO")
                .requestMatchers(HttpMethod.GET, "/api/reportes", "/api/reportes/csv").hasRole("JEFATURA")
                .requestMatchers(HttpMethod.GET, "/api/catalogos/proveedores", "/api/catalogos/vehiculos", "/api/catalogos/centro",
                                 "/api/lotes", "/api/lotes/*", "/api/tanques").hasAnyRole("OPERARIO", "JEFATURA")
                .anyRequest().denyAll()                   // Todo lo demás, bloqueado
            )
            .exceptionHandling(errors -> errors
                .authenticationEntryPoint((request, response, error) -> {
                    response.setStatus(401);
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.getWriter().write("{\"mensaje\":\"Autenticacion requerida\"}");
                })
                .accessDeniedHandler((request, response, error) -> {
                    response.setStatus(403);
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.getWriter().write("{\"mensaje\":\"Acceso no autorizado\"}");
                }))
            // Añadir nuestro filtro JWT antes del filtro de autenticación estándar de Spring
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    // BCrypt para encriptar/desencriptar contraseñas
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public org.springframework.web.cors.CorsConfigurationSource corsConfigurationSource(
        @org.springframework.beans.factory.annotation.Value("${app.cors.allowed-origins:http://localhost:5173,http://127.0.0.1:5173}") String origins) {
        var config = new org.springframework.web.cors.CorsConfiguration();
        config.setAllowedOrigins(java.util.Arrays.stream(origins.split(",")).map(String::trim).filter(s -> !s.isEmpty()).toList());
        config.setAllowedMethods(java.util.List.of("GET","POST","PUT","PATCH","OPTIONS"));
        config.setAllowedHeaders(java.util.List.of("Authorization","Content-Type","Accept"));
        config.setExposedHeaders(java.util.List.of("Content-Disposition"));
        config.setAllowCredentials(false); // JWT por Authorization; no cookies de sesion.
        config.setMaxAge(3600L);
        var source = new org.springframework.web.cors.UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return source;
    }
}
