class axi_timeout_base_test extends uvm_test;
 `uvm_component_utils(axi_timeout_base_test) axi_timeout_env env;
 function new(string n,uvm_component p);super.new(n,p);endfunction
 function void build_phase(uvm_phase phase);env=axi_timeout_env::type_id::create("env",this);endfunction
endclass
`define AXI_TEST(C,S) class C extends axi_timeout_base_test; `uvm_component_utils(C) function new(string n,uvm_component p);super.new(n,p);endfunction task run_phase(uvm_phase phase);S seq;phase.raise_objection(this);seq=S::type_id::create("seq");seq.start(env.agent.sqr);#30ns;phase.drop_objection(this);endtask endclass
`AXI_TEST(axi_timeout_smoke_test,axi_timeout_smoke_sequence)
`AXI_TEST(axi_timeout_boundary_test,axi_timeout_boundary_sequence)
`AXI_TEST(axi_timeout_recovery_test,axi_timeout_recovery_sequence)
`AXI_TEST(axi_timeout_parallel_reset_test,axi_timeout_parallel_reset_sequence)
`undef AXI_TEST
