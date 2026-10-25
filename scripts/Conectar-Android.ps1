param([string]$Serial,[switch]$PassThru)
$ErrorActionPreference='Stop'
$sdk=if($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
$adb=Join-Path $sdk 'platform-tools\adb.exe'
if(!(Test-Path -LiteralPath $adb)){throw 'No se encuentra adb. Define ANDROID_HOME con la carpeta del SDK.'}
$output=@(& $adb devices)
if($LASTEXITCODE -ne 0){throw 'No se pudo consultar los dispositivos Android.'}
$output | Out-Host
$devices=@($output | ForEach-Object {if($_ -match '^(\S+)\s+device$'){$matches[1]}})
if($Serial){
 if($devices -notcontains $Serial){throw "El dispositivo $Serial no esta conectado o no tiene autorizada la depuracion USB."}
} elseif($devices.Count -eq 1){
 $Serial=$devices[0]
} elseif($devices.Count -eq 0){
 throw 'Conecta un celular con depuracion USB autorizada o inicia un emulador Android.'
} else {
 throw 'Hay varios dispositivos Android. Ejecuta con -Serial ID_DEL_CELULAR para elegir uno.'
}
& $adb -s $Serial reverse tcp:18080 tcp:18080 | Out-Host
if($LASTEXITCODE -ne 0){throw 'No se pudo preparar el enlace USB con la API.'}
Write-Host "API preparada en el dispositivo $Serial. Ejecuta Abrir_Flutter.cmd desde la raiz del proyecto."
if($PassThru){Write-Output $Serial}
