package pe.edu.utp.acopio.controller;
import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import pe.edu.utp.acopio.security.OperarioPrincipal;
import pe.edu.utp.acopio.service.ReporteService;

@RestController
@RequestMapping("/api/reportes")
/** Expone indicadores, CSV y XLSX bajo /api/reportes. Spring Security exige JEFATURA; los filtros conservan el centro autenticado. */
public class ReporteController {
    private final ReporteService reportes;
    public ReporteController(ReporteService reportes){this.reportes=reportes;}
    @GetMapping
    public ReporteService.Reporte consultar(@AuthenticationPrincipal OperarioPrincipal usuario,
        @RequestParam(required=false) String estado,
        @RequestParam(required=false) @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate desde,
        @RequestParam(required=false) @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate hasta,
        @RequestParam(defaultValue="") String buscar) {
        return reportes.consultar(usuario.idCentro(),estado,desde,hasta,buscar);
    }
    @GetMapping(value="/xlsx",produces="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    public ResponseEntity<byte[]> exportarExcel(@AuthenticationPrincipal OperarioPrincipal usuario,
        @RequestParam(required=false) String estado,
        @RequestParam(required=false) @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate desde,
        @RequestParam(required=false) @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate hasta,
        @RequestParam(defaultValue="") String buscar) {
        return ResponseEntity.ok().header("Content-Disposition","attachment; filename=acopio-reporte.xlsx")
            .body(reportes.xlsx(reportes.consultar(usuario.idCentro(),estado,desde,hasta,buscar)));
    }
    @GetMapping(value="/csv",produces="text/csv;charset=UTF-8")
    public ResponseEntity<String> exportar(@AuthenticationPrincipal OperarioPrincipal usuario,
        @RequestParam(required=false) String estado,
        @RequestParam(required=false) @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate desde,
        @RequestParam(required=false) @DateTimeFormat(iso=DateTimeFormat.ISO.DATE) LocalDate hasta,
        @RequestParam(defaultValue="") String buscar) {
        return ResponseEntity.ok().header("Content-Disposition","attachment; filename=acopio-reporte.csv")
            .body(reportes.csv(reportes.consultar(usuario.idCentro(),estado,desde,hasta,buscar)));
    }
}
