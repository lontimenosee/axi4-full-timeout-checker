$ErrorActionPreference = 'Stop'

# ================================================================
# Path
# ================================================================

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$workDir = Join-Path $repoRoot 'work\m2_iverilog'
$logDir  = Join-Path $repoRoot 'logs\sim'
$logFile = Join-Path $logDir 'm2_iverilog.log'

$rtlFile        = Join-Path $repoRoot 'rtl\axi4_timeout_checker.v'
$tbFile         = Join-Path $repoRoot 'tb\verilog\tb_axi4_timeout_checker.v'
$timeout1TbFile = Join-Path $repoRoot 'tb\verilog\tb_axi4_timeout_checker_timeout1.v'

$rtlCheckFile    = Join-Path $workDir 'rtl_check.vvp'
$simFile         = Join-Path $workDir 'tb_axi4_timeout_checker.vvp'
$timeout1SimFile = Join-Path $workDir 'tb_axi4_timeout_checker_timeout1.vvp'


# ================================================================
# Prepare directories
# ================================================================

if (Test-Path -LiteralPath $workDir) {
    Remove-Item -LiteralPath $workDir -Recurse -Force
}

New-Item -ItemType Directory -Path $workDir -Force | Out-Null
New-Item -ItemType Directory -Path $logDir  -Force | Out-Null

if (Test-Path -LiteralPath $logFile) {
    Remove-Item -LiteralPath $logFile -Force
}


# ================================================================
# Log header
# ================================================================

"============================================================" |
    Tee-Object -FilePath $logFile

"M2 Icarus Verilog Regression" |
    Tee-Object -FilePath $logFile -Append

"Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" |
    Tee-Object -FilePath $logFile -Append

"============================================================" |
    Tee-Object -FilePath $logFile -Append


# ================================================================
# Tool version
# ================================================================

$versionOutput = & iverilog -V 2>&1
$versionOutput |
    Tee-Object -FilePath $logFile -Append |
    Out-Host


# ================================================================
# STEP 1
# Strict Verilog RTL compile check
#
# 这里故意使用 Verilog-2005，
# 用来证明 RTL 本身不依赖 SystemVerilog 语法。
# ================================================================

"`n[STEP 1] Verilog RTL compile check" |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

$compileOutput = & iverilog `
    -g2005 `
    -Wall `
    -s axi4_timeout_checker `
    -o $rtlCheckFile `
    $rtlFile 2>&1

$compileCode = $LASTEXITCODE

$compileOutput |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

if ($compileCode -ne 0) {
    "[FAIL] RTL compile failed." |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    exit $compileCode
}


# ================================================================
# STEP 2
# Normal M2 regression
#
# TB 使用了 $fatal 等验证语法，因此这里使用 -g2012。
# ================================================================

"`n[STEP 2] Main M2 regression" |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

$compileOutput = & iverilog `
    -g2012 `
    -Wall `
    -s tb_axi4_timeout_checker `
    -o $simFile `
    $rtlFile `
    $tbFile 2>&1

$compileCode = $LASTEXITCODE

$compileOutput |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

if ($compileCode -ne 0) {
    exit $compileCode
}


$simOutput = & vvp $simFile 2>&1
$simCode = $LASTEXITCODE

$simOutput |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

if ($simCode -ne 0) {
    exit $simCode
}

if (($simOutput -join "`n") -notmatch 'M2 TESTS PASSED') {

    "[FAIL] PASS signature not found: M2 TESTS PASSED" |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    exit 1
}


# ================================================================
# STEP 3
# TIMEOUT_CYCLES = 1 corner case
# ================================================================

"`n[STEP 3] TIMEOUT_CYCLES=1 regression" |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

$compileOutput = & iverilog `
    -g2012 `
    -Wall `
    -s tb_axi4_timeout_checker_timeout1 `
    -o $timeout1SimFile `
    $rtlFile `
    $timeout1TbFile 2>&1

$compileCode = $LASTEXITCODE

$compileOutput |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

if ($compileCode -ne 0) {
    exit $compileCode
}


$timeout1Output = & vvp $timeout1SimFile 2>&1
$timeout1Code = $LASTEXITCODE

$timeout1Output |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

if ($timeout1Code -ne 0) {
    exit $timeout1Code
}

if (($timeout1Output -join "`n") -notmatch 'M2 TIMEOUT_CYCLES=1 TEST PASSED') {

    "[FAIL] TIMEOUT_CYCLES=1 PASS signature not found." |
        Tee-Object -FilePath $logFile -Append |
        Out-Host

    exit 1
}


# ================================================================
# Final
# ================================================================

"`n============================================================" |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

"[PASS] M2 Icarus regression completed successfully." |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

"============================================================" |
    Tee-Object -FilePath $logFile -Append |
    Out-Host

exit 0