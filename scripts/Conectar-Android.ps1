param([string]$Serial)
$ErrorActionPreference='Stop'
$sdk=if($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
$adb=Join-Path $sdk 'platform-tools\adb.exe'
if(!(Test-Path $adb)){throw 'No se encuentra adb. Define ANDROID_HOME con la carpeta del SDK.'}
$target=@();if($Serial){$target=@('-s',$Serial)}
& $adb devices
& $adb @target reverse tcp:18080 tcp:18080
if($LASTEXITCODE -ne 0){throw 'Conecta un dispositivo autorizado o inicia un emulador. Si hay varios, usa -Serial.'}
& $adb @target reverse tcp:8081 tcp:8081
if($LASTEXITCODE -ne 0){throw 'No se pudo preparar el puerto de Expo.'}
Write-Host 'Puertos preparados. Abre Abrir_Movil.cmd y pulsa a con el dispositivo conectado.'
