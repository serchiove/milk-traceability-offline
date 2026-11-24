param(
    [ValidateSet('Backup', 'InstallSchedule', 'RemoveSchedule', 'TestRestore')]
    [string]$Action = 'Backup',
    [string]$BackupPath,
    [string]$BackupDirectory,
    [string]$PostgresBin,
    [ValidateRange(1, 3650)]
    [int]$RetentionDays = 5
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$local = Join-Path $root '.local'
$pgData = Join-Path $local 'pgdata'
$pgLog = Join-Path $local 'postgres.log'
$database = 'acopio_dev'
$dbUser = 'acopio_dev'
$hostName = '127.0.0.1'
$dbPortFile = Join-Path $local 'db-port.txt'
$port = if ($env:ACOPIO_DB_PORT) { $env:ACOPIO_DB_PORT }
elseif (Test-Path -LiteralPath $dbPortFile) { (Get-Content -LiteralPath $dbPortFile -Raw).Trim() }
else { '55440' }
if ($port -notmatch '^\d{4,5}$' -or [int]$port -lt 1024 -or [int]$port -gt 65535) {
    throw 'Puerto PostgreSQL local inválido.'
}
$taskName = 'Acopio-PostgreSQL-Backup'
$databaseStartedByScript = $false
$restoreDatabaseCreated = $false
$restoreDatabase = $null

if (!$BackupDirectory) {
    $BackupDirectory = Join-Path $local 'backups'
}
$BackupDirectory = [System.IO.Path]::GetFullPath($BackupDirectory)
$maintenanceLog = Join-Path $BackupDirectory 'maintenance.log'

New-Item -ItemType Directory -Force -Path $local, $BackupDirectory | Out-Null

function Write-MaintenanceLog {
    param([string]$Level, [string]$Message)
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -LiteralPath $maintenanceLog -Value $line -Encoding UTF8
    Write-Host $line
}

function Get-PostgresTool {
    param([string]$Name)
    if ($PostgresBin) {
        $pgBin = $PostgresBin
    }
    elseif ($env:ACOPIO_PG_BIN) {
        $pgBin = $env:ACOPIO_PG_BIN
    }
    else {
        $pgBin = 'C:\Program Files\PostgreSQL\18\bin'
    }
    $tool = Join-Path $pgBin $Name
    if (!(Test-Path -LiteralPath $tool -PathType Leaf)) {
        if (!$PostgresBin -and !$env:ACOPIO_PG_BIN) {
            $availableTool = Get-Command $Name -ErrorAction SilentlyContinue
            if ($availableTool) {
                return $availableTool.Source
            }
        }
        throw "No se encontró $Name en '$pgBin'. Instala PostgreSQL 18 o define ACOPIO_PG_BIN."
    }
    return $tool
}

function Invoke-PostgresTool {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [string]$Operation
    )
    $output = & $Executable @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $detail = ($output | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join ' '
        throw "$Operation falló (código $exitCode). $detail"
    }
    return $output
}

function Set-DatabaseEnvironment {
    $passwordFile = Join-Path $local 'db-password.txt'
    if (!(Test-Path -LiteralPath $passwordFile -PathType Leaf)) {
        throw 'Falta .local\db-password.txt. Prepara primero el entorno del proyecto.'
    }
    $env:PGPASSWORD = (Get-Content -LiteralPath $passwordFile -Raw).Trim()
    if (!$env:PGPASSWORD) {
        throw 'La contraseña local de PostgreSQL está vacía.'
    }
    $env:PGCONNECT_TIMEOUT = '5'
}

function Start-LocalDatabaseIfNeeded {
    $pgCtl = Get-PostgresTool 'pg_ctl.exe'
    & $pgCtl -D $pgData status *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-MaintenanceLog 'INFO' 'PostgreSQL local ya está iniciado.'
        return
    }
    if (!(Test-Path -LiteralPath (Join-Path $pgData 'PG_VERSION') -PathType Leaf)) {
        throw 'No existe la base PostgreSQL local. Ejecuta scripts\Preparar.ps1 primero.'
    }
    Write-MaintenanceLog 'INFO' 'Iniciando PostgreSQL local para la tarea de mantenimiento.'
    & $pgCtl -D $pgData -l $pgLog -o "-p $port -h 127.0.0.1" -w start
    if ($LASTEXITCODE -ne 0) {
        throw "Inicio de PostgreSQL falló (código $LASTEXITCODE). Revisa .local\postgres.log."
    }
    $script:databaseStartedByScript = $true
    Write-MaintenanceLog 'INFO' 'PostgreSQL local está listo.'
}

