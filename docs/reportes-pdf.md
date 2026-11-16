# Reportes PDF de recepciones

El dashboard ofrece **Reportes > Exportar PDF** junto a CSV y Excel. La descarga usa el JWT de la sesión y los filtros actuales `estado`, `desde`, `hasta` y `buscar`.

- `GET /api/reportes/pdf`: requiere JEFATURA; responde `application/pdf` y `attachment; filename=acopio-reporte.pdf`.
- El centro procede exclusivamente de la identidad autenticada. Un parámetro `idCentro` no cambia el alcance.
- Reutiliza `ReporteService.consultar`: fechas inclusivas, validación y máximo de 10 000 recepciones igual que CSV/XLSX.
- JasperReports 7.1.1 compila una vez al arrancar `backend/src/main/resources/reports/recepciones.jrxml`. La plantilla recibe datos autorizados en memoria, sin SQL.
- Formato A4 horizontal con filtros, totales, mediciones, calidad, tanque, código QR textual y páginas. Fechas en America/Lima, fuentes DejaVu incorporadas y mensaje explícito para resultados vacíos.
- Dependencias core, PDF, fonts y JDT fijadas a la misma versión. PDFBox se utiliza únicamente en pruebas para leer el PDF generado.

## Verificación del 11 de noviembre de 2026

- Iniciar.cmd y Verificar.cmd: correctos, PostgreSQL conectado (9 tablas), dashboard HTTP 200.
- Backend: 46 pruebas, 0 fallos, 0 errores, 0 omitidas; base aislada acopio_test. Incluye permisos 401/403, filtros, intento de cambiar centro, PDF vacío, caracteres acentuados, paginación y regresiones CSV/XLSX.
- Dashboard: 11 pruebas correctas y build de Vite correcto.
- JAR empaquetado con mvnw.cmd y reiniciado correctamente.
- Interfaz: inicio de sesión y botón Exportar PDF observados; el evento de descarga de la herramienta de navegador agotó el tiempo, por lo que no se considera comprobada la descarga por clic.
- Descargas autenticadas comprobadas adicionalmente mediante HTTP a través del proxy del dashboard.
- Flutter no se ejecutó ni se modificó en esta tarea. Se conservaron los cambios previos del wrapper y los ajustes locales.

Referencia de JasperReports: https://jasperreports.sourceforge.net/sample.reference/README.html

Verificación final: mvnw.cmd clean verify pasó las 46 pruebas. Se corrigió un método eliminado accidentalmente durante la edición; el build incremental había reutilizado una clase inválida. Tras reconstruir y reiniciar, PDF (37 403 bytes), CSV y XLSX respondieron HTTP 200 mediante el proxy en 5173. La base de desarrollo no tiene recepciones; los casos con datos se probaron en acopio_test.
