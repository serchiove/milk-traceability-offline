# Aplicación móvil del operario

Responsable: Sergio.

## Implementación inicial del 10 de octubre de 2026
- Formulario con proveedor, vehículo, centro, volumen, temperatura, acidez y densidad.
- Validación de campos obligatorios, números, límites de almacenamiento y precisión decimal.
- Guardado real en SQLite, tabla borrador_lote_v1, separada del diagnóstico existente.
- Identificador UUID v4 estable y fecha de captura por registro.
- Listado local y detalle; lectura al abrir la app.
- Pantalla de conexión al backend conservada.

Son borradores locales. Los nombres/códigos de proveedor y centro todavía se ingresan manualmente: antes de enviar deben resolverse contra catálogos autorizados. No hay usuario autenticado, motor de calidad ni envío de lotes. No se deben convertir estos borradores en peticiones de servidor sin resolver referencias y sesión. Las unidades son L, °C, °D y g/mL.

## Abrir
Desde la raíz del proyecto: Abrir_Movil.cmd. Para consultar el backend por USB, ejecutar Iniciar.cmd y scripts/Conectar-Android.ps1. Expo recarga los cambios; si estaba abierto, usar r en la consola de Metro.

No se ejecutaron pruebas ni comprobaciones automáticas en esta entrega por indicación del usuario. El comportamiento de estas pantallas aún no está confirmado en el celular.

## Ajuste de navegación y márgenes
Se incorporó react-native-safe-area-context para respetar barras y recortes del sistema. El encabezado y las pestañas quedan fuera del área desplazable. Al cambiar de pestaña, abrir un detalle o volver a la lista se restablece el desplazamiento. El botón Atrás de Android vuelve del detalle a la lista y de las pestañas secundarias al formulario; el formulario conserva los campos al navegar. No se ejecutaron pruebas en este ajuste.

## Consulta de registros locales
La lista permite buscar por proveedor, placa, centro o UUID sin distinguir mayúsculas ni tildes. Muestra cantidad y volumen de los resultados visibles; no son indicadores de recepción confirmada ni de capacidad de tanques. La búsqueda no modifica SQLite y puede limpiarse. No se ejecutaron pruebas en este ajuste.

## Pantalla de acceso
La entrada muestra correo, contraseña, mostrar/ocultar, validación y errores. El acceso real está deshabilitado hasta integrar la API. Continuar con borradores locales conserva el desarrollo sin simular una sesión. Contrato propuesto en docs/07_CONTRATO_ACCESO_MOVIL.md. Guardar campos antes de volver al acceso; no se ejecutaron pruebas en esta entrega.

## Pantallas del recorrido
La entrada después del acceso es Inicio, con resumen local acumulado y accesos a captura, listado, pendientes, calidad, trazabilidad, tanque y conexión. Pendientes muestra borradores sin simular una cola de envío operativa. Trazabilidad permite buscar un UUID local exacto y abrir su detalle. Calidad, QR y tanque muestran estados sin datos centrales y explican sus requisitos; no evalúan ni asignan. No hay scanner de cámara ni catálogos remotos todavía.
No se ejecutaron pruebas en esta entrega. Estas pantallas aún requieren revisión en el dispositivo. No equivalen a completar todas las funciones operativas.

## Selectores locales de recepción
Proveedor, vehículo y centro permiten escribir datos o abrir un selector con búsqueda de valores distintos tomados del historial real del dispositivo. Las sugerencias no son catálogos autorizados: aún faltan identificadores oficiales, estado activo y asociación con el centro del usuario. No se incluyen datos ficticios ni se modifica el esquema SQLite. No se ejecutaron pruebas.

## Revisión y salida
Revisar y guardar valida los campos y abre el resumen. Confirmar y guardar persiste en SQLite; Volver a editar conserva el formulario. Durante la escritura se bloquea el cierre de la revisión y la salida al acceso. Volver al acceso con campos sin guardar pide confirmación; el botón Atrás de Android desde Inicio también avisa antes de salir. Cambiar de pestaña conserva los campos en memoria y no pide descartar. Un cierre forzado o reinicio del proceso puede perder campos no guardados: no hay autoguardado del formulario. No se ejecutaron pruebas en este ajuste.

## Pulido visual después del rediseño
Acceso más compacto, iconos Feather uniformes mediante @expo/vector-icons, ayudas con mayor contraste y tamaño, pestañas en columna y filas adaptables. Se simplificaron avisos y se eliminó la afirmación incorrecta de firma digital QR. El volumen se describe como recibido, sin afirmar una descarga física. Los estilos principales están en src/theme/appStyles.ts. Se conserva el almacenamiento y el flujo existente; no se ejecutaron pruebas ni se publicaron cambios.

## Navegación móvil
Se reemplazaron las pestañas superiores por navegación inferior fija. Inicio presenta una acción principal y una lista de seguimiento compacta. Los avisos informativos se pueden expandir; errores y advertencias permanecen visibles. Se redujeron sombras y títulos. Sin cambios de datos o API, sin pruebas ni publicación.

### Referencia visual de Stitch

La interfaz nativa toma como referencia el exportado de Stitch: fondo claro, verde industrial, cabecera compacta, navegación inferior y mediciones en dos columnas. Con letra ampliada o pantallas estrechas, las mediciones usan una columna. Los indicadores muestran datos locales reales; el diseño no habilita autenticación, sincronización, evaluación de calidad ni asignación de tanques.

### Recorrido móvil simplificado

Inicio muestra nueva recepción y los tres últimos registros. El registro usa tres pasos (origen, mediciones, revisión), con validación por paso y conservación de campos al navegar. Registros ofrece búsqueda y actualización deslizando. Perfil reúne conexión, búsqueda por UUID y servicios pendientes. La navegación inferior se oculta durante el registro para centrar la tarea. SQLite y sus registros existentes no se modifican por este rediseño.

### Identidad de Leche Gloria

Paleta inspirada en la marca: azul para navegación, títulos e información; rojo para acciones principales; fondos blancos y azul muy claro. Tipografía sans serif nativa en títulos y contenido (Roboto en Android y fuente del sistema en iOS), sin descargas de fuentes. La identificación GLORIA es texto, no un reemplazo del logotipo oficial.

### Pantalla de preparación

Antes del acceso se prepara SQLite con una pantalla de marca e indicador de actividad. Si falla, permite reintentar sin borrar datos. Su duración depende de la preparación real, sin temporizador artificial; puede aparecer brevemente. Es una pantalla de React Native posterior al arranque de Expo, no un splash nativo independiente.
