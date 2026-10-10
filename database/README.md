# Base de datos

`modelo_original_informe.sql` conserva el modelo del informe como referencia.
La instalación de la aplicación se realiza exclusivamente con Flyway en `backend/src/main/resources/db/migration`.
No ejecutar el SQL de referencia encima de la base preparada, ni editar V1/V2 ya aplicadas. Acordar con el equipo y crear una nueva migración para cada cambio.
La instancia y contraseña de cada computadora permanecen en `.local`, fuera del código compartido.
