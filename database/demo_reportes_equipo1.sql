-- ACOPIO / Equipo 1 / Integrador 1 / Universidad Tecnológica del Perú
-- Abrir en Query Tool de la base acopio_dev (127.0.0.1:55440).
-- Datos FICTICIOS para desarrollo. Añade 24 recepciones: 12 aprobadas,
-- 8 rechazadas y 4 pendientes; no borra ni cambia recepciones existentes.
-- Es repetible: los UUID son fijos y una segunda ejecución no duplica datos.
-- Las fechas se distribuyen entre hoy y los últimos 13 días, en hora de Lima.
-- El periodo académico Agosto-2026 de la portada no restringe estas fechas.
-- Carga SQL de demostración: simula las decisiones DEMO-1 y conserva los
-- triggers de QR, incidencias y reserva de tanque. No sustituye la API normal.

BEGIN;
SELECT pg_advisory_xact_lock(hashtext('acopio-demo-equipo1-reportes'));

DO $demo$
DECLARE
  centro bigint;
  operario bigint;
  prov bigint;
  camion bigint;
  tanque_demo bigint;
  lote uuid;
  captura timestamptz;
  volumen numeric;
  temperatura numeric;
  acidez numeric;
  estado text;
  motivo_demo text;
  documento text;
  nombre_demo text;
  i integer;
