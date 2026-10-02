class axi_timeout_driver extends uvm_driver #(axi_timeout_cycle_item);
  `uvm_component_utils(axi_timeout_driver)
  virtual axi_timeout_if vif;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_timeout_if)::get(this,"","vif",vif)) `uvm_fatal("NOVIF","driver vif missing")
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(negedge vif.aclk);
      vif.aresetn<=req.aresetn; vif.awvalid<=req.awvalid; vif.awready<=req.awready;
      vif.wvalid<=req.wvalid; vif.wready<=req.wready; vif.wlast<=req.wlast;
      vif.bvalid<=req.bvalid; vif.bready<=req.bready; vif.arvalid<=req.arvalid; vif.arready<=req.arready;
      vif.rvalid<=req.rvalid; vif.rready<=req.rready; vif.rlast<=req.rlast;
      seq_item_port.item_done();
    end
  endtask
endclass
