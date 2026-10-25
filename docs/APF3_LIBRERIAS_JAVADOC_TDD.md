# Librerías documentación y pruebas del tercer avance

Ampliamos los reportes con Excel y usamos las cuatro librerías solicitadas en funciones del backend. Esta entrega se desarrolla en `sergio/apf3-reportes-documentacion`, a partir de `main` en `a59788d`. Conservamos el aporte web de Fernando mediante el cherry-pick de `73a9294` como `7da8c00`; la autoría original permanece en Git.

## Uso de las librerías

| Librería | Uso implementado | Cómo lo verificamos |
|---|---|---|
| Guava 33.7.2-jre | `LoteService` calcula SHA-256 sobre la misma representación canónica de la recepción. | La prueba backend usa `MessageDigest` como referencia independiente; la suite móvil conserva el mismo contrato. |
| Apache POI 6.0.0 | `ExportadorReporte` genera XLSX con mediciones numéricas, encabezados, filtros y cabecera inmovilizada. | Abrimos el archivo con POI y comprobamos filas, tipos, permisos, filtros y aislamiento por centro. |
| Apache Commons CSV 1.14.1 | `ExportadorReporte` escribe CSV con comillas, separadores y saltos de línea. | Leemos nuevamente el CSV y verificamos texto con comas, comillas, acentos, saltos y prefijos de fórmulas. |
| Logback, versión administrada por Spring Boot | Eventos `recepcion_confirmada`, `recepcion_conflictiva` y `reporte_generado`. | Una prueba HTTP captura el logger real y exige que un rollback no registre una recepción como confirmada. |

La versión de POI utilizada requiere Java 17, igual que el backend. El XLSX conserva como texto las cadenas que parecen fórmulas; el CSV añade un apóstrofo cuando corresponde. Las mediciones numéricas siguen siendo números. No cambiamos la representación canónica de los UUID, instantes ni decimales al sustituir el cálculo de SHA-256 por Guava.

## Consultar y exportar

Desde el dashboard iniciamos sesión con una cuenta JEFATURA, abrimos **Reportes**, aplicamos los filtros y elegimos **Exportar CSV** o **Exportar Excel**. Ambos formatos consultan el mismo servicio y el centro autenticado.

| Ruta | Permiso | Resultado |
|---|---|---|
| `GET /api/reportes` | JEFATURA | Indicadores y registros JSON |
| `GET /api/reportes/csv` | JEFATURA | `acopio-reporte.csv` |
| `GET /api/reportes/xlsx` | JEFATURA | `acopio-reporte.xlsx` |

Los tres aceptan `estado`, `desde`, `hasta` y `buscar`. El límite es de 10000 registros por reporte. Sin autenticación se responde 401; OPERARIO recibe 403 en las exportaciones. Un parámetro `idCentro` no amplía los datos autorizados por el JWT. Un resultado vacío conserva los encabezados del archivo.

## Ciclo TDD realizado

| Etapa | Commit | Resultado registrado |
|---|---|---|
| Rojo | `455200c` | Tres pruebas nuevas compilan y fallan: esperan 200 para JEFATURA y reciben 403 porque todavía no existe la exportación. |
| Verde | `71709df` | Implementamos el XLSX mínimo y las tres pruebas pasan. |
| Refactorización | `732dd39` | Extraemos `ExportadorReporte`, compartimos columnas y añadimos Commons CSV. La suite completa pasa con 39 pruebas. |

Los registros están en [rojo](evidencias/tdd/01-rojo.txt), [verde](evidencias/tdd/02-verde.txt) y [refactorización](evidencias/tdd/03-refactorizacion.txt). El cambio posterior incorpora una prueba de Logback y eleva el total a 40. Esta evidencia acredita TDD en la exportación nueva; no atribuimos retroactivamente ese proceso a todo el proyecto.

Para repetir solo las pruebas del ciclo, desde `backend` y con PostgreSQL de pruebas configurado:

```powershell
mvn '-Dtest=BackendFlowTests#excel*' test
```

Las variables `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD` y `TEST_DB_NAME` deben apuntar a un entorno de pruebas. `DB_PASSWORD` no se incluye en comandos registrados ni en el repositorio.

## Javadoc

Documentamos las responsabilidades de los paquetes y las clases principales, así como parámetros, retornos y errores de los casos de uso. Generamos la documentación con Java 17 y el plugin Maven Javadoc 3.12.0:

```powershell
cd backend
mvn javadoc:javadoc
Start-Process .\target\site\apidocs\index.html
```

La generación produjo 199 archivos HTML y comprobamos en el navegador la página de `ExportadorReporte`, sus métodos y enlaces. El contenido generado está en `target`, fuera de Git; se reproduce con el comando anterior. La configuración valida errores de documentación y omite los avisos por miembros todavía sin comentario. No afirmamos que todos los getters y constructores tengan documentación individual.

En Windows fijamos UTF-8 en `backend/.mvn/jvm.config` para que los comentarios y la caché de Javadoc conserven los acentos en generaciones sucesivas.

## Logs

`logback-spring.xml` escribe en consola y en `.local/logs/acopio.log`, relativo al directorio de trabajo del backend. `ACOPIO_LOG_DIR` permite cambiar el destino. Conservamos siete días de archivos rotados. Los eventos incluyen UUID o cantidad de filas y formato, sin cuerpos de solicitudes, credenciales, JWT ni huellas completas.

La recepción confirmada se registra después del commit. Estos logs son diagnóstico técnico; no sustituyen una bitácora durable de auditoría de usuarios.

## Resultados y evidencia

La revisión del 23/10/2026 utilizó PostgreSQL 18 en una instancia aislada, puerto 55449, base `acopio_test_apf3`. No usamos los datos de desarrollo. El backend de comprobación se inició en 18089 y el dashboard en 5179; los puertos habituales del proyecto siguen siendo 18080 y 5173. `ACOPIO_API_TARGET` permite configurar el proxy de Vite para esta comprobación.

- Backend: 40 pruebas aprobadas, cero fallos y cero errores; JAR generado.
- La verificación móvil actual se documenta en [las pruebas Flutter](../mobile-flutter/docs/VERIFICACION.md).
- Dashboard: compilación correcta y comprobación en navegador de login, carga de datos, filtro de aprobados y descarga CSV/XLSX.
- Javadoc: generación correcta, páginas HTML localizadas y navegación comprobada.

Vinculamos los resúmenes en [verificación final](evidencias/04-verificacion-final.txt). Las capturas están en [Excel filtrado](evidencias/capturas/reportes-excel-filtrado.png) y [Javadoc](evidencias/capturas/javadoc.png). Las [muestras CSV y XLSX](evidencias/muestras/) proceden de peticiones HTTP reales con datos ficticios; el proveedor de prueba contiene texto parecido a una fórmula para verificar el tratamiento seguro.

La evidencia backend de este documento corresponde al 23/10/2026. El recorrido posterior con teléfono físico, backend y dashboard del 24/10/2026 está documentado en [Evidencias del recorrido](../mobile-flutter/docs/EVIDENCIAS_RECORRIDO.md). El estado de publicación y fusión se consulta en Git.
