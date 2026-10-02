class axi_timeout_env extends uvm_env;
 `uvm_component_utils(axi_timeout_env)
 axi_timeout_agent agent; axi_timeout_scoreboard sb; axi_timeout_coverage cov;
 function new(string n,uvm_component p);super.new(n,p);endfunction
 function void build_phase(uvm_phase phase);agent=axi_timeout_agent::type_id::create("agent",this);sb=axi_timeout_scoreboard::type_id::create("sb",this);cov=axi_timeout_coverage::type_id::create("cov",this);endfunction
 function void connect_phase(uvm_phase phase);agent.mon.ap.connect(sb.analysis_export);agent.mon.ap.connect(cov.analysis_export);endfunction
endclass
