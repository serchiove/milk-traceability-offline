# Informe de base de datos y pruebas

Responsable: Elías. Fecha de corte: 09 de octubre de 2026.

## Propósito y alcance
PostgreSQL conserva usuarios, origen de las recepciones, lotes, mediciones, evaluación y destino de acopio. Su función es mantener relaciones e integridad, mientras el backend autentica y aplica las reglas de negocio. El esquema físico de nueve entidades ya está incorporado mediante Flyway.

## Modelo implementado
- rol: perfiles y descripción.
- centro_acopio: centro, región, capacidad nominal y disponibilidad.
- usuario: rol, centro de trabajo, identidad, correo, hash de contraseña y disponibilidad.
- proveedor: documento, razón social, estado documental y disponibilidad.
- vehiculo: placa, capacidad nominal y disponibilidad.
- tanque: centro, código, capacidad, volumen reservado y estado.
- lote_leche: UUID, referencias de origen, fechas, volumen, huella, QR y asignación opcional.
- registro_calidad: una medición por lote, temperatura, acidez, densidad, estado, fecha, versión y motivo.
- incidencia: referencia a evaluación rechazada y detalle de alerta.

El modelo contiene 59 columnas. V1 crea tablas, índices, funciones, triggers y v_trazabilidad; V2 incorpora dos roles y un centro ficticio. No crea usuarios de acceso, proveedores ni lotes operativos.
La temperatura se expresa en grados Celsius, acidez en grados Dornic y densidad en g/mL. Las capacidades y volúmenes se expresan en litros. La capacidad nominal del centro o vehículo no equivale a ocupación diaria calculada.

## Integridad ya implementada
Las claves foráneas mantienen referencias. Se controla unicidad de correos sin distinguir mayúsculas, documentos de proveedores, placas y códigos de tanque por centro. Las mediciones excluyen valores nulos o incompatibles con las restricciones básicas; esos límites no son criterios de aprobación sanitaria.
El UUID es la clave de lote. La base conserva los datos originales y prohíbe eliminar lotes o mediciones mediante las operaciones protegidas. La evaluación final es inmutable y el rechazo exige motivo.
Al persistir APROBADO se asigna el contenido ACOPIO seguido del UUID como código QR; esto no genera una imagen QR. Al persistir RECHAZADO se crea la incidencia desde el trigger.
La primera asignación de tanque exige lote aprobado, tanque del mismo centro, estado disponible y capacidad suficiente. El contador de volumen asignado es una reserva técnica; el piloto no modela descarga física, mezclas, vaciado ni reasignación.

## Entorno y archivos
La instancia local usa 127.0.0.1:55440, base y usuario acopio_dev. Los datos y la contraseña permanecen en .local, fuera de Git. Esta instancia no reemplaza las instalaciones existentes del usuario.
La fuente de instalación es backend/src/main/resources/db/migration. database/modelo_original_informe.sql se conserva como referencia y no debe ejecutarse encima del esquema preparado.
Cada modificación posterior requiere nueva migración con versión coordinada con Patricio. No modificar V1 o V2 ya aplicadas ni compartir el directorio pgdata.

## Pruebas disponibles y evidencia
La prueba de integración del backend verificó tablas, columnas y migraciones. En la revisión anterior se ejecutaron casos SQL en una base QA separada, con rollback de los datos de prueba: asignación aprobada, reintento sin doble conteo, bloqueo por capacidad, centro o mantenimiento, bloqueo de pendientes/rechazados, conservación de mediciones y evaluación final, QR e incidencia.
Las capturas del usuario confirman web y móvil consultando el backend y guardado local de diagnóstico. La persistencia SQLite después de cerrar/reabrir queda pendiente. Las pruebas de SQL no demuestran autenticación ni sincronización de la aplicación, que todavía no están implementadas.

## Trabajo que falta
1. Preparar datos ficticios de usuarios con hashes válidos generados por el backend, proveedores, vehículos y tanques.
2. Coordinar migraciones, privilegios y cambios de esquema con Patricio.
3. Mantener una matriz de casos con entrada, acción, resultado esperado, resultado obtenido y evidencia.
4. Probar autenticación por rol/centro, validaciones, recepción atómica, UUID repetido y contenido distinto, calidad y asignación concurrente.
5. Verificar el recorrido móvil a servidor a dashboard y los totales de indicadores.
6. Probar persistencia local, pérdida de conexión, reintento y recuperación después de reinicio cuando la cola offline exista.

## Criterios de aceptación
Las migraciones se aplican en una base nueva y los cambios se agregan sin destruir datos existentes. Un caso inválido no deja escrituras parciales ni altera el saldo. Los resultados se pueden repetir con datos ficticios. Ninguna prueba de negocio debe ejecutarse sobre datos de presentación sin identificar y controlar su impacto.

## Preparación y comprobación
En otra máquina ejecutar scripts/Preparar.ps1 con requisitos instalados. Verificar.cmd consulta el entorno; Probar_Proyecto.cmd ejecuta las comprobaciones de compilación e integración preparadas. Registrar resultados de nuevas pruebas con fecha, sin presentar resultados históricos como ejecuciones recientes.
