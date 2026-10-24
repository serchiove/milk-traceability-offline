package pe.edu.utp.acopio;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import pe.edu.utp.acopio.security.JwtTokenProvider;
import java.net.URI;
import java.net.http.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import static org.assertj.core.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class BackendFlowTests {
    @LocalServerPort int port;
    @Autowired JdbcTemplate db;
    @Autowired PasswordEncoder passwords;
    @Autowired JwtTokenProvider tokens;
    private static final AtomicInteger DNIS = new AtomicInteger(10000000 + new java.security.SecureRandom().nextInt(70000000));
    private static final String PASSWORD = "ClavePruebaSoloTests!";
    private final HttpClient http = HttpClient.newHttpClient();
    private long centro, usuario, proveedor, vehiculo;
    private String email;

    private static final String SECRET = randomSecret();
    private static String randomSecret() {
        byte[] key = new byte[48]; new java.security.SecureRandom().nextBytes(key);
        return Base64.getEncoder().encodeToString(key);
    }
    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry properties) {
        properties.add("app.jwt.secret", () -> SECRET);
    }

    @BeforeEach
    void fixture() {
        String unique = UUID.randomUUID().toString();
        centro = db.queryForObject("INSERT INTO acopio.centro_acopio(nombre,region,capacidad_litros) VALUES (?, 'Prueba',10000) RETURNING id_centro", Long.class, "Centro " + unique);
        email = "operario-" + unique + "@prueba.invalid";
        usuario = db.queryForObject("INSERT INTO acopio.usuario(id_rol,id_centro,nombre,dni,email,password_hash) VALUES ((SELECT id_rol FROM acopio.rol WHERE nombre='OPERARIO'),?,'Operario de prueba',?,?,?) RETURNING id_usuario", Long.class, centro, String.valueOf(DNIS.incrementAndGet()), email, passwords.encode(PASSWORD));
        proveedor = db.queryForObject("INSERT INTO acopio.proveedor(tipo_documento,numero_documento,razon_social,activo) VALUES ('DNI',?,'Proveedor ficticio',true) RETURNING id_proveedor", Long.class,String.valueOf(DNIS.incrementAndGet()));
        vehiculo = db.queryForObject("INSERT INTO acopio.vehiculo(placa,capacidad_litros,activo) VALUES (?,5000,true) RETURNING id_vehiculo",Long.class,"T"+unique.substring(0,7).toUpperCase(Locale.ROOT));
    }
    String token() {return tokens.generarToken(email,usuario,centro,"OPERARIO");}
    HttpResponse<String> post(String path, String token, String body) throws Exception {
        var builder=HttpRequest.newBuilder(URI.create("http://127.0.0.1:"+port+path)).header("Content-Type","application/json").POST(HttpRequest.BodyPublishers.ofString(body));
        if(token!=null) builder.header("Authorization","Bearer "+token);
        return http.send(builder.build(),HttpResponse.BodyHandlers.ofString());
    }
    String lote(UUID id, String volumen, String temperatura) {
        return """
            {"idLote":"%s","idProveedor":%d,"idVehiculo":%d,"volumenLitros":%s,
             "fechaHora":"2026-10-15T10:30:00-05:00",
             "mediciones":{"temperaturaC":%s,"acidezDornic":16,"densidadGml":1.0300}}
            """.formatted(id,proveedor,vehiculo,volumen,temperatura);
    }
    int count(String table, UUID id) {return db.queryForObject("SELECT count(*) FROM acopio."+table+" WHERE id_lote=?",Integer.class,id);}

    String jefe() {
        db.update("UPDATE acopio.usuario SET id_rol=(SELECT id_rol FROM acopio.rol WHERE nombre='JEFATURA') WHERE id_usuario=?",usuario);
        return tokens.generarToken(email,usuario,centro,"JEFATURA");
    }
    HttpResponse<String> cambiar(String method,String path,String jwt,String body) throws Exception {
        return http.send(HttpRequest.newBuilder(URI.create("http://127.0.0.1:"+port+path))
            .header("Authorization","Bearer "+jwt).header("Content-Type","application/json")
            .method(method,HttpRequest.BodyPublishers.ofString(body)).build(),HttpResponse.BodyHandlers.ofString());
    }
    @Test void administrationRequiresSupervisorAndValidCatalogData() throws Exception {
        String path="/api/administracion/catalogos/vehiculos";
        String body="{\"placa\":\"ABC-123\",\"capacidadLitros\":5000}";
        assertThat(post(path,null,body).statusCode()).isEqualTo(401);
        assertThat(post(path,token(),body).statusCode()).isEqualTo(403);
        assertThat(get(path,token()).statusCode()).isEqualTo(403);
        String jwt=jefe();
        for(String invalid:List.of("{\"placa\":\"   \",\"capacidadLitros\":5000}","{\"placa\":\"TEST\",\"capacidadLitros\":0}","{\"placa\":\"TEST\",\"capacidadLitros\":1.234}"))
            assertThat(post(path,jwt,invalid).statusCode()).isEqualTo(400);
        assertThat(post("/api/administracion/catalogos/proveedores",jwt,"{\"tipoDocumento\":\"DNI\",\"numeroDocumento\":\"12345678901\",\"razonSocial\":\"Prueba\",\"estadoCert\":\"PENDIENTE\"}").statusCode()).isEqualTo(400);
        assertThat(cambiar("PATCH",path+"/"+vehiculo+"/estado",jwt,"{}").statusCode()).isEqualTo(400);
        assertThat(cambiar("PATCH",path+"/9223372036854775807/estado",jwt,"{\"activo\":false}").statusCode()).isEqualTo(404);
        assertThat(get(path+"?tamano=101",jwt).statusCode()).isEqualTo(400);
    }
    @Test void vehicleLifecycleNormalizesDuplicatesAndPreservesIdentity() throws Exception {
        String jwt=jefe(),path="/api/administracion/catalogos/vehiculos";
        String placa="X"+UUID.randomUUID().toString().substring(0,7);
        String body="{\"placa\":\""+placa+"\",\"capacidadLitros\":1200}";
        assertThat(post(path,jwt,body).statusCode()).isEqualTo(201);
        long id=db.queryForObject("SELECT id_vehiculo FROM acopio.vehiculo WHERE placa=?",Long.class,placa.toUpperCase(Locale.ROOT));
        assertThat(post(path,jwt,body).statusCode()).isEqualTo(409);
        assertThat(cambiar("PUT",path+"/"+id,jwt,body.replace("1200","1500")).statusCode()).isEqualTo(200);
        assertThat(cambiar("PUT",path+"/"+id,jwt,body.replace(placa,"OTRA-PLACA")).statusCode()).isEqualTo(409);
        assertThat(cambiar("PATCH",path+"/"+id+"/estado",jwt,"{\"activo\":false}").statusCode()).isEqualTo(200);
        assertThat(get("/api/catalogos/vehiculos?buscar="+placa,jwt).body()).contains("\"total\":0");
        assertThat(get(path+"?buscar="+placa,jwt).body()).contains("\"activo\":false");
        assertThat(post(path,jwt,body).statusCode()).isEqualTo(409);
        assertThat(cambiar("PATCH",path+"/"+id+"/estado",jwt,"{\"activo\":true}").statusCode()).isEqualTo(200);
        assertThat(get("/api/catalogos/vehiculos?buscar="+placa,jwt).body()).contains("\"total\":1");
    }
    @Test void supplierAdministrationRetainsReceivedLotAndRetry() throws Exception {
        UUID id=UUID.randomUUID();String receipt=lote(id,"100","4");
        assertThat(post("/api/lotes",token(),receipt).statusCode()).isEqualTo(201);
        String jwt=jefe(),path="/api/administracion/catalogos/proveedores";
        String doc=String.valueOf(DNIS.incrementAndGet());
        String body="{\"tipoDocumento\":\"DNI\",\"numeroDocumento\":\""+doc+"\",\"razonSocial\":\"  Nuevo proveedor  \",\"estadoCert\":\"PENDIENTE\"}";
        assertThat(post(path,jwt,body).statusCode()).isEqualTo(201);
        assertThat(post(path,jwt,body).statusCode()).isEqualTo(409);
        long nuevo=db.queryForObject("SELECT id_proveedor FROM acopio.proveedor WHERE numero_documento=?",Long.class,doc);
        assertThat(cambiar("PUT",path+"/"+nuevo,jwt,body.replace("PENDIENTE","VIGENTE")).statusCode()).isEqualTo(200);
        assertThat(cambiar("PUT",path+"/"+nuevo,jwt,body.replace(doc,"99999999")).statusCode()).isEqualTo(409);
        assertThat(cambiar("PATCH",path+"/"+proveedor+"/estado",jwt,"{\"activo\":false}").statusCode()).isEqualTo(200);
        assertThat(get("/api/lotes/"+id,jwt).statusCode()).isEqualTo(200);
        db.update("UPDATE acopio.usuario SET id_rol=(SELECT id_rol FROM acopio.rol WHERE nombre='OPERARIO') WHERE id_usuario=?",usuario);
        assertThat(post("/api/lotes",token(),receipt).statusCode()).isEqualTo(200);
        assertThat(post("/api/lotes",token(),lote(UUID.randomUUID(),"100","4")).statusCode()).isEqualTo(400);
        assertThat(count("lote_leche",id)).isEqualTo(1);
    }

    @Test void lotWithoutQualityStillAppearsAsPendingInJpaProjection() throws Exception {
        UUID id=UUID.randomUUID();
        db.update("INSERT INTO acopio.lote_leche(id_lote,id_proveedor,id_vehiculo,id_usuario,id_centro,fecha_hora,volumen_litros,huella_solicitud) VALUES (?,?,?,?,?,CURRENT_TIMESTAMP,10,?)",id,proveedor,vehiculo,usuario,centro,"a".repeat(64));
        assertThat(get("/api/lotes/"+id,token()).body()).contains("\"estadoEvaluacion\":\"PENDIENTE\"");
        assertThat(get("/api/lotes?estado=PENDIENTE",token()).body()).contains(id.toString());
    }
    @Test void loginUsesDatabaseAndMatchesMobileContract() throws Exception {
        var response=post("/api/auth/login",null,"{\"email\":\""+email+"\",\"password\":\""+PASSWORD+"\"}");
        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.body()).contains("\"accessToken\"","\"usuario\"","\"id\":"+usuario,"\"idCentro\":"+centro,"\"centro\":","\"rol\":\"OPERARIO\"");
        assertThat(response.body()).doesNotContain("password", "passwordHash");
    }
    @Test void incorrectPasswordAndInactiveCenterCannotLogin() throws Exception {
        String request="{\"email\":\""+email+"\",\"password\":\"incorrecta\"}";
        assertThat(post("/api/auth/login",null,request).statusCode()).isEqualTo(401);
        db.update("UPDATE acopio.centro_acopio SET activo=false WHERE id_centro=?",centro);
        request="{\"email\":\""+email+"\",\"password\":\""+PASSWORD+"\"}";
        assertThat(post("/api/auth/login",null,request).statusCode()).isEqualTo(401);
    }
    @Test void missingInvalidAndExpiredTokensAreRejected() throws Exception {
        String body=lote(UUID.randomUUID(),"120","4");
        assertThat(post("/api/lotes",null,body).statusCode()).isEqualTo(401);
        assertThat(post("/api/lotes","token-invalido",body).statusCode()).isEqualTo(401);
        assertThat(tokens.validarToken("token-invalido")).isFalse();
        String expired = io.jsonwebtoken.Jwts.builder().setSubject(email)
            .claim("idUsuario",usuario).claim("idCentro",centro).claim("rol","OPERARIO")
            .setExpiration(new Date(1000)).signWith(io.jsonwebtoken.security.Keys.hmacShaKeyFor(SECRET.getBytes(java.nio.charset.StandardCharsets.UTF_8))).compact();
        assertThat(post("/api/lotes",expired,body).statusCode()).isEqualTo(401);
    }
    @Test void supervisorCannotRegisterLots() throws Exception {
        db.update("UPDATE acopio.usuario SET id_rol=(SELECT id_rol FROM acopio.rol WHERE nombre='JEFATURA') WHERE id_usuario=?",usuario);
        String supervisor=tokens.generarToken(email,usuario,centro,"JEFATURA");
        assertThat(post("/api/lotes",supervisor,lote(UUID.randomUUID(),"120","4")).statusCode()).isEqualTo(403);
    }
    @Test void revokedAccountAndTransferredCenterInvalidateExistingToken() throws Exception {
        String jwt=token();
        db.update("UPDATE acopio.usuario SET activo=false WHERE id_usuario=?",usuario);
        assertThat(post("/api/lotes",jwt,lote(UUID.randomUUID(),"120","4")).statusCode()).isEqualTo(401);
        db.update("UPDATE acopio.usuario SET activo=true WHERE id_usuario=?",usuario);
        db.update("UPDATE acopio.centro_acopio SET activo=false WHERE id_centro=?",centro);
        assertThat(post("/api/lotes",jwt,lote(UUID.randomUUID(),"120","4")).statusCode()).isEqualTo(401);
    }
    @Test void approvalIsAtomicAndRetryIsIdempotent() throws Exception {
        UUID id=UUID.randomUUID(); String body=lote(id,"120.00","4.00"), jwt=token();
        var response=post("/api/lotes",jwt,body);
        assertThat(response.statusCode()).isEqualTo(201);
        assertThat(response.body()).contains("APROBADO","ACOPIO:"+id,"DEMO-1","\"idempotente\":false");
        response=post("/api/lotes",jwt,lote(id,"120","4"));
        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.body()).contains("\"idempotente\":true");
        assertThat(count("lote_leche",id)).isEqualTo(1);
        assertThat(count("registro_calidad",id)).isEqualTo(1);
    }
    @Test void changedContentProducesConflictWithoutModifyingOriginal() throws Exception {
        UUID id=UUID.randomUUID();String jwt=token();
        assertThat(post("/api/lotes",jwt,lote(id,"120","4")).statusCode()).isEqualTo(201);
        assertThat(post("/api/lotes",jwt,lote(id,"121","4")).statusCode()).isEqualTo(409);
        assertThat(db.queryForObject("SELECT volumen_litros FROM acopio.lote_leche WHERE id_lote=?",java.math.BigDecimal.class,id)).isEqualByComparingTo("120");
    }
    @Test void rejectedLotIsPreservedWithOneIncidentAndNoQr() throws Exception {
        UUID id=UUID.randomUUID(); String jwt=token(), body=lote(id,"120","15");
        assertThat(post("/api/lotes",jwt,body).statusCode()).isEqualTo(201);
        assertThat(post("/api/lotes",jwt,body).statusCode()).isEqualTo(200);
        assertThat(db.queryForObject("SELECT estado_evaluacion FROM acopio.registro_calidad WHERE id_lote=?",String.class,id)).isEqualTo("RECHAZADO");
        assertThat(db.queryForObject("SELECT count(*) FROM acopio.incidencia i JOIN acopio.registro_calidad r USING(id_registro) WHERE r.id_lote=?",Integer.class,id)).isEqualTo(1);
        assertThat(db.queryForObject("SELECT codigo_qr FROM acopio.lote_leche WHERE id_lote=?",String.class,id)).isNull();
    }
    @Test void inactiveCatalogAndExcessPrecisionDoNotCreateLots() throws Exception {
        UUID id=UUID.randomUUID();String jwt=token();
        db.update("UPDATE acopio.proveedor SET activo=false WHERE id_proveedor=?",proveedor);
        assertThat(post("/api/lotes",jwt,lote(id,"120","4")).statusCode()).isEqualTo(400);
        db.update("UPDATE acopio.proveedor SET activo=true WHERE id_proveedor=?",proveedor);
        assertThat(post("/api/lotes",jwt,lote(id,"120.001","4")).statusCode()).isEqualTo(400);
        assertThat(post("/api/lotes",jwt,lote(id,"120","-274")).statusCode()).isEqualTo(400);
        assertThat(count("lote_leche",id)).isZero();
        assertThat(count("registro_calidad",id)).isZero();
    }
    @Test void concurrentIdenticalRequestsProduceOneLot() throws Exception {
        UUID id=UUID.randomUUID();String jwt=token(), body=lote(id,"120","4");
        ExecutorService workers=Executors.newFixedThreadPool(2);
        try {
            var a=workers.submit(()->post("/api/lotes",jwt,body).statusCode());
            var b=workers.submit(()->post("/api/lotes",jwt,body).statusCode());
            assertThat(List.of(a.get(15,TimeUnit.SECONDS),b.get(15,TimeUnit.SECONDS))).containsExactlyInAnyOrder(201,200);
            assertThat(count("lote_leche",id)).isEqualTo(1);
        } finally {workers.shutdownNow();}
    }
    @Test void databaseFailureRollsBackLotAndMeasurements() throws Exception {
        UUID id=UUID.randomUUID();
        db.execute("ALTER TABLE acopio.registro_calidad ADD CONSTRAINT test_rollback CHECK (id_lote <> '"+id+"'::uuid)");
        try {
            assertThat(post("/api/lotes",token(),lote(id,"120","4")).statusCode()).isEqualTo(400);
            assertThat(count("lote_leche",id)).isZero();
            assertThat(count("registro_calidad",id)).isZero();
        } finally {db.execute("ALTER TABLE acopio.registro_calidad DROP CONSTRAINT test_rollback");}
    }
    @Test void developmentSeedPasswordIsUsable() {
        String hash=db.queryForObject("SELECT password_hash FROM acopio.usuario WHERE email='operario@gloria.com.pe'",String.class);
        assertThat(passwords.matches("123456",hash)).isTrue();
    }

    HttpResponse<String> get(String path, String jwt) throws Exception {
        var builder=HttpRequest.newBuilder(URI.create("http://127.0.0.1:"+port+path)).GET();
        if(jwt!=null) builder.header("Authorization","Bearer "+jwt);
        return http.send(builder.build(),HttpResponse.BodyHandlers.ofString());
    }
    @Test void catalogsRequireAuthenticationAndOnlyExposeActiveRecords() throws Exception {
        String placa=db.queryForObject("SELECT placa FROM acopio.vehiculo WHERE id_vehiculo=?",String.class,vehiculo);
        String documento=db.queryForObject("SELECT numero_documento FROM acopio.proveedor WHERE id_proveedor=?",String.class,proveedor);
        assertThat(get("/api/catalogos/proveedores",null).statusCode()).isEqualTo(401);
        var proveedores=get("/api/catalogos/proveedores?buscar="+documento,token());
        assertThat(proveedores.statusCode()).isEqualTo(200);
        assertThat(proveedores.body()).contains("\"total\":1","\"id\":"+proveedor);
        var vehiculos=get("/api/catalogos/vehiculos?buscar="+placa.toLowerCase(Locale.ROOT),token());
        assertThat(vehiculos.statusCode()).isEqualTo(200);
        assertThat(vehiculos.body()).contains("\"total\":1","\"id\":"+vehiculo);
        db.update("UPDATE acopio.proveedor SET activo=false WHERE id_proveedor=?",proveedor);
        db.update("UPDATE acopio.vehiculo SET activo=false WHERE id_vehiculo=?",vehiculo);
        assertThat(get("/api/catalogos/proveedores?buscar="+documento,token()).body()).contains("\"total\":0","\"elementos\":[]");
        assertThat(get("/api/catalogos/vehiculos?buscar="+placa,token()).body()).contains("\"total\":0","\"elementos\":[]");
    }
    @Test void centerAndLotQueriesAreScopedToAuthenticatedCenter() throws Exception {
        long centroA=centro;String tokenA=token(); UUID a=UUID.randomUUID();
        assertThat(post("/api/lotes",tokenA,lote(a,"120","4")).statusCode()).isEqualTo(201);
        fixture(); String tokenB=token(); UUID b=UUID.randomUUID();
        assertThat(post("/api/lotes",tokenB,lote(b,"200","4")).statusCode()).isEqualTo(201);
        var listado=get("/api/lotes?idCentro="+centro,tokenA);
        assertThat(listado.statusCode()).isEqualTo(200);
        assertThat(listado.body()).contains(a.toString(),"\"total\":1").doesNotContain(b.toString());
        assertThat(get("/api/lotes/"+b,tokenA).statusCode()).isEqualTo(404);
        assertThat(get("/api/lotes/por-qr?codigo=ACOPIO:"+b,tokenA).statusCode()).isEqualTo(404);
        var centroUsuario=get("/api/catalogos/centro?idCentro="+centro,tokenA);
        assertThat(centroUsuario.statusCode()).isEqualTo(200);
        assertThat(centroUsuario.body()).contains("\"id\":"+centroA);
        var detalle=get("/api/lotes/"+a,tokenA);
        assertThat(detalle.statusCode()).isEqualTo(200);
        assertThat(detalle.body()).contains("\"estadoEvaluacion\":\"APROBADO\"","\"densidadGml\":1.0300").doesNotContain("password","huellaSolicitud");
    }
    @Test void lotFiltersUseInclusiveLocalDatesAndBoundedPagination() throws Exception {
        String jwt=token();UUID a=UUID.randomUUID(),b=UUID.randomUUID(),c=UUID.randomUUID();
        assertThat(post("/api/lotes",jwt,lote(a,"120","4")).statusCode()).isEqualTo(201);
        assertThat(post("/api/lotes",jwt,lote(b,"120","15").replace("2026-10-15T10:30:00-05:00","2026-10-16T00:00:00Z")).statusCode()).isEqualTo(201);
        assertThat(post("/api/lotes",jwt,lote(c,"120","4").replace("2026-10-15T10:30:00-05:00","2026-10-16T05:00:00Z")).statusCode()).isEqualTo(201);
        var dia=get("/api/lotes?desde=2026-10-15&hasta=2026-10-15",jwt);
        assertThat(dia.statusCode()).isEqualTo(200);
        assertThat(dia.body()).contains(a.toString(),b.toString(),"\"total\":2").doesNotContain(c.toString());
        assertThat(get("/api/lotes?estado=RECHAZADO",jwt).body()).contains(b.toString(),"\"total\":1").doesNotContain(a.toString());
        var pagina=get("/api/lotes?tamano=1&pagina=0",jwt);
        assertThat(pagina.body()).contains("\"total\":3","\"tamano\":1","\"pagina\":0",c.toString()).doesNotContain(a.toString(),b.toString());
        assertThat(get("/api/lotes?buscar="+a,jwt).body()).contains(a.toString(),"\"total\":1");
        assertThat(get("/api/lotes?pagina=100",jwt).body()).contains("\"elementos\":[]","\"total\":3");
    }
    @Test void qrLookupOnlyAcceptsAssignedCodes() throws Exception {
        String jwt=token();UUID aprobado=UUID.randomUUID(),rechazado=UUID.randomUUID();
        post("/api/lotes",jwt,lote(aprobado,"120","4"));
        post("/api/lotes",jwt,lote(rechazado,"120","15"));
        assertThat(get("/api/lotes/por-qr?codigo=ACOPIO:"+aprobado,jwt).statusCode()).isEqualTo(200);
        assertThat(get("/api/lotes/por-qr?codigo=ACOPIO:"+rechazado,jwt).statusCode()).isEqualTo(404);
        assertThat(get("/api/lotes/por-qr?codigo=ACOPIO:"+UUID.randomUUID(),jwt).statusCode()).isEqualTo(404);
        assertThat(get("/api/lotes/por-qr?codigo=invalido",jwt).statusCode()).isEqualTo(400);
    }
    @Test void invalidQueryParametersReturn400() throws Exception {
        String jwt=token();
        for(String query:List.of("pagina=-1","tamano=101","estado=INVENTADO","desde=2026-10-16&hasta=2026-10-15","desde=mal","pagina=no")) {
            assertThat(get("/api/lotes?"+query,jwt).statusCode()).as(query).isEqualTo(400);
        }
        assertThat(get("/api/catalogos/proveedores?tamano=0",jwt).statusCode()).isEqualTo(400);
        assertThat(get("/api/lotes/uuid-invalido",jwt).statusCode()).isEqualTo(400);
        assertThat(get("/api/lotes/por-qr",jwt).statusCode()).isEqualTo(400);
        String injection=java.net.URLEncoder.encode("' OR 1=1 --",java.nio.charset.StandardCharsets.UTF_8);
        assertThat(get("/api/lotes?buscar="+injection,jwt).body()).contains("\"total\":0");
    }
    @Test void supervisorCanReadOwnCenterButStillCannotCreateLots() throws Exception {
        UUID id=UUID.randomUUID();post("/api/lotes",token(),lote(id,"120","4"));
        db.update("UPDATE acopio.usuario SET id_rol=(SELECT id_rol FROM acopio.rol WHERE nombre='JEFATURA') WHERE id_usuario=?",usuario);
        String jwt=tokens.generarToken(email,usuario,centro,"JEFATURA");
        assertThat(get("/api/lotes/"+id,jwt).statusCode()).isEqualTo(200);
        assertThat(get("/api/catalogos/centro",jwt).statusCode()).isEqualTo(200);
        assertThat(post("/api/lotes",jwt,lote(UUID.randomUUID(),"120","4")).statusCode()).isEqualTo(403);
    }

    long tanque(String capacidad, String estado) {
        return db.queryForObject("INSERT INTO acopio.tanque(id_centro,codigo,capacidad_litros,estado) VALUES (?,?,?::numeric,?) RETURNING id_tanque",Long.class,centro,"T-"+UUID.randomUUID().toString().substring(0,20),capacidad,estado);
    }
    HttpResponse<String> asignar(UUID lote, long tanque, String jwt) throws Exception {
        return post("/api/lotes/"+lote+"/asignacion-tanque",jwt,"{\"idTanque\":"+tanque+"}");
    }
    @Test void assigningAndRetryingReserveVolumeOnlyOnce() throws Exception {
        UUID id=UUID.randomUUID();String jwt=token();long tank=tanque("500","DISPONIBLE");
        post("/api/lotes",jwt,lote(id,"120","4"));
        var primera=asignar(id,tank,jwt);
        assertThat(primera.statusCode()).isEqualTo(201);
        assertThat(primera.body()).contains("\"idempotente\":false","\"idUsuarioAsigna\":"+usuario);
        var repetida=asignar(id,tank,jwt);
        assertThat(repetida.statusCode()).isEqualTo(200);
        assertThat(repetida.body()).contains("\"idempotente\":true");
        assertThat(db.queryForObject("SELECT volumen_asignado_litros FROM acopio.tanque WHERE id_tanque=?",java.math.BigDecimal.class,tank)).isEqualByComparingTo("120");
        assertThat(get("/api/lotes/"+id,jwt).body()).contains("\"idTanque\":"+tank);
        assertThat(asignar(id,tanque("500","DISPONIBLE"),jwt).statusCode()).isEqualTo(409);
        assertThat(get("/api/tanques?disponibles=true",jwt).body()).contains("\"disponibleLitros\":380.00");
    }
    @Test void rejectedLotsUnavailableAndSmallTanksCannotBeAssigned() throws Exception {
        UUID rechazado=UUID.randomUUID(),aprobado=UUID.randomUUID();String jwt=token();
        post("/api/lotes",jwt,lote(rechazado,"120","15"));
        post("/api/lotes",jwt,lote(aprobado,"120","4"));
        long disponible=tanque("500","DISPONIBLE"),mantenimiento=tanque("500","MANTENIMIENTO"),pequeno=tanque("100","DISPONIBLE");
        assertThat(asignar(rechazado,disponible,jwt).statusCode()).isEqualTo(409);
        assertThat(asignar(aprobado,mantenimiento,jwt).statusCode()).isEqualTo(409);
        assertThat(asignar(aprobado,pequeno,jwt).statusCode()).isEqualTo(409);
        assertThat(db.queryForObject("SELECT id_tanque FROM acopio.lote_leche WHERE id_lote=?",Long.class,aprobado)).isNull();
        assertThat(db.queryForObject("SELECT volumen_asignado_litros FROM acopio.tanque WHERE id_tanque=?",java.math.BigDecimal.class,pequeno)).isEqualByComparingTo("0");
        assertThat(get("/api/tanques?disponibles=true",jwt).body()).doesNotContain("\"id\":"+mantenimiento+",");
    }
    @Test void assignmentAndTankQueriesCannotCrossCenters() throws Exception {
        UUID id=UUID.randomUUID();String jwtA=token();long tankA=tanque("500","DISPONIBLE");
        post("/api/lotes",jwtA,lote(id,"120","4"));
        fixture();long tankB=tanque("500","DISPONIBLE");String jwtB=token();
        assertThat(asignar(id,tankB,jwtA).statusCode()).isEqualTo(404);
        assertThat(asignar(id,tankB,jwtB).statusCode()).isEqualTo(404);
        assertThat(get("/api/tanques",jwtB).body()).contains("\"id\":"+tankB+",").doesNotContain("\"id\":"+tankA+",");
    }
    @Test void assignmentRequiresOperarioAndValidTank() throws Exception {
        UUID id=UUID.randomUUID();long tank=tanque("500","DISPONIBLE");String jwt=token();
        post("/api/lotes",jwt,lote(id,"120","4"));
        assertThat(asignar(id,tank,null).statusCode()).isEqualTo(401);
        assertThat(asignar(id,-1,jwt).statusCode()).isEqualTo(400);
        db.update("UPDATE acopio.usuario SET id_rol=(SELECT id_rol FROM acopio.rol WHERE nombre='JEFATURA') WHERE id_usuario=?",usuario);
        String jefatura=tokens.generarToken(email,usuario,centro,"JEFATURA");
        assertThat(asignar(id,tank,jefatura).statusCode()).isEqualTo(403);
        assertThat(get("/api/tanques",jefatura).statusCode()).isEqualTo(200);
    }
    @Test void concurrentAssignmentsCannotOverbookTank() throws Exception {
        UUID a=UUID.randomUUID(),b=UUID.randomUUID();String jwt=token();long tank=tanque("100","DISPONIBLE");
        post("/api/lotes",jwt,lote(a,"80","4"));post("/api/lotes",jwt,lote(b,"80","4"));
        ExecutorService workers=Executors.newFixedThreadPool(2);
        try {
            var x=workers.submit(()->asignar(a,tank,jwt).statusCode());
            var y=workers.submit(()->asignar(b,tank,jwt).statusCode());
            assertThat(List.of(x.get(15,TimeUnit.SECONDS),y.get(15,TimeUnit.SECONDS))).containsExactlyInAnyOrder(201,409);
            assertThat(db.queryForObject("SELECT volumen_asignado_litros FROM acopio.tanque WHERE id_tanque=?",java.math.BigDecimal.class,tank)).isEqualByComparingTo("80");
            assertThat(db.queryForObject("SELECT count(*) FROM acopio.lote_leche WHERE id_tanque=?",Integer.class,tank)).isEqualTo(1);
        } finally {workers.shutdownNow();}
    }


    @Test void browserCorsAllowsConfiguredOriginWithoutBypassingAuthentication() throws Exception {
        var url=URI.create("http://127.0.0.1:"+port+"/api/reportes");
        var preflight=HttpRequest.newBuilder(url).header("Origin","http://localhost:5173")
            .header("Access-Control-Request-Method","GET").header("Access-Control-Request-Headers","authorization")
            .method("OPTIONS",HttpRequest.BodyPublishers.noBody()).build();
        var allowed=http.send(preflight,HttpResponse.BodyHandlers.ofString());
        assertThat(allowed.statusCode()).isEqualTo(200);
        assertThat(allowed.headers().firstValue("Access-Control-Allow-Origin")).contains("http://localhost:5173");
        var unauthenticated=http.send(HttpRequest.newBuilder(url).header("Origin","http://localhost:5173").GET().build(),HttpResponse.BodyHandlers.ofString());
        assertThat(unauthenticated.statusCode()).isEqualTo(401);
        assertThat(unauthenticated.headers().firstValue("Access-Control-Allow-Origin")).contains("http://localhost:5173");
        var denied=http.send(HttpRequest.newBuilder(url).header("Origin","https://no-autorizado.invalid")
            .header("Access-Control-Request-Method","GET").method("OPTIONS",HttpRequest.BodyPublishers.noBody()).build(),HttpResponse.BodyHandlers.ofString());
        assertThat(denied.statusCode()).isEqualTo(403);
        assertThat(denied.headers().firstValue("Access-Control-Allow-Origin")).isEmpty();
        String jwt=jefe();
        var download=http.send(HttpRequest.newBuilder(URI.create(url+"/csv")).header("Origin","http://localhost:5173")
            .header("Authorization","Bearer "+jwt).GET().build(),HttpResponse.BodyHandlers.ofString());
        assertThat(download.statusCode()).isEqualTo(200);
        assertThat(download.headers().firstValue("Access-Control-Expose-Headers").orElse("")).contains("Content-Disposition");
    }
    @Test void reportsRequireJefaturaAndRespectFiltersAndCenter() throws Exception {
        UUID aprobado=UUID.randomUUID(), rechazado=UUID.randomUUID();String op=token();
        post("/api/lotes",op,lote(aprobado,"100","4"));post("/api/lotes",op,lote(rechazado,"50","12"));
        assertThat(get("/api/reportes",op).statusCode()).isEqualTo(403);
        assertThat(get("/api/reportes/csv",null).statusCode()).isEqualTo(401);
        db.update("UPDATE acopio.usuario SET id_rol=(SELECT id_rol FROM acopio.rol WHERE nombre='JEFATURA') WHERE id_usuario=?",usuario);
        String jwt=tokens.generarToken(email,usuario,centro,"JEFATURA");
        var reporte=get("/api/reportes?desde=2026-10-15&hasta=2026-10-15",jwt);
        assertThat(reporte.statusCode()).isEqualTo(200);
        assertThat(reporte.body()).contains("\"total\":2","\"volumenLitros\":150.00","\"tasaAprobacion\":50.0","\"porcentajeLotesConIncidencia\":50.0","\"incidencias\":[{");
        assertThat(reporte.body()).contains("\"volumenAprobadoLitros\":100.00","\"volumenRechazadoLitros\":50.00","\"volumenPendienteLitros\":0.00","\"porcentajeVolumenRechazado\":33.333");
        var filtrado=get("/api/reportes?estado=APROBADO",jwt);
        assertThat(filtrado.body()).contains(aprobado.toString()).doesNotContain(rechazado.toString());
        assertThat(get("/api/reportes?desde=2026-10-16&hasta=2026-10-15",jwt).statusCode()).isEqualTo(400);
        assertThat(get("/api/reportes?desde=2027-01-01",jwt).body()).contains("\"total\":0","\"tasaAprobacion\":0.0");
        assertThat(get("/api/reportes?desde=2027-01-01",jwt).body()).contains("\"porcentajeVolumenAprobado\":0.0","\"porcentajeVolumenRechazado\":0.0");
        long anterior=centro;fixture();
        db.update("UPDATE acopio.usuario SET id_rol=(SELECT id_rol FROM acopio.rol WHERE nombre='JEFATURA') WHERE id_usuario=?",usuario);
        String otro=tokens.generarToken(email,usuario,centro,"JEFATURA");
        assertThat(get("/api/reportes?idCentro="+anterior,otro).body()).doesNotContain(aprobado.toString(),rechazado.toString());
    }
    @Test void csvExportsFilteredRowsAndEscapesSpreadsheetContent() throws Exception {
        db.update("UPDATE acopio.proveedor SET razon_social=? WHERE id_proveedor=?","=SUM(1,2)\n\"Nombre\"",proveedor);
        UUID id=UUID.randomUUID();post("/api/lotes",token(),lote(id,"100","4"));
        db.update("UPDATE acopio.usuario SET id_rol=(SELECT id_rol FROM acopio.rol WHERE nombre='JEFATURA') WHERE id_usuario=?",usuario);
        String jwt=tokens.generarToken(email,usuario,centro,"JEFATURA");
        var csv=get("/api/reportes/csv?estado=APROBADO",jwt);
        assertThat(csv.statusCode()).isEqualTo(200);
        assertThat(csv.headers().firstValue("Content-Disposition").orElse("")).contains("attachment");
        assertThat(csv.body()).contains(id.toString(),"'=SUM(1,2)","\"\"Nombre\"\"");
        assertThat(get("/api/reportes/csv?estado=RECHAZADO",jwt).body()).doesNotContain(id.toString());
    }
    @Test void logbackRecordsCommittedReceiptWithoutLoggingRolledBackReceipt() throws Exception {
        var logger = (ch.qos.logback.classic.Logger) org.slf4j.LoggerFactory.getLogger(pe.edu.utp.acopio.service.LoteService.class);
        var appender = new ch.qos.logback.core.read.ListAppender<ch.qos.logback.classic.spi.ILoggingEvent>();
        appender.setContext(logger.getLoggerContext());
        appender.start();
        logger.addAppender(appender);
        UUID confirmado = UUID.randomUUID(), fallido = UUID.randomUUID();
        try {
            assertThat(post("/api/lotes", token(), lote(confirmado, "100", "4")).statusCode()).isEqualTo(201);
            db.execute("ALTER TABLE acopio.registro_calidad ADD CONSTRAINT test_rollback_log CHECK (id_lote <> '" + fallido + "'::uuid)");
            try {
                assertThat(post("/api/lotes", token(), lote(fallido, "100", "4")).statusCode()).isEqualTo(400);
            } finally { db.execute("ALTER TABLE acopio.registro_calidad DROP CONSTRAINT test_rollback_log"); }
            var mensajes = appender.list.stream().map(ch.qos.logback.classic.spi.ILoggingEvent::getFormattedMessage).toList();
            assertThat(mensajes).anyMatch(m -> m.contains("recepcion_confirmada") && m.contains(confirmado.toString()));
            assertThat(mensajes).noneMatch(m -> m.contains(fallido.toString()) || m.contains(PASSWORD) || m.contains("Bearer"));
        } finally { logger.detachAppender(appender); appender.stop(); }
    }

    HttpResponse<byte[]> excel(String query, String jwt) throws Exception {
        var request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + "/api/reportes/xlsx" + query)).GET();
        if (jwt != null) request.header("Authorization", "Bearer " + jwt);
        return http.send(request.build(), HttpResponse.BodyHandlers.ofByteArray());
    }

    @Test void excelRequiresJefaturaAndExportsFilteredNumericRows() throws Exception {
        assertThat(excel("", null).statusCode()).isEqualTo(401);
        String op = token();
        assertThat(excel("", op).statusCode()).isEqualTo(403);
        String supplier = "=SUM(1,2)\n\"Lechería\"";
        db.update("UPDATE acopio.proveedor SET razon_social=? WHERE id_proveedor=?", supplier, proveedor);
        UUID aprobado = UUID.randomUUID(), rechazado = UUID.randomUUID();
        assertThat(post("/api/lotes", op, lote(aprobado, "120.50", "4")).statusCode()).isEqualTo(201);
        assertThat(post("/api/lotes", op, lote(rechazado, "50", "12")).statusCode()).isEqualTo(201);
        var response = excel("?estado=APROBADO&desde=2026-10-15&hasta=2026-10-15", jefe());
        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.headers().firstValue("Content-Type").orElse("")).contains("spreadsheetml.sheet");
        assertThat(response.headers().firstValue("Content-Disposition").orElse("")).contains("acopio-reporte.xlsx");
        try (var book = new org.apache.poi.xssf.usermodel.XSSFWorkbook(new java.io.ByteArrayInputStream(response.body()))) {
            var sheet = book.getSheet("Recepciones");
            assertThat(sheet).isNotNull();
            assertThat(sheet.getLastRowNum()).isEqualTo(1);
            assertThat(sheet.getRow(0).getCell(0).getStringCellValue()).isEqualTo("UUID");
            var row = sheet.getRow(1);
            assertThat(row.getCell(0).getStringCellValue()).isEqualTo(aprobado.toString());
            assertThat(row.getCell(3).getCellType()).isEqualTo(org.apache.poi.ss.usermodel.CellType.STRING);
            assertThat(row.getCell(3).getStringCellValue()).isEqualTo(supplier);
            assertThat(row.getCell(6).getCellType()).isEqualTo(org.apache.poi.ss.usermodel.CellType.NUMERIC);
            assertThat(row.getCell(6).getNumericCellValue()).isEqualTo(120.5);
            assertThat(row.getCell(10).getStringCellValue()).isEqualTo("APROBADO");
        }
    }

    @Test void excelDoesNotExposeLotsFromAnotherCenter() throws Exception {
        UUID ajeno = UUID.randomUUID();
        assertThat(post("/api/lotes", token(), lote(ajeno, "100", "4")).statusCode()).isEqualTo(201);
        long centroAjeno = centro;
        fixture();
        var response = excel("?idCentro=" + centroAjeno, jefe());
        assertThat(response.statusCode()).isEqualTo(200);
        try (var book = new org.apache.poi.xssf.usermodel.XSSFWorkbook(new java.io.ByteArrayInputStream(response.body()))) {
            assertThat(book.getSheet("Recepciones").getLastRowNum()).isZero();
        }
    }

    @Test void excelHasHeadersForEmptyReportAndRejectsInvalidFilters() throws Exception {
        String jwt = jefe();
        var response = excel("?desde=2027-01-01", jwt);
        assertThat(response.statusCode()).isEqualTo(200);
        try (var book = new org.apache.poi.xssf.usermodel.XSSFWorkbook(new java.io.ByteArrayInputStream(response.body()))) {
            var sheet = book.getSheet("Recepciones");
            assertThat(sheet.getLastRowNum()).isZero();
            assertThat(sheet.getRow(0).getLastCellNum()).isEqualTo((short) 15);
        }
        assertThat(excel("?desde=2026-10-16&hasta=2026-10-15", jwt).statusCode()).isEqualTo(400);
    }

    @Test void suppliedFingerprintIsVerifiedAndCanonicalRetryWorks() throws Exception {
        UUID id=UUID.randomUUID();String body=lote(id,"120.50","4");
        String canonical=id+"|"+proveedor+"|"+vehiculo+"|"+usuario+"|"+centro+"|2026-10-15T15:30:00Z|120.5|4|16|1.03";
        String hash=HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(canonical.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        int end=body.lastIndexOf('}');
        String invalid=body.substring(0,end)+",\"huellaSolicitud\":\""+"0".repeat(64)+"\"}";
        assertThat(post("/api/lotes",token(),invalid).statusCode()).isEqualTo(400);
        assertThat(count("lote_leche",id)).isZero();
        String valid=body.substring(0,end)+",\"huellaSolicitud\":\""+hash+"\"}";
        assertThat(post("/api/lotes",token(),valid).statusCode()).isEqualTo(201);
        assertThat(post("/api/lotes",token(),valid).statusCode()).isEqualTo(200);
        assertThat(count("lote_leche",id)).isEqualTo(1);
    }

    @Test void eliasVehiculoInactivoNoGuardaLote() throws Exception {
        String jwt = token();
        UUID anterior = UUID.randomUUID();
        assertThat(post("/api/lotes", jwt, lote(anterior, "100", "4")).statusCode()).isEqualTo(201);

        db.update("UPDATE acopio.vehiculo SET activo=false WHERE id_vehiculo=?", vehiculo);
        UUID nuevo = UUID.randomUUID();
        assertThat(post("/api/lotes", jwt, lote(nuevo, "100", "4")).statusCode()).isEqualTo(400);
        assertThat(count("lote_leche", nuevo)).isZero();
        assertThat(count("registro_calidad", nuevo)).isZero();

        assertThat(get("/api/lotes/" + anterior, jwt).statusCode()).isEqualTo(200);
        assertThat(count("lote_leche", anterior)).isEqualTo(1);
        assertThat(count("registro_calidad", anterior)).isEqualTo(1);
    }

    @Test void eliasReportesYCsvRespetanMedianocheLima() throws Exception {
        String op = token();
        UUID antes = UUID.randomUUID(), inicio = UUID.randomUUID();
        UUID fin = UUID.randomUUID(), siguiente = UUID.randomUUID();
        UUID[] ids = {antes, inicio, fin, siguiente};
        String[] fechas = {
            "2026-10-15T04:59:59Z",
            "2026-10-15T05:00:00Z",
            "2026-10-16T04:59:59Z",
            "2026-10-16T05:00:00Z"
        };

        for (int i = 0; i < ids.length; i++) {
            String solicitud = lote(ids[i], "100", "4")
                .replace("2026-10-15T10:30:00-05:00", fechas[i]);
            assertThat(post("/api/lotes", op, solicitud).statusCode()).isEqualTo(201);
        }

        String jwt = jefe();
        String filtro = "?desde=2026-10-15&hasta=2026-10-15&estado=APROBADO";
        for (String ruta : List.of("/api/reportes", "/api/reportes/csv")) {
            var respuesta = get(ruta + filtro, jwt);
            assertThat(respuesta.statusCode()).as(ruta).isEqualTo(200);
            assertThat(respuesta.body()).as(ruta)
                .contains(inicio.toString(), fin.toString())
                .doesNotContain(antes.toString(), siguiente.toString());
            if (ruta.endsWith("/csv")) {
                assertThat(respuesta.body().lines().filter(l -> !l.isBlank()).count()).isEqualTo(3);
            } else {
                assertThat(respuesta.body()).contains("\"total\":2");
            }
        }
    }
}