function Stop-LocalDatabaseIfStarted {
    if (!$script:databaseStartedByScript) {
        return
    }
    $pgCtl = Get-PostgresTool 'pg_ctl.exe'
    Invoke-PostgresTool $pgCtl @('-D', $pgData, '-m', 'fast', '-w', 'stop') 'Detención de PostgreSQL' | Out-Null
    $script:databaseStartedByScript = $false
    Write-MaintenanceLog 'INFO' 'PostgreSQL quedó detenido; el script lo había iniciado.'
}

function Assert-DatabaseExists {
    $psql = Get-PostgresTool 'psql.exe'
    Write-MaintenanceLog 'INFO' "Comprobando la conexión a '$database'."
    $result = Invoke-PostgresTool $psql @(
        '-X', '-q', '-t', '-A', '-v', 'ON_ERROR_STOP=1',
        '--host', $hostName, '--port', $port, '--username', $dbUser,
        '--dbname', 'postgres', '-c', "SELECT 1 FROM pg_database WHERE datname = '$database'"
    ) 'Comprobación de la base'
    if (($result -join '').Trim() -ne '1') {
        throw "No existe la base local '$database'. Ejecuta Iniciar.cmd para preparar el entorno."
    }
    Write-MaintenanceLog 'INFO' "Conexión a '$database' confirmada."
}

function Invoke-Backup {
    Set-DatabaseEnvironment
    Start-LocalDatabaseIfNeeded
    Assert-DatabaseExists

    $pgDump = Get-PostgresTool 'pg_dump.exe'
    $pgRestore = Get-PostgresTool 'pg_restore.exe'
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    $backupFile = Join-Path $BackupDirectory "acopio_$timestamp.dump"

    try {
        Invoke-PostgresTool $pgDump @(
            '--no-password', '--host', $hostName, '--port', $port, '--username', $dbUser,
            '--format', 'custom', '--no-owner', '--no-acl', '--file', $backupFile, $database
        ) 'Respaldo de PostgreSQL' | Out-Null
        Invoke-PostgresTool $pgRestore @('--list', $backupFile) 'Validación del archivo de respaldo' | Out-Null
    }
    catch {
        if (Test-Path -LiteralPath $backupFile) {
            Remove-Item -LiteralPath $backupFile -Force
        }
        throw
    }

    Write-MaintenanceLog 'INFO' "Respaldo creado y validado: $backupFile"
    $cutoff = (Get-Date).AddDays(-$RetentionDays)
    $expiredBackups = @(Get-ChildItem -LiteralPath $BackupDirectory -Filter 'acopio_*.dump' -File |
        Where-Object { $_.LastWriteTime -lt $cutoff })
    foreach ($expiredBackup in $expiredBackups) {
        Remove-Item -LiteralPath $expiredBackup.FullName -Force
        Write-MaintenanceLog 'INFO' "Respaldo vencido eliminado: $($expiredBackup.Name)"
    }
    Write-MaintenanceLog 'INFO' "Retención aplicada: $RetentionDays días; respaldos vencidos eliminados: $($expiredBackups.Count)."
}

