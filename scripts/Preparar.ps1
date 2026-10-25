$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$local=Join-Path $root '.local'
New-Item -ItemType Directory -Force $local | Out-Null
$pgBin=if($env:ACOPIO_PG_BIN){$env:ACOPIO_PG_BIN}else{'C:\Program Files\PostgreSQL\18\bin'}
foreach($tool in @('java.exe','mvn.cmd','npm.cmd','git.exe','flutter.bat')){Get-Command $tool -ErrorAction Stop | Out-Null}
if(!(Test-Path "$pgBin/initdb.exe")){throw 'Instala PostgreSQL 18 o define ACOPIO_PG_BIN con la carpeta bin.'}
if($env:ACOPIO_NODE){$env:PATH=(Split-Path $env:ACOPIO_NODE)+';'+$env:PATH}
if(!(Test-Path "$local/db-password.txt")){
 $bytes=New-Object byte[] 32
 $rng=[System.Security.Cryptography.RandomNumberGenerator]::Create();$rng.GetBytes($bytes);$rng.Dispose()
 [Convert]::ToBase64String($bytes) | Set-Content "$local/db-password.txt"
}
if(!(Test-Path "$local/pgdata/PG_VERSION")){
 & "$pgBin/initdb.exe" -D "$local/pgdata" -U acopio_dev "--pwfile=$local/db-password.txt" --auth=scram-sha-256 --encoding=UTF8 --locale=C
 if($LASTEXITCODE -ne 0){throw 'No se pudo inicializar la base local.'}
}
foreach($app in @('dashboard')){
 Push-Location "$root/$app"
 try { & npm.cmd ci --registry=https://registry.npmjs.org "--cache=$local/npm-cache" --no-fund; if($LASTEXITCODE -ne 0){throw "No se pudieron instalar dependencias de $app."} } finally {Pop-Location}
}
Push-Location "$root/mobile-flutter"
try { & flutter.bat pub get; if($LASTEXITCODE -ne 0){throw 'No se pudieron instalar las dependencias Flutter.'} } finally {Pop-Location}
& "$PSScriptRoot/Dev.ps1" -Action Build
