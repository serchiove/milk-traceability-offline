$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$local = Join-Path $root '.local'
Write-Host 'Configurar Gmail para el resumen diario de ACOPIO'
Write-Host 'Activa la verificacion en dos pasos y genera una contrasena de aplicacion en tu cuenta Google.'
Write-Host 'No uses tu contrasena habitual de Gmail. Las credenciales se guardaran solo en .local/mail.properties (fuera de Git).'
$valoresAcopio = @{}
$configLocalAcopio = Join-Path $local 'mail.properties'
if (Test-Path $configLocalAcopio) {
  foreach ($lineaAcopio in Get-Content $configLocalAcopio) {
    if ($lineaAcopio -match '^([^#=]+)=(.*)$') { $valoresAcopio[$Matches[1]] = $Matches[2] }
  }
}
$correoAcopio = $valoresAcopio['spring.mail.username']
if (!$correoAcopio) { $correoAcopio = (Read-Host 'Correo Gmail remitente').Trim() }
$destinoAcopio = $null
$centroAcopio = $null
foreach ($llaveAcopio in $valoresAcopio.Keys) {
  if ($llaveAcopio -match '^app\.mail\.centros\.(\d+)\.destinatario$') {
    $centroAcopio = $Matches[1]; $destinoAcopio = $valoresAcopio[$llaveAcopio]; break
  }
}
if (!$centroAcopio) { $centroAcopio = (Read-Host 'ID del centro autorizado').Trim() }
if ($centroAcopio -notmatch '^[1-9]\d*$') { throw 'ID de centro invalido.' }
if (!$destinoAcopio) { $destinoAcopio = (Read-Host 'Correo destinatario autorizado del centro').Trim() }
if ($destinoAcopio -notmatch '^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$') { throw 'Correo destinatario invalido.' }
Write-Host "Remitente: $correoAcopio | Centro: $centroAcopio | Destinatario: $destinoAcopio"
if ($correoAcopio -notmatch '^[a-zA-Z0-9._%+\-]+@gmail\.com$') {
  throw 'Introduce una direccion @gmail.com. Para cuentas institucionales consulta docs/resumen-diario.md.'
}
$claveSegura = Read-Host 'Contrasena de aplicacion de Google (16 letras)' -AsSecureString
$punteroAcopio = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($claveSegura)
try {
  $claveAcopio = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($punteroAcopio).Replace(' ', '')
  if ($claveAcopio -notmatch '^[a-zA-Z]{16}$') { throw 'La contrasena de aplicacion debe contener 16 letras.' }
  New-Item -ItemType Directory -Force -Path $local | Out-Null
  $configuracionAcopio = @"
app.mail.enabled=true
spring.mail.host=smtp.gmail.com
spring.mail.port=587
app.mail.centros.$centroAcopio.destinatario=$destinoAcopio
spring.mail.username=$correoAcopio
spring.mail.password=$claveAcopio
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
spring.mail.properties.mail.smtp.starttls.required=true
"@
  [IO.File]::WriteAllText((Join-Path $local 'mail.properties'), $configuracionAcopio, (New-Object Text.UTF8Encoding($false)))
  Write-Host 'Configuracion guardada. Reinicia el backend para aplicarla. Todavia no se ha enviado ningun correo.'
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($punteroAcopio)
  $claveAcopio = $null
  $configuracionAcopio = $null
  $claveSegura.Dispose()
}
