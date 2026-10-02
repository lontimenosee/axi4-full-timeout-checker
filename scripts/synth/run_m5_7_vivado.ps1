$ErrorActionPreference='Stop'
$root=(Resolve-Path(Join-Path $PSScriptRoot '..\..')).Path
$vivado='D:\FPGA\Vivado\Vivado\2020.2\bin\vivado.bat'
$logDir=Join-Path $root 'logs\synth';New-Item $logDir -ItemType Directory -Force|Out-Null
$out=& $vivado -mode batch -nolog -nojournal -source (Join-Path $PSScriptRoot 'synth_m5_7.tcl') 2>&1
$code=$LASTEXITCODE;$out|Set-Content (Join-Path $logDir 'm5_7_vivado.log') -Encoding utf8;$out|Out-Host
if($code-ne 0 -or ($out-join"`n")-notmatch 'M5_7_SYNTH_PASS'){exit 1};exit 0
