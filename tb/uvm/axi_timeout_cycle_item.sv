class axi_timeout_cycle_item extends uvm_sequence_item;
  rand bit aresetn;
  rand bit awvalid, awready;
  rand bit wvalid, wready, wlast;
  rand bit bvalid, bready;
  rand bit arvalid, arready;
  rand bit rvalid, rready, rlast;
  bit timeout_irq;
  bit [4:0] timeout_status;
  `uvm_object_utils_begin(axi_timeout_cycle_item)
    `uvm_field_int(aresetn, UVM_DEFAULT)
    `uvm_field_int(awvalid, UVM_DEFAULT) `uvm_field_int(awready, UVM_DEFAULT)
    `uvm_field_int(wvalid, UVM_DEFAULT)  `uvm_field_int(wready, UVM_DEFAULT) `uvm_field_int(wlast, UVM_DEFAULT)
    `uvm_field_int(bvalid, UVM_DEFAULT)  `uvm_field_int(bready, UVM_DEFAULT)
    `uvm_field_int(arvalid, UVM_DEFAULT) `uvm_field_int(arready, UVM_DEFAULT)
    `uvm_field_int(rvalid, UVM_DEFAULT)  `uvm_field_int(rready, UVM_DEFAULT) `uvm_field_int(rlast, UVM_DEFAULT)
  `uvm_object_utils_end
  function new(string name="axi_timeout_cycle_item"); super.new(name); endfunction
endclass
