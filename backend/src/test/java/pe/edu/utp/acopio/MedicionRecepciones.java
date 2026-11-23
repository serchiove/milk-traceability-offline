package pe.edu.utp.acopio;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.jdbc.core.JdbcTemplate;
import pe.edu.utp.acopio.security.JwtTokenProvider;
import static org.junit.jupiter.api.Assertions.*;

/** Medición voluntaria: una recepción de calentamiento y veinte medidas en PostgreSQL de pruebas. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
    "spring.datasource.url=jdbc:postgresql://127.0.0.1:${DB_PORT:55440}/acopio_test",
    "spring.config.import=", "app.mail.enabled=false", "server.address=127.0.0.1"
})
class MedicionRecepciones {
    @LocalServerPort int puerto;
    @Autowired JdbcTemplate db;
    @Autowired JwtTokenProvider tokens;
    @Test void medirAltas() throws Exception {
        assertEquals("acopio_test", db.queryForObject("select current_database()",String.class));
        // Semillas ficticias de V3. No se imprimen identidades ni tokens.
        String sql="select u.id_usuario,u.id_centro,u.email from acopio.usuario u join acopio.rol r using(id_rol) "
            +"join acopio.centro_acopio c using(id_centro) where u.activo and c.activo and r.nombre='OPERARIO' "
            +"and u.email='operario@gloria.com.pe'";
        var op=db.queryForMap(sql);
        long proveedor=db.queryForObject("select min(id_proveedor) from acopio.proveedor where activo",Long.class);
        long vehiculo=db.queryForObject("select min(id_vehiculo) from acopio.vehiculo where activo",Long.class);
        String jwt=tokens.generarToken(op.get("email").toString(),((Number) op.get("id_usuario")).longValue(),
            ((Number) op.get("id_centro")).longValue(),"OPERARIO");
        var cliente=HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
        URI url=URI.create("http://127.0.0.1:"+puerto+"/api/lotes");
        String tag=UUID.fromString(System.getenv().getOrDefault("ACOPIO_MON_CORRIDA",UUID.randomUUID().toString())).toString();
        Path dir=Path.of("target","monitoreo",tag);
        Files.createDirectories(dir);
        var latencias=new ArrayList<Double>(); var fila=new ArrayList<String>();
        fila.add("fechaUTC,fase,muestra,uuid,http,ms,resultado");
        int tardias=0, fallos=0; boolean caliente=false;
        for(int i=0;i<=20;i++) {
            UUID id=UUID.randomUUID(); Instant fecha=Instant.now();
            String cuerpo="""
                {"idLote":"%s","idProveedor":%d,"idVehiculo":%d,"volumenLitros":5,
                 "fechaHora":"%s","mediciones":{"temperaturaC":4,"acidezDornic":16,"densidadGml":1.0300}}
                """.formatted(id,proveedor,vehiculo,fecha);
            var peticion=HttpRequest.newBuilder(url).timeout(Duration.ofSeconds(10))
                .header("Authorization","Bearer "+jwt).header("Content-Type","application/json")
                .POST(HttpRequest.BodyPublishers.ofString(cuerpo)).build();
            int estado=0; boolean ok=false; String resultado;
            long inicio=System.nanoTime();
            try {
                var resp=cliente.send(peticion,HttpResponse.BodyHandlers.ofString());
                estado=resp.statusCode(); ok=estado==201 && resp.body().contains(id.toString());
                resultado=ok?"CREADO":"RESPUESTA_INESPERADA";
            } catch(java.io.IOException e) { resultado="SIN_RESPUESTA"; }
            double ms=(System.nanoTime()-inicio)/1_000_000.0;
            fila.add(String.format(Locale.ROOT,"%s,%s,%d,%s,%d,%.3f,%s",
                fecha,i==0?"calentamiento":"medicion",i,id,estado,ms,resultado));
            if(i==0) caliente=ok;
            else if(!ok) fallos++;
            else {latencias.add(ms);if(ms>=2000)tardias++;}
        }
        latencias.sort(Double::compare);
        String p95=latencias.isEmpty()?"no_disponible":String.format(Locale.ROOT,"%.3f",latencias.get((int)Math.ceil(.95*latencias.size())-1));
        String max=latencias.isEmpty()?"no_disponible":String.format(Locale.ROOT,"%.3f",latencias.get(latencias.size()-1));
        String sha=System.getenv("ACOPIO_MON_COMMIT"); if(sha==null||!sha.matches("[0-9a-fA-F]{40,64}"))sha="sin_identificar";
        Files.write(dir.resolve("recepciones.csv"),fila,StandardCharsets.UTF_8);
        Files.write(dir.resolve("recepciones-resumen.txt"),List.of("fechaUTC="+Instant.now(),"commit="+sha,
            "base=acopio_test","operacion=POST /api/lotes","calentamiento_ok="+caliente,
            "muestras=20","altas_201_con_uuid="+latencias.size(),"fallos="+fallos,"altas_con_2000ms_o_mas="+tardias,
            "p95_ms_solo_altas_validas="+p95,"max_ms_solo_altas_validas="+max,
            "alcance=HTTP local hasta recibir la respuesta. Token de prueba previo; usuarios en paralelo: 1. No es carga de produccion."),StandardCharsets.UTF_8);
        assertTrue(caliente,"Falló el calentamiento: revisa el CSV");
        assertEquals(0,fallos,"Hubo recepciones no confirmadas: revisa el CSV");
        assertEquals(0,tardias,"Hay recepciones que no cumplieron la meta de menos de 2 s");
    }
}