function Invoke-RestoreCheck {
    Set-DatabaseEnvironment
    Start-LocalDatabaseIfNeeded

    if (!$BackupPath) {
        $latestBackup = Get-ChildItem -LiteralPath $BackupDirectory -Filter 'acopio_*.dump' -File |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if (!$latestBackup) {
            throw "No hay respaldos en '$BackupDirectory'. Ejecuta primero -Action Backup."
        }
        $BackupPath = $latestBackup.FullName
    }
    $BackupPath = [System.IO.Path]::GetFullPath($BackupPath)
    if (!(Test-Path -LiteralPath $BackupPath -PathType Leaf)) {
        throw "No se encontró el respaldo '$BackupPath'."
    }

    $pgRestore = Get-PostgresTool 'pg_restore.exe'
    $createdb = Get-PostgresTool 'createdb.exe'
    $dropdb = Get-PostgresTool 'dropdb.exe'
    $psql = Get-PostgresTool 'psql.exe'
    Invoke-PostgresTool $pgRestore @('--list', $BackupPath) 'Validación del archivo de respaldo' | Out-Null

    $restoreDatabase = 'acopio_restore_check_{0}_{1}' -f (Get-Date -Format 'yyyyMMddHHmmss'), (Get-Random -Maximum 1000000)
    try {
        Invoke-PostgresTool $createdb @(
            '--no-password', '--host', $hostName, '--port', $port, '--username', $dbUser,
            '--maintenance-db', 'postgres', '--template', 'template0', $restoreDatabase
        ) 'Creación de la base temporal de restauración' | Out-Null
        $script:restoreDatabaseCreated = $true

        Write-MaintenanceLog 'INFO' "Restaurando en la base temporal '$restoreDatabase'; '$database' no será modificada."
        Invoke-PostgresTool $pgRestore @(
            '--no-password', '--exit-on-error', '--no-owner', '--no-privileges',
            '--host', $hostName, '--port', $port, '--username', $dbUser,
            '--dbname', $restoreDatabase, $BackupPath
        ) 'Restauración de prueba' | Out-Null

        $summarySql = "SELECT (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'acopio' AND table_type = 'BASE TABLE')::text || '|' || (SELECT count(*)::text FROM public.flyway_schema_history WHERE success)"
        $summary = Invoke-PostgresTool $psql @(
            '-X', '-q', '-t', '-A', '-v', 'ON_ERROR_STOP=1',
            '--host', $hostName, '--port', $port, '--username', $dbUser,
            '--dbname', $restoreDatabase, '-c', $summarySql
        ) 'Verificación de la base restaurada'
        $counts = (($summary -join '').Trim()).Split('|')
        if ($counts.Count -ne 2 -or [int]$counts[0] -lt 1 -or [int]$counts[1] -lt 1) {
            throw 'La restauración terminó, pero no se encontraron tablas del esquema acopio y migraciones Flyway exitosas.'
        }
        Write-MaintenanceLog 'INFO' "Restauración de prueba correcta: $($counts[0]) tablas y $($counts[1]) migraciones Flyway exitosas."
    }
    finally {
        if ($script:restoreDatabaseCreated) {
            Invoke-PostgresTool $dropdb @(
                '--no-password', '--if-exists', '--host', $hostName, '--port', $port, '--username', $dbUser,
                '--maintenance-db', 'postgres', $restoreDatabase
            ) 'Eliminación de la base temporal de restauración' | Out-Null
            $script:restoreDatabaseCreated = $false
            Write-MaintenanceLog 'INFO' "Base temporal '$restoreDatabase' eliminada."
        }
    }
}

function Register-BackupSchedule {
    Import-Module ScheduledTasks -ErrorAction Stop
    $scriptPath = Join-Path $PSScriptRoot 'Maintenance.ps1'
    $postgresBin = Split-Path (Get-PostgresTool 'pg_dump.exe') -Parent
    $taskArguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Action Backup -BackupDirectory "{1}" -PostgresBin "{2}" -RetentionDays {3}' -f $scriptPath, $BackupDirectory, $postgresBin, $RetentionDays
    $scheduledAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $taskArguments
    $trigger = New-ScheduledTaskTrigger -Daily -At '2:00 AM'
    $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 2) -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskName $taskName -Action $scheduledAction -Trigger $trigger -Principal $principal -Settings $settings -Description "Respaldo diario validado de la base local Acopio; retención de $RetentionDays días." -Force | Out-Null
    Write-MaintenanceLog 'INFO' "Tarea '$taskName' programada diariamente a las 2:00 AM con retención de $RetentionDays días."
    Write-MaintenanceLog 'INFO' 'Windows ejecuta la tarea cuando este usuario ha iniciado sesión; si el equipo estaba suspendido, se inicia al reanudarse.'
}

$operationError = $null
try {
    switch ($Action) {
        'Backup' {
            Invoke-Backup
        }
        'TestRestore' {
            Invoke-RestoreCheck
        }
        'InstallSchedule' {
            Register-BackupSchedule
        }
        'RemoveSchedule' {
            Import-Module ScheduledTasks -ErrorAction Stop
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
            Write-MaintenanceLog 'INFO' "Tarea '$taskName' eliminada."
        }
    }
}
catch {
    $operationError = $_
    Write-MaintenanceLog 'ERROR' $operationError.Exception.Message
}
finally {
    try {
        Stop-LocalDatabaseIfStarted
    }
    catch {
        $stopError = $_
        Write-MaintenanceLog 'ERROR' $stopError.Exception.Message
        if (!$operationError) {
            $operationError = $stopError
        }
    }
}

if ($operationError) {
    throw $operationError
}
