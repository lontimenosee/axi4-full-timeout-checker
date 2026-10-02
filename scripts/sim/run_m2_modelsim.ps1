$ErrorActionPreference = 'Stop'

# ================================================================
# Path
# ================================================================

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$workDir = Join-Path $repoRoot 'work\m2_modelsim'
$logDir  = Join-Path $repoRoot 'logs\sim'
$logFile = Join-Path $logDir 'm2_modelsim.log'

$rtlFile        = Join-Path $repoRoot 'rtl\axi4_timeout_checker.v'
$tbFile         = Join-Path $repoRoot 'tb\verilog\tb_axi4_timeout_checker.v'
$timeout1TbFile = Join-Path $repoRoot 'tb\verilog\tb_axi4_timeout_checker_timeout1.v'


# ================================================================
# Prepare
# ================================================================

if (Test-Path -LiteralPath $workDir) {
    Remove-Item -LiteralPath $workDir -Recurse -Force
}

New-Item -ItemType Directory -Path $workDir -Force | Out-Null
New-Item -ItemType Directory -Path $logDir  -Force | Out-Null

if (Test-Path -LiteralPath $logFile) {
    Remove-Item -LiteralPath $logFile -Force
}


"============================================================" |
    Tee-Object -FilePath $logFile

"M2 ModelSim Regression" |
    Tee-Object -FilePath $logFile -Append

"Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" |
    Tee-Object -FilePath $logFile -Append

"============================================================" |
    Tee-Object -FilePath $logFile -Append


Push-Location $workDir

try {

    # ============================================================
    # Tool Version
    # ============================================================

    $versionOutput = & vsim -version 2>&1

    $versionOutput |
        Tee-Object -FilePath $logFile -Append |
        Out-Host


    # ============================================================
    # Create work library
    # ============================================================

    "`n[STEP 1] Create ModelSim work library" |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    $output = & vlib work 2>&1
    $code = $LASTEXITCODE

    $output |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    if ($code -ne 0) {
        throw "vlib failed with exit code $code"
    }


    # ============================================================
    # Compile RTL as Verilog
    # ============================================================

    "`n[STEP 2] Compile RTL as Verilog" |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    $output = & vlog -work work $rtlFile 2>&1
    $code = $LASTEXITCODE

    $output |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    if ($code -ne 0) {
        throw "RTL compilation failed with exit code $code"
    }


    # ============================================================
    # Compile testbenches
    #
    # 当前 TB 使用 $fatal，因此按 SystemVerilog 编译。
    # ============================================================

    "`n[STEP 3] Compile testbenches" |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    $output = & vlog `
        -sv `
        -work work `
        $tbFile `
        $timeout1TbFile 2>&1

    $code = $LASTEXITCODE

    $output |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    if ($code -ne 0) {
        throw "Testbench compilation failed with exit code $code"
    }


    # ============================================================
    # Main regression
    # ============================================================

    "`n[STEP 4] Main M2 regression" |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    $simOutput = & vsim `
        -c `
        work.tb_axi4_timeout_checker `
        -do 'onerror {quit -code 1}; run -all; quit -code 0' 2>&1

    $simCode = $LASTEXITCODE

    $simOutput |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    if ($simCode -ne 0) {
        throw "Main simulation failed with exit code $simCode"
    }

    if (($simOutput -join "`n") -notmatch 'M2 TESTS PASSED') {
        throw "PASS signature not found: M2 TESTS PASSED"
    }


    # ============================================================
    # TIMEOUT_CYCLES = 1 regression
    # ============================================================

    "`n[STEP 5] TIMEOUT_CYCLES=1 regression" |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    $timeout1Output = & vsim `
        -c `
        work.tb_axi4_timeout_checker_timeout1 `
        -do 'onerror {quit -code 1}; run -all; quit -code 0' 2>&1

    $timeout1Code = $LASTEXITCODE

    $timeout1Output |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    if ($timeout1Code -ne 0) {
        throw "TIMEOUT_CYCLES=1 simulation failed with exit code $timeout1Code"
    }

    if (($timeout1Output -join "`n") -notmatch 'M2 TIMEOUT_CYCLES=1 TEST PASSED') {
        throw "PASS signature not found: M2 TIMEOUT_CYCLES=1 TEST PASSED"
    }


    # ============================================================
    # PASS
    # ============================================================

    "`n============================================================" |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    "[PASS] M2 ModelSim regression completed successfully." |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    "============================================================" |
        Tee-Object -FilePath $logFile -Append |
        Out-Host
}
catch {

    "`n[FAIL] $($_.Exception.Message)" |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    Pop-Location

    exit 1
}

Pop-Location
exit 0