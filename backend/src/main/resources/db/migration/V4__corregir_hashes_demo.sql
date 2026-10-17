-- Correccion exclusiva de las cuentas ficticias introducidas en V3.
-- No restablece contrasenas modificadas por el usuario. Clave SOLO desarrollo: 123456.
UPDATE acopio.usuario
SET password_hash = '$2a$10$Ksi1KT146mzVpvDeBW3lM.f9yAUBSMQmpkt.VfmjMN3HQDD4waNQa'
WHERE email IN ('operario@gloria.com.pe', 'jefatura@gloria.com.pe')
  AND password_hash = '$2a$10$W2neF9.6Agi6kAKVq8q3fec5dHW8KUA.b0VSIGdIZyUawGceP6yGq';
