-- Acopio lacteo - modelo fisico de nueve tablas.
-- Ejecutar una sola vez en una base de desarrollo. No elimina objetos existentes.
-- PostgreSQL 13 o superior. Motor de calidad y autorizacion: backend Java.
BEGIN;
CREATE SCHEMA acopio;
SET search_path TO acopio, public;

CREATE TABLE rol (
 id_rol BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador autogenerado del rol.
 nombre VARCHAR(40) NOT NULL UNIQUE, -- Nombre unico del perfil.
 descripcion TEXT NOT NULL -- Responsabilidades del perfil.
);
CREATE TABLE centro_acopio (
 id_centro BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador del centro.
 nombre VARCHAR(120) NOT NULL, -- Nombre del centro de recepcion.
 region VARCHAR(100) NOT NULL, -- Region geografica.
 capacidad_litros NUMERIC(12,2) NOT NULL CHECK (capacidad_litros > 0 AND capacidad_litros <> 'NaN'::numeric), -- Capacidad nominal declarada en litros; no es volumen diario ni saldo calculado.
 activo BOOLEAN NOT NULL DEFAULT TRUE -- Disponibilidad administrativa del centro.
);
CREATE TABLE usuario (
 id_usuario BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador del usuario.
 id_rol BIGINT NOT NULL REFERENCES rol(id_rol) ON DELETE RESTRICT, -- Perfil del usuario.
 id_centro BIGINT NOT NULL REFERENCES centro_acopio(id_centro) ON DELETE RESTRICT, -- Centro de trabajo actual.
 nombre VARCHAR(150) NOT NULL, -- Nombres y apellidos.
 dni VARCHAR(8) NOT NULL UNIQUE CHECK (dni ~ '^[0-9]{8}$'), -- DNI de ocho digitos.
 email VARCHAR(150) NOT NULL CHECK (btrim(email) <> ''), -- Correo de acceso; unicidad sin distinguir mayusculas.
 password_hash VARCHAR(255) NOT NULL CHECK (btrim(password_hash) <> ''), -- Hash de contrasena generado por el backend; nunca texto plano.
 activo BOOLEAN NOT NULL DEFAULT TRUE -- Habilitacion de la cuenta.
);
CREATE UNIQUE INDEX uq_usuario_email ON usuario (lower(email));
CREATE TABLE proveedor (
 id_proveedor BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador del proveedor.
 tipo_documento VARCHAR(3) NOT NULL CHECK (tipo_documento IN ('DNI','RUC')), -- Tipo de documento.
 numero_documento VARCHAR(11) NOT NULL, -- DNI de ocho o RUC de once digitos segun el tipo.
 razon_social VARCHAR(180) NOT NULL, -- Razon social o nombre del proveedor.
 estado_cert VARCHAR(12) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_cert IN ('PENDIENTE','VIGENTE','VENCIDO')), -- Estado documental propuesto; no acredita certificacion por si mismo.
 activo BOOLEAN NOT NULL DEFAULT TRUE, -- Disponibilidad del proveedor para nuevas recepciones.
 UNIQUE (tipo_documento, numero_documento),
 CHECK ((tipo_documento = 'DNI' AND numero_documento ~ '^[0-9]{8}$') OR
        (tipo_documento = 'RUC' AND numero_documento ~ '^[0-9]{11}$'))
);
CREATE TABLE vehiculo (
 id_vehiculo BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador del vehiculo.
 placa VARCHAR(12) NOT NULL UNIQUE CHECK (placa = upper(placa) AND btrim(placa) <> ''), -- Placa en mayusculas sin formato nacional impuesto.
 capacidad_litros NUMERIC(12,2) NOT NULL CHECK (capacidad_litros > 0 AND capacidad_litros <> 'NaN'::numeric), -- Capacidad nominal en litros.
 activo BOOLEAN NOT NULL DEFAULT TRUE -- Disponibilidad administrativa.
);
CREATE TABLE tanque (
 id_tanque BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador del tanque.
 id_centro BIGINT NOT NULL REFERENCES centro_acopio(id_centro) ON DELETE RESTRICT, -- Centro al que pertenece.
 codigo VARCHAR(30) NOT NULL, -- Codigo unico dentro del centro.
 capacidad_litros NUMERIC(12,2) NOT NULL CHECK (capacidad_litros > 0 AND capacidad_litros <> 'NaN'::numeric), -- Capacidad maxima de asignacion en litros.
 volumen_asignado_litros NUMERIC(12,2) NOT NULL DEFAULT 0, -- Contador tecnico mantenido por el trigger de asignacion; no representa descarga fisica.
 estado VARCHAR(15) NOT NULL DEFAULT 'DISPONIBLE' CHECK (estado IN ('DISPONIBLE','MANTENIMIENTO','INACTIVO')), -- Disponibilidad operativa.
 UNIQUE (id_centro, codigo),
 UNIQUE (id_tanque, id_centro),
 CHECK (volumen_asignado_litros BETWEEN 0 AND capacidad_litros)
);
CREATE TABLE lote_leche (
 id_lote UUID PRIMARY KEY, -- UUID generado una sola vez en el movil y reutilizado en cada reintento.
 id_proveedor BIGINT NOT NULL REFERENCES proveedor(id_proveedor) ON DELETE RESTRICT, -- Origen de la leche.
 id_vehiculo BIGINT NOT NULL REFERENCES vehiculo(id_vehiculo) ON DELETE RESTRICT, -- Vehiculo de recepcion.
 id_usuario BIGINT NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT, -- Operario que captura el lote.
 id_centro BIGINT NOT NULL REFERENCES centro_acopio(id_centro) ON DELETE RESTRICT, -- Centro historico de recepcion, independiente del centro actual del usuario.
 fecha_hora TIMESTAMPTZ NOT NULL, -- Fecha y hora de captura con zona horaria.
 recibido_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Fecha y hora de recepcion central.
 volumen_litros NUMERIC(12,2) NOT NULL CHECK (volumen_litros > 0 AND volumen_litros <> 'NaN'::numeric), -- Volumen recibido en litros.
 huella_solicitud VARCHAR(64) NOT NULL CHECK (huella_solicitud ~ '^[0-9a-f]{64}$'), -- SHA256 del contenido canonico calculado por backend; permite detectar UUID reutilizado con cambios.
 codigo_qr VARCHAR(80) UNIQUE, -- Contenido del QR para aprobado; no almacena la imagen. Derivado de UUID.
 id_tanque BIGINT, -- Destino opcional; un solo tanque por lote.
 asignado_en TIMESTAMPTZ, -- Momento de confirmacion del destino.
 id_usuario_asigna BIGINT REFERENCES usuario(id_usuario) ON DELETE RESTRICT, -- Responsable de confirmar el destino.
 FOREIGN KEY (id_tanque, id_centro) REFERENCES tanque(id_tanque, id_centro) ON DELETE RESTRICT,
 CHECK ((id_tanque IS NULL AND asignado_en IS NULL AND id_usuario_asigna IS NULL) OR
        (id_tanque IS NOT NULL AND asignado_en IS NOT NULL AND id_usuario_asigna IS NOT NULL))
);
CREATE TABLE registro_calidad (
 id_registro BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador de las mediciones y su evaluacion.
 id_lote UUID NOT NULL UNIQUE REFERENCES lote_leche(id_lote) ON DELETE RESTRICT, -- Maximo un registro de calidad por lote.
 temperatura_c NUMERIC(6,2) NOT NULL CHECK (temperatura_c >= -273.15 AND temperatura_c <> 'NaN'::numeric), -- Temperatura en grados Celsius; limite fisico, no criterio de aprobacion.
 acidez_dornic NUMERIC(6,2) NOT NULL CHECK (acidez_dornic >= 0 AND acidez_dornic <> 'NaN'::numeric), -- Acidez en grados Dornic; validar unidad con el equipo.
 densidad_g_ml NUMERIC(7,4) NOT NULL CHECK (densidad_g_ml > 0 AND densidad_g_ml <> 'NaN'::numeric), -- Densidad en gramos por mililitro.
 estado_evaluacion VARCHAR(10) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_evaluacion IN ('PENDIENTE','APROBADO','RECHAZADO')), -- PENDIENTE conserva mediciones antes de evaluar.
 fecha_evaluacion TIMESTAMPTZ, -- Nula mientras no exista decision.
 version_reglas VARCHAR(40), -- Version del conjunto de reglas del backend usado para evaluar.
 motivo TEXT, -- Obligatorio para rechazo; opcional para aprobado.
 CHECK ((estado_evaluacion = 'PENDIENTE' AND fecha_evaluacion IS NULL AND version_reglas IS NULL AND motivo IS NULL) OR
        (estado_evaluacion IN ('APROBADO','RECHAZADO') AND fecha_evaluacion IS NOT NULL AND version_reglas IS NOT NULL AND btrim(version_reglas) <> '')),
 CHECK (estado_evaluacion <> 'RECHAZADO' OR (motivo IS NOT NULL AND btrim(motivo) <> ''))
);
CREATE TABLE incidencia (
 id_incidencia BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador de la incidencia.
 id_registro BIGINT NOT NULL REFERENCES registro_calidad(id_registro) ON DELETE RESTRICT, -- Evaluacion que origina la incidencia.
 tipo_alerta VARCHAR(30) NOT NULL CHECK (btrim(tipo_alerta) <> ''), -- Clasificacion definida por backend, por ejemplo CALIDAD.
 descripcion TEXT NOT NULL CHECK (btrim(descripcion) <> ''), -- Motivo o detalle de incumplimiento.
 fecha_hora TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP -- Momento del registro de incidencia.
);

