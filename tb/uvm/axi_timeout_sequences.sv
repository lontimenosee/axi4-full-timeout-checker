class axi_timeout_base_sequence extends uvm_sequence #(axi_timeout_cycle_item);
 `uvm_object_utils(axi_timeout_base_sequence)
 function new(string n="axi_timeout_base_sequence");super.new(n);endfunction
 task send(bit rst,bit[11:0] b=0);axi_timeout_cycle_item t;t=axi_timeout_cycle_item::type_id::create("t");start_item(t);t.aresetn=rst;{t.awvalid,t.awready,t.wvalid,t.wready,t.wlast,t.bvalid,t.bready,t.arvalid,t.arready,t.rvalid,t.rready,t.rlast}=b;finish_item(t);endtask
 task idle(int n=1);repeat(n)send(1,0);endtask
 task reset_dut();send(0);send(0);send(1);endtask
 task aw();send(1,12'b110000000000);endtask
 task w(bit last);send(1,last?12'b001110000000:12'b001100000000);endtask
 task b();send(1,12'b000001100000);endtask
 task ar();send(1,12'b000000011000);endtask
 task r(bit last);send(1,last?12'b000000000111:12'b000000000110);endtask
endclass

class axi_timeout_smoke_sequence extends axi_timeout_base_sequence;
 `uvm_object_utils(axi_timeout_smoke_sequence) function new(string n="smoke");super.new(n);endfunction
 task body();reset_dut();aw();w(0);w(1);b();ar();r(0);r(1);idle();
  reset_dut();repeat(4)send(1,12'b100000000000);idle();
  reset_dut();aw();repeat(4)idle();reset_dut();aw();w(1);repeat(4)idle();
  reset_dut();repeat(4)send(1,12'b000000010000);reset_dut();ar();repeat(4)idle();idle(2);
 endtask
endclass
class axi_timeout_boundary_sequence extends axi_timeout_base_sequence;
 `uvm_object_utils(axi_timeout_boundary_sequence) function new(string n="boundary");super.new(n);endfunction
 task body();reset_dut();repeat(3)send(1,12'b100000000000);aw();w(1);b();
  reset_dut();aw();idle(3);w(0);idle(3);w(1);b();
  reset_dut();send(1,12'b111110000000);b();reset_dut();send(1,12'b000000011111);idle(2);endtask
endclass
class axi_timeout_recovery_sequence extends axi_timeout_base_sequence;
 `uvm_object_utils(axi_timeout_recovery_sequence) function new(string n="recovery");super.new(n);endfunction
 task body();reset_dut();aw();idle(8);w(1);b();aw();idle(4);w(1);b();idle(2);endtask
endclass
class axi_timeout_parallel_reset_sequence extends axi_timeout_base_sequence;
 `uvm_object_utils(axi_timeout_parallel_reset_sequence) function new(string n="parallel");super.new(n);endfunction
 task body();reset_dut();send(1,12'b110000011000);idle(4);send(0);send(0);send(1);idle(5);endtask
endclass
