-- Solo lectura. Cambiar fecha y centro ficticio a los consultados en el reporte.
-- Usar la misma base que el reporte y una cuenta de prueba autorizada.
WITH filtro AS (
  SELECT DATE '2026-11-22' AS dia, 1 AS centro
)
SELECT coalesce(q.estado_evaluacion::text, 'PENDIENTE') AS estado,
       count(DISTINCT l.id_lote) AS lotes
FROM acopio.lote_leche AS l
CROSS JOIN filtro AS f
LEFT JOIN acopio.registro_calidad AS q ON q.id_lote = l.id_lote
WHERE l.id_centro = f.centro
  AND l.fecha_hora >= (f.dia::timestamp AT TIME ZONE 'America/Lima')
  AND l.fecha_hora < ((f.dia + 1)::timestamp AT TIME ZONE 'America/Lima')
GROUP BY 1
ORDER BY 1;
