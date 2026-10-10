package pe.edu.utp.acopio.controller;
import java.util.Map;
import pe.edu.utp.acopio.service.EntornoService;
import org.springframework.web.bind.annotation.*;
@RestController
@RequestMapping("/api")
public class EntornoController {
 private final EntornoService service;
 public EntornoController(EntornoService service) { this.service=service; }
 @GetMapping("/estado") public Map<String,Object> estado() { return service.estado(); }
}
