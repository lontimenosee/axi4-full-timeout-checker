class axi_timeout_agent extends uvm_agent;
 `uvm_component_utils(axi_timeout_agent)
 axi_timeout_sequencer sqr; axi_timeout_driver drv; axi_timeout_monitor mon;
 function new(string n,uvm_component p);super.new(n,p);endfunction
 function void build_phase(uvm_phase phase);sqr=axi_timeout_sequencer::type_id::create("sqr",this);drv=axi_timeout_driver::type_id::create("drv",this);mon=axi_timeout_monitor::type_id::create("mon",this);endfunction
 function void connect_phase(uvm_phase phase);drv.seq_item_port.connect(sqr.seq_item_export);endfunction
endclass
