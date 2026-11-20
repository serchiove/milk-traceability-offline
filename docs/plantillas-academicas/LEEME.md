> **Estado actualizado al 20/11/2026:** las plantillas `01_PDF_academico.jrxml` y
> `03_PowerPoint_academico.jrxml` ya están conectadas a las descargas del dashboard.
> `04_Resumen_diario.jrxml` genera el PDF diario y el adjunto del correo.
> `02_Excel_academico.jrxml` sigue siendo un diseño para Studio: Excel se descarga con Apache POI.
> Maven copia las plantillas utilizadas al compilar; guardar cambios requiere recompilar y reiniciar.
> Las notas posteriores sobre “integración futura” describen la preparación histórica de las muestras.

# Integración activa del PDF y PowerPoint (13/11/2026)

El dashboard ya dispone de Exportar PDF y Exportar PowerPoint. El backend utiliza directamente 01_PDF_academico.jrxml y 03_PowerPoint_academico.jrxml de esta carpeta: Maven los copia al JAR en reports/academicas. Cambiar el diseño en Studio requiere guardar, recompilar el backend y reiniciarlo. F5 en Studio refresca el editor; no recompila el backend.

El servicio entrega los datos autorizados en memoria, reemplazando la consulta CSV usada para Preview. Centro, filtros, mediciones y totales proceden de ReporteService; nunca se toma el centro del CSV. Cada recepción genera una ficha PPTX, además de portada y resumen. Un resultado vacío conserva portada y mensaje explícito.

La plantilla Excel de esta carpeta sigue siendo un diseño de Studio; la exportación Excel del dashboard conserva su exportador anterior. CSV conserva su comportamiento. La plantilla antigua backend/src/main/resources/reports/recepciones.jrxml queda sin uso por el exportador PDF actual.

Los datos académicos se editan en Parameters > Default Value Expression. Los parámetros centro, filtros y generado se sustituyen al descargar. No cambies los nombres de campos sin adaptar el mapeo Java.

---

# ACOPIO: tres diseños académicos para Jaspersoft Studio

## Qué está preparado

- 01_PDF_academico.jrxml: A4 vertical, portada académica y tabla de recepciones con total de litros.
- 02_Excel_academico.jrxml: cabecera académica y tabla de nueve columnas. Volumen y temperatura son valores numéricos. Para XLSX se genera sin paginación.
- 03_PowerPoint_academico.jrxml: formato 16:9, portada, una ficha por recepción y resumen final. La muestra tiene cinco diapositivas.
- muestra.csv: tres recepciones totalmente ficticias. No tiene encabezado: el orden se define en la propiedad net.sf.jasperreports.csv.column.names.

Estos diseños son independientes de la plantilla productiva recepciones.jrxml. Aún no reemplazan las descargas del dashboard ni añaden su botón PowerPoint. No se inició la base de datos ni el proyecto.

## Abrir el proyecto

1. Inicia Jaspersoft Studio.exe desde la carpeta extraída.
2. Elige tu workspace habitual.
3. File > Import > General > Existing Projects into Workspace > Next.
4. En Select root directory selecciona esta carpeta (la que contiene .project y los tres .jrxml).
5. Deja desmarcado Copy projects into workspace si quieres editar los archivos en esta misma ubicación. Pulsa Finish.
6. Expande ACOPIO_Plantillas_Academicas en Project Explorer y abre uno de los .jrxml.
7. Selecciona la pestaña Design. Si se abre como texto: clic derecho > Open With > JasperReports Editor.

## Cambiar los datos de portada

En Outline > Parameters selecciona universidad, curso, docente, equipo, periodo o titulo. En Properties cambia Default Value Expression. Escribe textos Java entre comillas, por ejemplo: "Curso de Calidad de Software". No cambies el nombre del parámetro.

También existen centro y filtros para el encabezado de la muestra. Son datos ficticios; cuando se conecte al backend deberán ser reemplazados por el centro autenticado y sus filtros reales.

## Cambiar el diseño visual

