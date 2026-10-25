param([string]$Device,[switch]$Usb)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
 if(!$Device){& flutter devices;throw 'Ejecuta de nuevo con -Device ID. Agrega -Usb para un celular conectado por cable.'}
 $api='http://10.0.2.2:18080'
 if($Usb){
  $adb=Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
  if(!(Test-Path $adb)){$adb=(Get-Command adb.exe).Source}
  & $adb -s $Device reverse tcp:18080 tcp:18080
  if($LASTEXITCODE -ne 0){throw 'No se pudo establecer el enlace USB.'}
  $api='http://127.0.0.1:18080'
 }
 & flutter run -d $Device "--dart-define=API_BASE_URL=$api"
 if($LASTEXITCODE -ne 0){throw 'Flutter no pudo iniciar la aplicación.'}
}finally{Pop-Location}
