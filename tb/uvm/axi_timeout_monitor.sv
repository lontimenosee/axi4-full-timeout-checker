class axi_timeout_monitor extends uvm_monitor;
  `uvm_component_utils(axi_timeout_monitor)
  virtual axi_timeout_if vif;
  uvm_analysis_port #(axi_timeout_cycle_item) ap;
  function new(string name, uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction
  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual axi_timeout_if)::get(this,"","vif",vif)) `uvm_fatal("NOVIF","monitor vif missing")
  endfunction
  task run_phase(uvm_phase phase); axi_timeout_cycle_item t;
    forever begin @(posedge vif.aclk); #1ps; t=axi_timeout_cycle_item::type_id::create("sample");
      t.aresetn=vif.aresetn; t.awvalid=vif.awvalid; t.awready=vif.awready;
      t.wvalid=vif.wvalid; t.wready=vif.wready; t.wlast=vif.wlast; t.bvalid=vif.bvalid; t.bready=vif.bready;
      t.arvalid=vif.arvalid; t.arready=vif.arready; t.rvalid=vif.rvalid; t.rready=vif.rready; t.rlast=vif.rlast;
      t.timeout_irq=vif.timeout_irq; t.timeout_status=vif.timeout_status; ap.write(t);
    end
  endtask
endclass