BEGIN
  IF current_database() <> 'acopio_dev' THEN
    RAISE EXCEPTION 'Ejecuta este script únicamente en acopio_dev';
  END IF;

  SELECT u.id_centro INTO STRICT centro
    FROM acopio.usuario u JOIN acopio.rol r USING(id_rol)
    WHERE lower(u.email)='jefatura@gloria.com.pe'
      AND u.activo AND r.nombre='JEFATURA';
  SELECT u.id_usuario INTO operario
    FROM acopio.usuario u JOIN acopio.rol r USING(id_rol)
    WHERE u.id_centro=centro AND u.activo AND r.nombre='OPERARIO'
    ORDER BY u.id_usuario LIMIT 1;
  IF operario IS NULL THEN
    RAISE EXCEPTION 'Falta un operario activo en el centro de Jefatura';
  END IF;

  FOR i IN 1..3 LOOP
    documento := '9900000' || i;
    nombre_demo := '[DEMO EQUIPO 1] ' || CASE i
      WHEN 1 THEN 'Lechería Sur' WHEN 2 THEN 'Productores del Valle'
      ELSE 'Cooperativa La Campiña' END;
    IF EXISTS (SELECT 1 FROM acopio.proveedor p
        WHERE p.tipo_documento='DNI' AND p.numero_documento=documento
          AND p.razon_social IS DISTINCT FROM nombre_demo) THEN
      RAISE EXCEPTION 'Documento de muestra % ya pertenece a otro proveedor', documento;
    END IF;
    INSERT INTO acopio.proveedor(tipo_documento,numero_documento,razon_social,estado_cert)
      VALUES ('DNI',documento,nombre_demo,'VIGENTE')
      ON CONFLICT(tipo_documento,numero_documento) DO NOTHING;
  END LOOP;

  INSERT INTO acopio.vehiculo(placa,capacidad_litros)
    VALUES ('DEMO-E1-01',5000) ON CONFLICT(placa) DO NOTHING;
  SELECT id_vehiculo INTO STRICT camion FROM acopio.vehiculo WHERE placa='DEMO-E1-01' AND activo;
  INSERT INTO acopio.tanque(id_centro,codigo,capacidad_litros,estado)
    VALUES (centro,'DEMO-E1-TQ01',5000,'DISPONIBLE')
    ON CONFLICT(id_centro,codigo) DO NOTHING;
  SELECT t.id_tanque INTO STRICT tanque_demo FROM acopio.tanque t
    WHERE t.id_centro=centro AND t.codigo='DEMO-E1-TQ01' AND t.estado='DISPONIBLE';

  FOR i IN 1..24 LOOP
    lote := ('e1000001-2026-4000-8000-' || lpad(i::text,12,'0'))::uuid;
    IF EXISTS (SELECT 1 FROM acopio.lote_leche l WHERE l.id_lote=lote) THEN
      IF EXISTS (SELECT 1 FROM acopio.lote_leche l WHERE l.id_lote=lote AND l.id_centro<>centro) THEN
        RAISE EXCEPTION 'Un UUID de muestra pertenece a otro centro';
      END IF;
      CONTINUE;
    END IF;
    SELECT id_proveedor INTO STRICT prov FROM acopio.proveedor
      WHERE tipo_documento='DNI' AND numero_documento='9900000' || (1 + (i-1)%3)
        AND activo;
    captura := (((CURRENT_TIMESTAMP AT TIME ZONE 'America/Lima')::date - ((i-1)%14))
      + make_time(8+(i%8),15,0)) AT TIME ZONE 'America/Lima';
    volumen := 80 + (i*17)%180;
    temperatura := CASE WHEN i%6=1 THEN 12 ELSE 4 END;
    acidez := CASE WHEN i%6=2 THEN 21 ELSE 16 END;
    estado := CASE WHEN i%6=0 THEN 'PENDIENTE'
      WHEN i%6 IN (1,2) THEN 'RECHAZADO' ELSE 'APROBADO' END;
    motivo_demo := CASE WHEN i%6=1 THEN '[DEMO EQUIPO 1] Temperatura fuera del rango DEMO-1 (2 a 8 °C)'
      WHEN i%6=2 THEN '[DEMO EQUIPO 1] Acidez fuera del rango DEMO-1 (14 a 18 °D)' ELSE NULL END;

    INSERT INTO acopio.lote_leche(id_lote,id_proveedor,id_vehiculo,id_usuario,id_centro,
      fecha_hora,recibido_en,volumen_litros,huella_solicitud)
    VALUES (lote,prov,camion,operario,centro,captura,captura+interval '5 minutes',volumen,
      encode(sha256(convert_to(concat_ws('|',lote,prov,camion,operario,centro,
        to_char(captura AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        trim_scale(volumen),trim_scale(temperatura),trim_scale(acidez),'1.03'),'UTF8')),'hex'));
    INSERT INTO acopio.registro_calidad(id_lote,temperatura_c,acidez_dornic,densidad_g_ml)
      VALUES (lote,temperatura,acidez,1.0300);
    IF estado <> 'PENDIENTE' THEN
      UPDATE acopio.registro_calidad SET estado_evaluacion=estado,
        fecha_evaluacion=captura+interval '5 minutes',version_reglas='DEMO-1',motivo=motivo_demo
        WHERE id_lote=lote;
    END IF;
    -- El trigger calcula el contador; no se escribe directamente en el tanque.
    IF estado='APROBADO' AND i%2=0 THEN
      UPDATE acopio.lote_leche SET id_tanque=tanque_demo,
        asignado_en=CURRENT_TIMESTAMP,id_usuario_asigna=operario WHERE id_lote=lote;
    END IF;
  END LOOP;
END
$demo$;

-- Resumen solo de las 24 recepciones de esta muestra.
SELECT r.estado_evaluacion, count(*) AS recepciones, sum(l.volumen_litros) AS litros
FROM acopio.lote_leche l JOIN acopio.registro_calidad r USING(id_lote)
WHERE l.id_lote::text LIKE 'e1000001-2026-4000-8000-%'
GROUP BY r.estado_evaluacion ORDER BY r.estado_evaluacion;

SELECT id_lote,fecha_hora AT TIME ZONE 'America/Lima' AS captura_lima,
  proveedor,volumen_litros,estado_evaluacion,tanque,codigo_qr
FROM acopio.v_trazabilidad
WHERE id_lote::text LIKE 'e1000001-2026-4000-8000-%'
ORDER BY fecha_hora DESC;

COMMIT;
