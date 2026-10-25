param([string]$PgBin='C:\Program Files\PostgreSQL\18\bin',[int]$Port=18081,[int]$PgPort=55441)
$ErrorActionPreference='Stop'
$appRoot=Split-Path $PSScriptRoot -Parent
$repoRoot=Split-Path $appRoot -Parent
$work=Join-Path $appRoot '.local'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$jar=Join-Path $repoRoot 'backend\target\acopio-0.0.1-SNAPSHOT.jar'
if(!(Test-Path -LiteralPath $jar)){throw 'Falta el JAR del backend. Proporciona el backend existente compilado antes de ejecutar esta prueba.'}
if(Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue){throw "El puerto $Port esta ocupado; elige otro con -Port."}
if(Get-NetTCPConnection -State Listen -LocalPort $PgPort -ErrorAction SilentlyContinue){throw "El puerto PostgreSQL $PgPort esta ocupado; elige otro con -PgPort."}
$names=@('DB_HOST','DB_PORT','DB_NAME','DB_USERNAME','DB_PASSWORD','JWT_SECRET','SERVER_PORT','PGPASSWORD','ACOPIO_TEST_API')
$old=@{}; foreach($name in $names){$old[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
$testDb='acopio_flutter_test_'+[Guid]::NewGuid().ToString('N').Substring(0,12)
$created=$false;$server=$null;$pgStarted=$false
$cluster=Join-Path $work ('pg-contract-'+[Guid]::NewGuid().ToString('N').Substring(0,12))
try {
 $env:DB_HOST='127.0.0.1';$env:DB_PORT=[string]$PgPort;$env:DB_USERNAME='acopio_test_owner'
 $passwordBytes=New-Object byte[] 32;$random=[Security.Cryptography.RandomNumberGenerator]::Create()
 try{$random.GetBytes($passwordBytes)}finally{$random.Dispose()}
 $env:DB_PASSWORD=[Convert]::ToBase64String($passwordBytes)
 $pwFile=Join-Path $work 'contract-pg-password.txt';[IO.File]::WriteAllText($pwFile,$env:DB_PASSWORD)
 & "$PgBin\initdb.exe" -D $cluster -U $env:DB_USERNAME "--pwfile=$pwFile" --auth=scram-sha-256 --encoding=UTF8 --locale=C *> "$work\contract-initdb.log"
 if($LASTEXITCODE -ne 0){throw 'No se pudo inicializar PostgreSQL de pruebas.'}
 & "$PgBin\pg_ctl.exe" -D $cluster -l "$work\contract-postgres.log" -o "-p $PgPort -h 127.0.0.1" -w start
 if($LASTEXITCODE -ne 0){throw 'No se pudo iniciar PostgreSQL de pruebas.'}
 $pgStarted=$true
 $env:PGPASSWORD=$env:DB_PASSWORD
 & "$PgBin\createdb.exe" -w -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USERNAME $testDb
 if($LASTEXITCODE -ne 0){throw 'No se pudo crear la base temporal; no se ejecuta ninguna prueba.'}
 $created=$true;$env:DB_NAME=$testDb;$env:SERVER_PORT=[string]$Port
 $bytes=New-Object byte[] 48;$rng=[Security.Cryptography.RandomNumberGenerator]::Create()
 try{$rng.GetBytes($bytes)}finally{$rng.Dispose()}
 $env:JWT_SECRET=[Convert]::ToBase64String($bytes)
 $java=(Get-Command java.exe).Source
 $server=Start-Process -FilePath $java -ArgumentList @('-jar',('"'+$jar+'"')) -WorkingDirectory $appRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput "$work\contract-backend.log" -RedirectStandardError "$work\contract-backend.error.log"
 $ready=$false
 for($n=0;$n -lt 40;$n++){
  if($server.HasExited){throw 'El backend temporal termino. Revisa .local/contract-backend.log.'}
  try{$state=Invoke-RestMethod "http://127.0.0.1:$Port/api/estado" -TimeoutSec 1;if($state.tablas -eq 9){$ready=$true;break}}catch{}
  Start-Sleep -Milliseconds 500
 }
 if(!$ready){throw 'El backend temporal no inicio a tiempo.'}
 $env:ACOPIO_TEST_API="http://127.0.0.1:$Port"
 Push-Location $appRoot
 try {& flutter test test/live_contract_test.dart --reporter expanded; if($LASTEXITCODE -ne 0){throw 'Fallo el contrato Flutter/Spring Boot.'}}finally{Pop-Location}
} finally {
 if($server -and !$server.HasExited){Stop-Process -Id $server.Id;$server.WaitForExit(10000) | Out-Null}
 if($created -and $testDb -match '^acopio_flutter_test_[0-9a-f]{12}$'){
  & "$PgBin\dropdb.exe" -w -h '127.0.0.1' -p $PgPort -U acopio_test_owner $testDb
  if($LASTEXITCODE -ne 0){Write-Warning "No se pudo retirar la base temporal $testDb"}
 }
 if($pgStarted){& "$PgBin\pg_ctl.exe" -D $cluster -m fast -w stop}
 foreach($name in $names){[Environment]::SetEnvironmentVariable($name,$old[$name],'Process')}
}
