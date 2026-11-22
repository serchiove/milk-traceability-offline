# Registro de evidencias de monitoreo
Completar tras probar el proyecto. No es un acta de aprobación. Si falta una comprobación, conservar su causa y qué hace falta para resolverla.

Fecha y hora (Lima): ___ · Responsable: Elías · Rama: ___ · Commit probado: ___  
Base del ensayo de recepciones: acopio_test · Versión de PostgreSQL: ___ · Java: ___ · Equipo y entorno: ___  
Commit de integración y comprobaciones repetidas allí: ___

| ID | Acción y dato | Resultado esperado | Resultado obtenido y estado | Archivo o captura |
|---|---|---|---|---|
| MON-01 | Tres sondeos al backend de la versión final | HTTP 200, UP, CONECTADO, 9 tablas | Pendiente | |
| MON-02 | Un sondeo a un puerto local libre y otro al correcto | Error de conexión registrado; luego respuesta válida | Pendiente | |
| MON-03 | Registrar una recepción ficticia válida; consultar un conflicto previsto del mismo UUID en la prueba de integración | INFO confirmado y WARN de conflicto; anotar hora, origen y sin datos sensibles | Pendiente | |
| MON-04 | Una alta de calentamiento y 20 altas válidas medidas en acopio_test | 20 HTTP 201 con su UUID; menos de 2 000 ms cada una como criterio del piloto | Pendiente | |
| MON-05 | Revisar memoria y avisos durante el ensayo | 3 lecturas del heap usado/máximo, interpretación y actuación si hay alerta | Pendiente | |
| MON-06 | Contrastar recepciones por calidad de un centro en un período fijo | Los recuentos de UUID únicos coinciden con el reporte del mismo centro y período | Pendiente | |
| MON-07 | Volver a comprobar el sistema integrado | Se identifica el commit final y el resultado de salud/recorrido tras integrar | Pendiente | |

Recepciones válidas: ___/20 · fallidas: ___ · ≥ 2 s: ___ · p95: ___ ms · máximo: ___ ms.  
Incidencia: ___ · Responsable avisado y acción: ___ · Verificación posterior: ___

Para Fernando: entregar enlace al commit, cuadro completado, dos o tres evidencias legibles y el diagrama corregido. Numerar la figura y el cuadro según el orden del informe. Para Sergio: enlace al cambio integrado o al PR si sigue en revisión, y una frase con resultado y pendientes.