CREATE INDEX ix_usuario_rol ON usuario(id_rol);
CREATE INDEX ix_usuario_centro ON usuario(id_centro);
CREATE INDEX ix_lote_centro_fecha ON lote_leche(id_centro, fecha_hora);
CREATE INDEX ix_lote_proveedor ON lote_leche(id_proveedor);
CREATE INDEX ix_lote_vehiculo ON lote_leche(id_vehiculo);
CREATE INDEX ix_lote_usuario ON lote_leche(id_usuario);
CREATE INDEX ix_lote_tanque ON lote_leche(id_tanque);
CREATE INDEX ix_lote_usuario_asigna ON lote_leche(id_usuario_asigna);
CREATE INDEX ix_calidad_estado ON registro_calidad(estado_evaluacion);
CREATE INDEX ix_incidencia_registro ON incidencia(id_registro);

-- Los lotes de recepcion son inmutables salvo QR y primera asignacion.
CREATE FUNCTION proteger_lote() RETURNS trigger LANGUAGE plpgsql SET search_path = acopio, pg_temp AS $$
BEGIN
 IF TG_OP = 'DELETE' THEN RAISE EXCEPTION 'El piloto conserva los lotes'; END IF;
 IF TG_OP = 'INSERT' THEN
  IF NEW.id_tanque IS NOT NULL OR NEW.codigo_qr IS NOT NULL THEN
   RAISE EXCEPTION 'Registrar primero el lote sin destino ni QR';
  END IF;
  RETURN NEW;
 END IF;
 IF (to_jsonb(NEW) - ARRAY['codigo_qr','id_tanque','asignado_en','id_usuario_asigna']) IS DISTINCT FROM
    (to_jsonb(OLD) - ARRAY['codigo_qr','id_tanque','asignado_en','id_usuario_asigna']) THEN
  RAISE EXCEPTION 'Los datos originales de recepcion no se modifican';
 END IF;
 IF NEW.codigo_qr IS DISTINCT FROM OLD.codigo_qr AND
    (OLD.codigo_qr IS NOT NULL OR NEW.codigo_qr IS DISTINCT FROM ('ACOPIO:' || NEW.id_lote::text) OR
     NOT EXISTS (SELECT 1 FROM registro_calidad WHERE id_lote=NEW.id_lote AND estado_evaluacion='APROBADO')) THEN
  RAISE EXCEPTION 'QR permitido solo para lote aprobado';
 END IF;
 IF OLD.id_tanque IS NOT NULL AND
    ROW(NEW.id_tanque,NEW.asignado_en,NEW.id_usuario_asigna) IS DISTINCT FROM ROW(OLD.id_tanque,OLD.asignado_en,OLD.id_usuario_asigna) THEN
  RAISE EXCEPTION 'El piloto no incluye reasignaciones ni vaciados';
 END IF;
 IF OLD.id_tanque IS NULL AND NEW.id_tanque IS NOT NULL THEN
  IF NOT EXISTS (SELECT 1 FROM registro_calidad WHERE id_lote=NEW.id_lote AND estado_evaluacion='APROBADO') THEN
   RAISE EXCEPTION 'Solo se asignan lotes aprobados';
  END IF;
  -- UPDATE condicional serializa asignaciones concurrentes al mismo tanque.
  UPDATE tanque SET volumen_asignado_litros = volumen_asignado_litros + NEW.volumen_litros
   WHERE id_tanque=NEW.id_tanque AND id_centro=NEW.id_centro AND estado='DISPONIBLE'
     AND volumen_asignado_litros + NEW.volumen_litros <= capacidad_litros;
  IF NOT FOUND THEN RAISE EXCEPTION 'Tanque invalido, no disponible o sin capacidad'; END IF;
  NEW.asignado_en := CURRENT_TIMESTAMP;
 END IF;
 RETURN NEW;
