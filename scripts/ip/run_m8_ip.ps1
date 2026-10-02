$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$defaultVivado = 'D:\FPGA\Vivado\Vivado\2020.2\bin\vivado.bat'
$vivado = if ($env:VIVADO_BIN) { $env:VIVADO_BIN } else { $defaultVivado }
$logDir = Join-Path $repoRoot 'logs\ip'

if (-not (Test-Path -LiteralPath $vivado -PathType Leaf)) {
    throw "Vivado executable not found: $vivado. Set VIVADO_BIN to vivado.bat."
}

New-Item -Path $logDir -ItemType Directory -Force | Out-Null

function Invoke-VivadoStage {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Script,
        [Parameter(Mandatory)] [string] $PassMarker
    )

    $logFile = Join-Path $logDir "$Name.log"
    $output = & $vivado -mode batch -nolog -nojournal -source $Script 2>&1
    $exitCode = $LASTEXITCODE
    $output | Set-Content -Path $logFile -Encoding utf8
    $output | Out-Host

    if ($exitCode -ne 0 -or ($output -join "`n") -notmatch [regex]::Escape($PassMarker)) {
        throw "Vivado stage '$Name' failed. See $logFile"
    }
}

Invoke-VivadoStage `
    -Name 'm8_package' `
    -Script (Join-Path $PSScriptRoot 'package_ip.tcl') `
    -PassMarker 'M8_PACKAGE_PASS'

Invoke-VivadoStage `
    -Name 'm8_validate' `
    -Script (Join-Path $PSScriptRoot 'validate_ip.tcl') `
    -PassMarker 'M8_VALIDATE_PASS'

Write-Host "M8 IP packaging and consumer validation passed. Logs: $logDir"
