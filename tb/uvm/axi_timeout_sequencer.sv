class axi_timeout_sequencer extends uvm_sequencer #(axi_timeout_cycle_item);
  `uvm_component_utils(axi_timeout_sequencer)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
endclass
