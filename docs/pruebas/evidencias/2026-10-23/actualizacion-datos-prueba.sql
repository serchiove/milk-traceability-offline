BEGIN;

INSERT INTO acopio.lote_leche
(id_lote, id_proveedor, id_vehiculo, id_usuario, id_centro, fecha_hora, volumen_litros, huella_solicitud)
VALUES
('5d00fabe-5614-49da-9f28-515912dd35b2', 1, 1, 1, 1, CURRENT_TIMESTAMP, 100, repeat('a',64)),
('a2acd681-f1a1-4549-a815-b566da78e8c3', 1, 1, 1, 1, CURRENT_TIMESTAMP, 50, repeat('b',64));

INSERT INTO acopio.registro_calidad
(id_lote, temperatura_c, acidez_dornic, densidad_g_ml, estado_evaluacion, fecha_evaluacion, version_reglas, motivo)
VALUES
('5d00fabe-5614-49da-9f28-515912dd35b2', 4, 16, 1.0300, 'APROBADO', CURRENT_TIMESTAMP, 'PRUEBA-MIGRACION', NULL),
('a2acd681-f1a1-4549-a815-b566da78e8c3', 20, 16, 1.0300, 'RECHAZADO', CURRENT_TIMESTAMP, 'PRUEBA-MIGRACION', 'Temperatura fuera del rango del piloto');

UPDATE acopio.lote_leche
SET id_tanque = 1, asignado_en = CURRENT_TIMESTAMP, id_usuario_asigna = 1
WHERE id_lote = '5d00fabe-5614-49da-9f28-515912dd35b2';

COMMIT;

SELECT id_lote, volumen_litros, estado_evaluacion, tanque
FROM acopio.v_trazabilidad ORDER BY id_lote;

SELECT codigo, volumen_asignado_litros FROM acopio.tanque;
SELECT COUNT(*) AS incidencias FROM acopio.incidencia;
