package pe.edu.utp.acopio.service;
import java.util.Map;
import pe.edu.utp.acopio.repository.EntornoRepository;
import org.springframework.stereotype.Service;
@Service
public class EntornoService {
 private final EntornoRepository repository;
 public EntornoService(EntornoRepository repository) { this.repository=repository; }
 public Map<String,Object> estado() { return Map.of("estado","CONECTADO", "baseDatos","PostgreSQL", "tablas",repository.tablas(), "centros",repository.centros(), "alcance","Entorno de desarrollo; funciones de negocio pendientes"); }
}
