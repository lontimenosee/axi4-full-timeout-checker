class axi_timeout_coverage extends uvm_subscriber #(axi_timeout_cycle_item);
  `uvm_component_utils(axi_timeout_coverage)
  axi_timeout_cycle_item sample;
  covergroup cg;
    option.per_instance = 1;
    cp_reset: coverpoint sample.aresetn { bins asserted={0}; bins released={1}; }
    cp_irq: coverpoint sample.timeout_irq;
    cp_aw: coverpoint sample.timeout_status[0] { bins seen={1}; }
    cp_w : coverpoint sample.timeout_status[1] { bins seen={1}; }
    cp_b : coverpoint sample.timeout_status[2] { bins seen={1}; }
    cp_ar: coverpoint sample.timeout_status[3] { bins seen={1}; }
    cp_r : coverpoint sample.timeout_status[4] { bins seen={1}; }
    cp_aw_hs: coverpoint (sample.awvalid && sample.awready);
    cp_w_hs : coverpoint (sample.wvalid && sample.wready);
    cp_b_hs : coverpoint (sample.bvalid && sample.bready);
    cp_ar_hs: coverpoint (sample.arvalid && sample.arready);
    cp_r_hs : coverpoint (sample.rvalid && sample.rready);
    cp_parallel: coverpoint ((sample.awvalid||sample.wvalid||sample.bvalid) &&
                             (sample.arvalid||sample.rvalid)) { bins active={1}; }
  endgroup
  function new(string name,uvm_component parent); super.new(name,parent); cg=new; endfunction
  function void write(axi_timeout_cycle_item t); sample=t; cg.sample(); endfunction
  function void report_phase(uvm_phase phase);
    `uvm_info("COVERAGE",$sformatf("functional coverage = %0.2f%%",cg.get_inst_coverage()),UVM_LOW)
  endfunction
endclass
