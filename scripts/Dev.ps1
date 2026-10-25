param([ValidateSet('Start','Stop','Check','Build','Mobile')][string]$Action='Start',[string]$DeviceId)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$local=Join-Path $root '.local'
New-Item -ItemType Directory -Force $local | Out-Null
# Java 17 es el entorno compartido por Spring Boot y Android.
$javaHome = if ($env:ACOPIO_JAVA_HOME) { $env:ACOPIO_JAVA_HOME }
 elseif (Test-Path 'C:\Program Files\Eclipse Adoptium') {
  (Get-ChildItem -LiteralPath 'C:\Program Files\Eclipse Adoptium' -Directory | Where-Object Name -Like 'jdk-17*' | Sort-Object Name -Descending | Select-Object -First 1).FullName
 } else { $env:JAVA_HOME }
if ($javaHome) {
 $env:JAVA_HOME=$javaHome
 $env:PATH=(Join-Path $javaHome 'bin')+';'+$env:PATH
}
if ($Action -eq 'Mobile') {
 $flutter=(Get-Command flutter.bat -ErrorAction Stop).Source
 $serial=& "$PSScriptRoot/Conectar-Android.ps1" -Serial $DeviceId -PassThru
 Push-Location "$root/mobile-flutter"
 try {
  & $flutter run -d $serial --dart-define=API_BASE_URL=http://127.0.0.1:18080
  if($LASTEXITCODE -ne 0){throw 'No se pudo ejecutar la app Flutter. Revisa el mensaje anterior.'}
 } finally {Pop-Location}
 return
}
$pgBin=if($env:ACOPIO_PG_BIN){$env:ACOPIO_PG_BIN}else{'C:\Program Files\PostgreSQL\18\bin'}
$node=if($env:ACOPIO_NODE){$env:ACOPIO_NODE}else{(Get-Command node.exe).Source}
$java=(Get-Command java.exe).Source
$env:PATH=(Split-Path $node)+';'+$env:PATH
$env:DB_HOST='127.0.0.1';$env:DB_PORT='55440';$env:DB_NAME='acopio_dev';$env:DB_USERNAME='acopio_dev'
if(!(Test-Path "$local/db-password.txt")){throw 'Falta .local/db-password.txt. Ejecuta scripts/Preparar.ps1 primero.'}
$env:DB_PASSWORD=(Get-Content "$local/db-password.txt" -Raw).Trim()
$env:PGPASSWORD=$env:DB_PASSWORD
$env:PGCONNECT_TIMEOUT='5'
$env:SERVER_PORT='18080'
# Generate once per PC; keep outside Git and reuse across backend restarts.
if(!$env:JWT_SECRET){
 $jwtFile=Join-Path $local 'jwt-secret.txt'
 if(!(Test-Path -LiteralPath $jwtFile)){
  $jwtBytes=New-Object byte[] 48
  $jwtGenerator=[System.Security.Cryptography.RandomNumberGenerator]::Create()
  try {$jwtGenerator.GetBytes($jwtBytes)} finally {$jwtGenerator.Dispose()}
  [System.IO.File]::WriteAllText($jwtFile,[Convert]::ToBase64String($jwtBytes))
 }
 $env:JWT_SECRET=([System.IO.File]::ReadAllText($jwtFile)).Trim()
}
function Start-Database {
 & "$pgBin/pg_ctl.exe" -D "$local/pgdata" status *> $null
 if($LASTEXITCODE -ne 0){
  & "$pgBin/pg_ctl.exe" -D "$local/pgdata" -l "$local/postgres.log" -o '-p 55440 -h 127.0.0.1' -w start
  if($LASTEXITCODE -ne 0){throw 'No se pudo iniciar PostgreSQL del proyecto. Revisa .local/postgres.log.'}
 }
 $exists=& "$pgBin/psql.exe" -w -h 127.0.0.1 -p 55440 -U acopio_dev -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='acopio_dev'"
 if($LASTEXITCODE -ne 0){throw 'No se pudo autenticar en PostgreSQL del proyecto.'}
 if($exists -ne '1'){
  & "$pgBin/createdb.exe" -h 127.0.0.1 -p 55440 -U acopio_dev acopio_dev
  if($LASTEXITCODE -ne 0){throw 'No se pudo crear acopio_dev.'}
 }
}
function Build-All {
 Start-Database
 # Integration tests must never write fixtures into the application's development database.
 $env:TEST_DB_NAME='acopio_test'
 $testDatabaseExists=& "$pgBin/psql.exe" -w -h 127.0.0.1 -p 55440 -U acopio_dev -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='acopio_test'"
 if($LASTEXITCODE -ne 0){throw 'No se pudo comprobar la base de pruebas.'}
 if($testDatabaseExists -ne '1'){
  & "$pgBin/createdb.exe" -h 127.0.0.1 -p 55440 -U acopio_dev acopio_test
  if($LASTEXITCODE -ne 0){throw 'No se pudo crear la base aislada acopio_test.'}
 }
 $jar="$root/backend/target/acopio-0.0.1-SNAPSHOT.jar"
 $jarMatch=$jar.Replace('/','\')
 $runningBackends=@(Get-CimInstance Win32_Process -Filter "name='java.exe'" | Where-Object {
  $_.CommandLine -and $_.CommandLine.Contains('-jar') -and $_.CommandLine.Replace('/','\').Contains($jarMatch)
 })
 foreach($backendProcess in $runningBackends){
  Write-Host 'Deteniendo el backend del proyecto para liberar el JAR...'
  $ownedProcess=Get-Process -Id $backendProcess.ProcessId -ErrorAction Stop
  Stop-Process -Id $ownedProcess.Id
  if(!$ownedProcess.WaitForExit(10000)){throw 'El backend no termino; no se puede reemplazar el JAR.'}
 }
 if($runningBackends.Count -gt 0 -and (Test-Path "$local/backend.pid")){Remove-Item -LiteralPath "$local/backend.pid"}
 Push-Location "$root/backend"
 try { & mvn.cmd "-Dmaven.repo.local=$local/m2" --batch-mode verify; if($LASTEXITCODE -ne 0){throw 'Fallo la compilacion, las pruebas o el empaquetado del backend. Revisa el primer ERROR de Maven; el backend queda detenido.'} } finally {Pop-Location}
 if($runningBackends.Count -gt 0){
  Start-Managed 'backend' $java @('-jar',('"'+$jar+'"')) "$root/backend"
  $ready=$false
  for($n=0;$n -lt 40;$n++){
   try{$result=Invoke-RestMethod 'http://127.0.0.1:18080/api/estado' -TimeoutSec 2;if($result.tablas -eq 9){$ready=$true;break}}catch{}
   Start-Sleep -Milliseconds 750
  }
  if(!$ready){throw 'Compilacion completada, pero el backend no reinicio. Revisa .local/backend.log.'}
  Write-Host 'Backend recompilado y disponible nuevamente.'
 }
 Push-Location "$root/dashboard"
 try { & npm.cmd test; if($LASTEXITCODE -ne 0){throw 'Fallaron las pruebas del dashboard.'}; & npm.cmd run build; if($LASTEXITCODE -ne 0){throw 'Fallo el build del dashboard.'} } finally {Pop-Location}
 Push-Location "$root/mobile-flutter"
 try {
  & flutter.bat analyze --no-pub
  if($LASTEXITCODE -ne 0){throw 'Fallo el analisis de Flutter.'}
  & flutter.bat test --no-pub test/connection_test.dart test/services_test.dart test/widget_test.dart test/repository_test.dart test/validation_test.dart
  if($LASTEXITCODE -ne 0){throw 'Fallaron las pruebas de Flutter.'}
  & flutter.bat build apk --debug --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:18080
  if($LASTEXITCODE -ne 0){throw 'Fallo la compilacion Android.'}
 } finally {Pop-Location}
}
function Start-Managed($name,$exe,$arguments,$cwd) {
 $pidFile="$local/$name.pid"
 if(Test-Path $pidFile){
  $savedPid=[int](Get-Content $pidFile)
  $process=Get-CimInstance Win32_Process -Filter "ProcessId=$savedPid" -ErrorAction SilentlyContinue
  if($process -and $process.CommandLine -and $process.CommandLine.Contains($root)){return}
 }
 $p=Start-Process -FilePath $exe -ArgumentList $arguments -WorkingDirectory $cwd -WindowStyle Hidden -PassThru -RedirectStandardOutput "$local/$name.log" -RedirectStandardError "$local/$name.error.log"
 Set-Content -Path $pidFile -Value $p.Id
}
switch($Action){
 'Build' {Build-All}
 'Start' {
  Start-Database
  $jar="$root/backend/target/acopio-0.0.1-SNAPSHOT.jar"
  if(!(Test-Path $jar)){Build-All}
  Start-Managed 'backend' $java @('-jar',('"'+$jar+'"')) "$root/backend"
  $ready=$false
  for($n=0;$n -lt 40;$n++){
   try{$result=Invoke-RestMethod 'http://127.0.0.1:18080/api/estado' -TimeoutSec 2;if($result.tablas -eq 9){$ready=$true;break}}catch{}
   Start-Sleep -Milliseconds 750
  }
  if(!$ready){throw 'API no disponible. Revisa .local/backend.log y backend.error.log.'}
  Start-Managed 'dashboard' $node @(('"'+$root+'/dashboard/node_modules/vite/bin/vite.js"'),'--host','127.0.0.1','--port','5173','--strictPort') "$root/dashboard"
  Write-Host 'Backend: http://127.0.0.1:18080/api/estado'
  Write-Host 'Dashboard: http://127.0.0.1:5173'
 }
 'Check' {
  & $java -version
  & $node --version
  & "$pgBin/pg_ctl.exe" -D "$local/pgdata" status
  Invoke-RestMethod 'http://127.0.0.1:18080/api/estado' | ConvertTo-Json -Depth 5
  Write-Host ('Dashboard HTTP '+(Invoke-WebRequest 'http://127.0.0.1:5173' -UseBasicParsing).StatusCode)
 }
 'Stop' {
  foreach($name in @('dashboard','backend')){
   $pidFile="$local/$name.pid"
   if(Test-Path $pidFile){
    $savedPid=[int](Get-Content $pidFile)
    $process=Get-CimInstance Win32_Process -Filter "ProcessId=$savedPid" -ErrorAction SilentlyContinue
    if($process -and $process.CommandLine -and $process.CommandLine.Contains($root)){Stop-Process -Id $savedPid}
    Remove-Item -LiteralPath $pidFile
   }
  }
  & "$pgBin/pg_ctl.exe" -D "$local/pgdata" -m fast -w stop
 }
}
