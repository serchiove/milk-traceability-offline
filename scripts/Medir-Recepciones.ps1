# Ejecutar cuando PostgreSQL local del proyecto este preparado y en marcha.
# No arranca/detiene servicios ni crea/elimina bases. Maven usa acopio_test.
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
$localAcopio = Join-Path $raiz '.local'
$archivoClave = Join-Path $localAcopio 'db-password.txt'
if (!(Test-Path -LiteralPath $archivoClave)) { throw 'Falta la preparacion local del clon (db-password.txt).' }
$sha = (& git -C $raiz rev-parse HEAD)
if ($LASTEXITCODE -ne 0 -or $sha -notmatch '^[a-fA-F0-9]{40,64}$') { throw 'Usa un clon de Git del proyecto para identificar el commit.' }
$estadoCodigo = @(& git -C $raiz status --porcelain -- backend scripts)
if ($LASTEXITCODE -ne 0 -or $estadoCodigo.Count -gt 0) { throw 'Guarda tus cambios de backend y scripts en un commit antes de medir.' }
$portFile = Join-Path $localAcopio 'db-port.txt'
$puertoPg = if ($env:ACOPIO_DB_PORT) { $env:ACOPIO_DB_PORT } elseif (Test-Path -LiteralPath $portFile) { (Get-Content -LiteralPath $portFile -Raw).Trim() } else { '55440' }
if ($puertoPg -notmatch '^\d{1,5}$' -or [int]$puertoPg -gt 65535 -or [int]$puertoPg -lt 1024) { throw 'Puerto de PostgreSQL local no valido.' }
$variables = @('DB_HOST','DB_PORT','DB_USERNAME','DB_PASSWORD','TEST_DB_NAME','ACOPIO_MON_COMMIT','ACOPIO_MON_CORRIDA')
$previas = @{}; foreach ($k in $variables) { $previas[$k] = [Environment]::GetEnvironmentVariable($k,'Process') }
$corrida = [guid]::NewGuid().ToString()
Push-Location (Join-Path $raiz 'backend')
try {
    $env:DB_HOST='127.0.0.1'; $env:DB_PORT=$puertoPg; $env:DB_USERNAME='acopio_dev'
    $env:TEST_DB_NAME='acopio_test'; $env:DB_PASSWORD=(Get-Content -LiteralPath $archivoClave -Raw).Trim()
    $env:ACOPIO_MON_COMMIT=$sha; $env:ACOPIO_MON_CORRIDA=$corrida
    & .\mvnw.cmd "-Dmaven.repo.local=$localAcopio/m2" '-Dtest=MedicionRecepciones' --batch-mode test
    $codigo = $LASTEXITCODE
    $origen = Join-Path (Get-Location).Path "target/monitoreo/$corrida"
    if (Test-Path -LiteralPath (Join-Path $origen 'recepciones-resumen.txt')) {
        $destino = Join-Path $raiz "docs/monitoreo/evidencias/recepciones-$corrida"
        New-Item -ItemType Directory -Path $destino -ErrorAction Stop | Out-Null
        foreach ($n in @('recepciones.csv','recepciones-resumen.txt')) {
            Copy-Item -LiteralPath (Join-Path $origen $n) -Destination $destino
        }
        Write-Host "Evidencia de esta corrida: $destino"
    } elseif ($codigo -eq 0) { throw 'No se genero evidencia para esta corrida.' }
    if ($codigo -ne 0) { throw 'Maven o la medicion no cumplieron el criterio. Conserva el resultado y revisa la causa.' }
} finally {
    Pop-Location
    foreach ($k in $variables) { [Environment]::SetEnvironmentVariable($k,$previas[$k],'Process') }
}
