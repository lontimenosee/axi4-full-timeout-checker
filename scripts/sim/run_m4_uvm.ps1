$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$work=Join-Path $root 'work\m4_uvm'; $logDir=Join-Path $root 'logs\sim'; $log=Join-Path $logDir 'm4_uvm.log'
if(Test-Path $work){Remove-Item $work -Recurse -Force};New-Item $work -ItemType Directory|Out-Null;New-Item $logDir -ItemType Directory -Force|Out-Null
$all=@(); Push-Location $work
try{
 & vlib work | Out-Null
 $inc="+incdir+$root\tb\uvm"
 $compile=& vlog -sv -L uvm -work work $inc "$root\tb\uvm\axi_timeout_if.sv" "$root\tb\uvm\axi_timeout_pkg.sv" "$root\rtl\axi4_timeout_checker.v" "$root\tb\uvm\tb_axi4_timeout_uvm.sv" 2>&1
 $all+=$compile; if($LASTEXITCODE-ne 0){$all|Set-Content $log -Encoding utf8;$all|Out-Host;exit 1}
 $tests=@('axi_timeout_smoke_test','axi_timeout_boundary_test','axi_timeout_recovery_test','axi_timeout_parallel_reset_test')
 foreach($test in $tests){
  $out=& vsim -c -L uvm work.tb_axi4_timeout_uvm "+UVM_TESTNAME=$test" -do 'run -all; quit -code 0' 2>&1
  $all+="===== $test =====";$all+=$out
  $text=$out-join"`n"
  if($text-notmatch 'M4_PASS' -or $text-notmatch 'UVM_ERROR\s*:\s*0' -or $text-notmatch 'UVM_FATAL\s*:\s*0'){$all|Set-Content $log -Encoding utf8;$all|Out-Host;exit 1}
 }
 $all+='[PASS] M4 UVM regression completed successfully.';$all|Set-Content $log -Encoding utf8;$all|Out-Host;exit 0
}finally{Pop-Location}
