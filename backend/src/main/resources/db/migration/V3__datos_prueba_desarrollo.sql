-- Datos semilla de desarrollo para pruebas de autenticacion y recepcion de lotes.
SET search_path TO acopio, public;

-- 1. Usuarios de prueba (Contraseña para ambos: 123456)
INSERT INTO acopio.usuario (id_rol, id_centro, nombre, dni, email, password_hash, activo)
VALUES (
    (SELECT id_rol FROM acopio.rol WHERE nombre = 'OPERARIO'),
    (SELECT id_centro FROM acopio.centro_acopio WHERE nombre = 'Centro de prueba académico'),
    'Juan Pérez',
    '45678912',
    'operario@gloria.com.pe',
    '$2a$10$W2neF9.6Agi6kAKVq8q3fec5dHW8KUA.b0VSIGdIZyUawGceP6yGq',
    TRUE
),
(
    (SELECT id_rol FROM acopio.rol WHERE nombre = 'JEFATURA'),
    (SELECT id_centro FROM acopio.centro_acopio WHERE nombre = 'Centro de prueba académico'),
    'María Gómez',
    '41234567',
    'jefatura@gloria.com.pe',
    '$2a$10$W2neF9.6Agi6kAKVq8q3fec5dHW8KUA.b0VSIGdIZyUawGceP6yGq',
    TRUE
);

-- 2. Proveedor de prueba
INSERT INTO acopio.proveedor (tipo_documento, numero_documento, razon_social, estado_cert, activo)
VALUES ('RUC', '20100190797', 'Establo Lechero Los Andes S.A.C.', 'VIGENTE', TRUE);

-- 3. Vehículo cisterna de prueba
INSERT INTO acopio.vehiculo (placa, capacidad_litros, activo)
VALUES ('V1A-450', 5000.00, TRUE);

-- 4. Tanque disponible en el centro de prueba
INSERT INTO acopio.tanque (id_centro, codigo, capacidad_litros, estado)
VALUES (
    (SELECT id_centro FROM acopio.centro_acopio WHERE nombre = 'Centro de prueba académico'),
    'TQ-01',
    5000.00,
    'DISPONIBLE'
);