END; $$;
CREATE TRIGGER tr_lote BEFORE INSERT OR UPDATE OR DELETE ON lote_leche FOR EACH ROW EXECUTE FUNCTION proteger_lote();

CREATE FUNCTION proteger_calidad() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='DELETE' THEN RAISE EXCEPTION 'No se eliminan mediciones ni evaluaciones'; END IF;
 IF TG_OP='UPDATE' THEN
  IF OLD.estado_evaluacion <> 'PENDIENTE' THEN RAISE EXCEPTION 'Evaluacion final inmutable'; END IF;
  IF ROW(NEW.id_registro,NEW.id_lote,NEW.temperatura_c,NEW.acidez_dornic,NEW.densidad_g_ml) IS DISTINCT FROM
     ROW(OLD.id_registro,OLD.id_lote,OLD.temperatura_c,OLD.acidez_dornic,OLD.densidad_g_ml) THEN
   RAISE EXCEPTION 'No se modifican mediciones de recepcion';
  END IF;
 END IF;
 RETURN NEW;
END; $$;
CREATE TRIGGER tr_calidad BEFORE UPDATE OR DELETE ON registro_calidad FOR EACH ROW EXECUTE FUNCTION proteger_calidad();

CREATE FUNCTION completar_evaluacion() RETURNS trigger LANGUAGE plpgsql SET search_path = acopio, pg_temp AS $$
BEGIN
 IF NEW.estado_evaluacion='APROBADO' THEN
  UPDATE lote_leche SET codigo_qr='ACOPIO:' || id_lote::text WHERE id_lote=NEW.id_lote;
 ELSIF NEW.estado_evaluacion='RECHAZADO' THEN
  INSERT INTO incidencia(id_registro,tipo_alerta,descripcion) VALUES (NEW.id_registro,'CALIDAD',NEW.motivo);
 END IF;
 RETURN NEW;
