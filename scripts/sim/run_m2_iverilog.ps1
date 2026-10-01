$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$workDir = Join-Path $repoRoot 'work\m2_iverilog'
$rtlFile = Join-Path $repoRoot 'rtl\axi4_timeout_checker.v'
$tbFile = Join-Path $repoRoot 'tb\verilog\tb_axi4_timeout_checker.v'
$timeout1TbFile = Join-Path $repoRoot 'tb\verilog\tb_axi4_timeout_checker_timeout1.v'
$simFile = Join-Path $workDir 'tb_axi4_timeout_checker.vvp'
$timeout1SimFile = Join-Path $workDir 'tb_axi4_timeout_checker_timeout1.vvp'

if (Test-Path -LiteralPath $workDir) {
    Remove-Item -LiteralPath $workDir -Recurse -Force
}
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

& iverilog -g2012 -s tb_axi4_timeout_checker -o $simFile $rtlFile $tbFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& vvp $simFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& iverilog -g2012 -s tb_axi4_timeout_checker_timeout1 -o $timeout1SimFile $rtlFile $timeout1TbFile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& vvp $timeout1SimFile
exit $LASTEXITCODE
