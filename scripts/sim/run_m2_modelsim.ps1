$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$workDir = Join-Path $repoRoot 'work\m2_modelsim'
$rtlFile = Join-Path $repoRoot 'rtl\axi4_timeout_checker.v'
$tbFile = Join-Path $repoRoot 'tb\verilog\tb_axi4_timeout_checker.v'
$timeout1TbFile = Join-Path $repoRoot 'tb\verilog\tb_axi4_timeout_checker_timeout1.v'

if (Test-Path -LiteralPath $workDir) {
    Remove-Item -LiteralPath $workDir -Recurse -Force
}
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

Push-Location $workDir
try {
    & vlib work
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & vlog -sv -work work $rtlFile $tbFile $timeout1TbFile
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $simOutput = & vsim -c work.tb_axi4_timeout_checker -do 'onerror {resume}; run -all; quit -code 0' 2>&1
    $simOutput | Out-Host
    if (($simOutput -join "`n") -notmatch 'M2 TESTS PASSED') {
        exit 1
    }

    $timeout1Output = & vsim -c work.tb_axi4_timeout_checker_timeout1 -do 'onerror {resume}; run -all; quit -code 0' 2>&1
    $timeout1Output | Out-Host
    if (($timeout1Output -join "`n") -notmatch 'M2 TIMEOUT_CYCLES=1 TEST PASSED') {
        exit 1
    }
    exit 0
}
finally {
    Pop-Location
}