END; $$;
CREATE TRIGGER tr_resultado AFTER INSERT OR UPDATE OF estado_evaluacion ON registro_calidad
 FOR EACH ROW EXECUTE FUNCTION completar_evaluacion();

CREATE VIEW v_trazabilidad AS
 SELECT l.id_lote,l.fecha_hora,l.recibido_en,l.id_centro,c.nombre AS centro,
 p.razon_social AS proveedor,v.placa,u.nombre AS operario,l.volumen_litros,
 r.temperatura_c,r.acidez_dornic,r.densidad_g_ml,
 COALESCE(r.estado_evaluacion,'PENDIENTE') AS estado_evaluacion,
 r.fecha_evaluacion,r.version_reglas,r.motivo,l.codigo_qr,t.codigo AS tanque,
 l.asignado_en,l.id_usuario_asigna
 FROM lote_leche l JOIN centro_acopio c USING(id_centro)
 JOIN proveedor p USING(id_proveedor) JOIN vehiculo v USING(id_vehiculo)
 JOIN usuario u ON u.id_usuario=l.id_usuario
 LEFT JOIN registro_calidad r USING(id_lote) LEFT JOIN tanque t ON t.id_tanque=l.id_tanque;

COMMENT ON SCHEMA acopio IS 'Piloto academico de nueve entidades; no incluye vaciados ni mezclas';
COMMENT ON TABLE tanque IS 'volumen_asignado_litros es una desnormalizacion controlada para reserva concurrente';
COMMENT ON TABLE registro_calidad IS 'Conserva mediciones pendientes; decision unica e inmutable al evaluar';
COMMENT ON COLUMN registro_calidad.version_reglas IS 'Identificador de configuracion versionada conservada por el backend, no una FK';
COMMENT ON COLUMN lote_leche.huella_solicitud IS 'Comparar huella en reintentos; UNIQUE UUID evita duplicados pero no valida contenido por si solo';
COMMIT;

-- CONTRATO JAVA OBLIGATORIO
-- 1. Registrar lote + registro_calidad PENDIENTE en la misma transaccion.
-- 2. ON CONFLICT(id_lote) DO NOTHING; despues consultar y comparar huella.
--    Misma huella: confirmar original. Distinta huella: rechazar conflicto.
-- 3. Evaluar parametros con reglas versionadas del backend; no usar rangos ficticios en produccion.
-- 4. UPDATE calidad WHERE estado_evaluacion='PENDIENTE'; verificar filas afectadas.
-- 5. Asignar tanque con UPDATE lote; el trigger valida y reserva en la misma transaccion.
-- 6. Autorizacion y usuario activo se verifican en API; id_usuario no autentica una peticion.
-- 7. Cuenta de aplicacion distinta del propietario: sin DELETE, TRUNCATE ni alteracion de triggers;
--    sin UPDATE directo del contador de tanque. Asignar permisos minimos por columna.
-- 8. Administracion: no cambiar centro/capacidad nominal de tanques usados; no escribir contador.
-- 9. Centro.capacidad y vehiculo.capacidad son datos nominales; no se modelan viajes ni aforo global.
