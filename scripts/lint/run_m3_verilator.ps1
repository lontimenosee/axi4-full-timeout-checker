$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$rtlFile = Join-Path $repoRoot 'rtl\axi4_timeout_checker.v'
$logDir = Join-Path $repoRoot 'logs\lint'
$logFile = Join-Path $logDir 'm3_verilator.log'
$fallbackVerilator = 'D:\FPGA\Verilator\bin\verilator.cmd'

$verilatorCommand = Get-Command verilator -ErrorAction SilentlyContinue
if ($verilatorCommand) {
    $verilator = $verilatorCommand.Source
} elseif (Test-Path -LiteralPath $fallbackVerilator) {
    $verilator = $fallbackVerilator
} else {
    throw 'Verilator was not found in PATH or at D:\FPGA\Verilator\bin\verilator.cmd'
}

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$versionOutput = & $verilator --version 2>&1
$versionCode = $LASTEXITCODE
if ($versionCode -ne 0) {
    throw "Verilator version check failed with exit code $versionCode"
}

$arguments = @(
    '--lint-only',
    '--Wall',
    '--top-module', 'axi4_timeout_checker',
    $rtlFile
)

$savedErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$lintOutput = & $verilator @arguments 2>&1
$lintCode = $LASTEXITCODE
$ErrorActionPreference = $savedErrorActionPreference

$report = @(
    '============================================================',
    'M3 Verilator RTL Lint',
    "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Tool: $versionOutput",
    "Command: verilator $($arguments -join ' ')",
    '============================================================',
    ''
) + $lintOutput + @(
    '',
    '============================================================',
    "Exit code: $lintCode",
    $(if ($lintCode -eq 0) { '[PASS] M3 Verilator lint completed with zero warnings and errors.' } else { '[FAIL] M3 Verilator lint reported warnings or errors.' }),
    '============================================================'
)

$report | Set-Content -LiteralPath $logFile -Encoding utf8
$report | ForEach-Object { Write-Output $_ }
exit $lintCode