- Selecciona un elemento en Design para moverlo o ajustar tamaño, posición, fuente, color y alineación en Properties.
- Para textos fijos (como EQUIPO DE TRABAJO), usa doble clic o la propiedad Text.
- Para elementos dinámicos conserva expresiones $P{...}, $F{...} y $V{...}; el texto lo aportan parámetros, filas y totales.
- En Outline > Styles > Base cambia la fuente o color general. Algunos títulos tienen color/tamaño propio: selecciónalos para cambiarlos.
- Palette > Image permite añadir tu logo. Usa un recurso dentro del proyecto y conserva la proporción. No se incluyó ningún logo institucional sin autorización o archivo original.
- PDF: Title es la portada; Page Header, Column Header y Detail forman el detalle. Summary contiene los totales.
- Excel: conserva bordes de columna alineados entre encabezado y detalle para evitar celdas combinadas innecesarias. Mantén BigDecimal en volumen y temperatura. Selecciona XLSX para exportar.
- PowerPoint: Title es la portada, Detail la ficha que se repite por recepción y Summary el resumen. Mantén texto dentro de los márgenes. Para una presentación más corta, habrá que cambiar las fichas por tablas agrupadas antes de conectar grandes reportes.

## Preview con datos ficticios

Las plantillas contienen una consulta de tipo CSV y la ruta local del archivo muestra.csv. No hace falta configurar PostgreSQL.

1. Abre Preview. Usa la ejecución de la consulta CSV sin un adaptador que la sustituya por registros vacíos (No Data Adapter / Don't use a Data Adapter, según versión).
2. Si Studio solicita datos, abre Dataset and Query y confirma el lenguaje CSV. La propiedad net.sf.jasperreports.csv.source debe apuntar al archivo muestra.csv de esta carpeta.
3. Si moviste la carpeta, corrige esa ruta desde Properties > Advanced > Properties o en la pestaña Source. La muestra usa UTF-8, comas, salto LF y decimales con punto (locale en_US).
4. Selecciona PDF, XLSX o PPTX como salida. Para Excel activa Ignore Pagination y Detect Cell Type en las opciones de exportación.
5. Puedes cambiar los valores de parámetros al ejecutar Preview o editar sus valores predeterminados.

## Comprobación realizada

Las tres fuentes se compilaron y llenaron mediante JasperReports 7.1.1, la versión del backend. PDF de 2 páginas; Excel de una hoja, con 7 celdas numéricas (6 mediciones y total); PPTX con 5 diapositivas. Total ficticio: 300.75 litros. Se inspeccionaron las vistas PDF renderizadas; el XLSX y PPTX se reabrieron con Apache POI para comprobar su estructura. No se afirma una revisión dentro de Microsoft Office o de Studio.

Studio instalado: 7.0.8. Se usó sintaxis JRXML 7 común; si Studio informa una incompatibilidad al abrir, conserva el mensaje para revisar el ajuste antes de guardar cambios.

## Para integrarlos posteriormente

El backend deberá llenar cada plantilla con el conjunto autorizado de ReporteService, sustituyendo la consulta CSV de demostración con un JRDataSource en memoria. Se deben conservar autenticación, centro, filtros, tipos numéricos, límite de registros y protección contra fórmulas en las salidas tabulares. Se necesita adaptar los nombres de campos y conectar JRXlsxExporter y JRPptxExporter, más el endpoint y botón PPTX. Guardar estos diseños por sí solo todavía no cambia el dashboard.

## Rediseño del 13 de noviembre de 2026

Se mantienen los colores originales de ACOPIO (#14634D, #213D37 y #E4F0E9). PDF: portada institucional, tabla con cabecera verde y bloque de totales. Excel: fila de títulos verde, filas alternadas y total numérico destacado. PowerPoint: portada asimétrica, fichas de recepción y resumen con cifras grandes. Los parámetros y nombres de campos se conservan. Para ver los cambios en Studio, selecciona el proyecto y pulsa F5; si un editor conserva una versión antigua, ciérralo sin guardar esa versión y vuelve a abrir el JRXML.

Los tres diseños se compilaron y exportaron con JasperReports. Las muestras contienen 3 recepciones ficticias, 300.75 litros, 2 aprobadas y 1 rechazada. No se inició el backend ni PostgreSQL; estos diseños siguen pendientes de conexión al dashboard.

