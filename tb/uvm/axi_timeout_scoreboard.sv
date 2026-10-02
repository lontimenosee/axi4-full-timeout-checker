class axi_timeout_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi_timeout_scoreboard)
  uvm_analysis_imp #(axi_timeout_cycle_item,axi_timeout_scoreboard) analysis_export;
  int timeout_cycles=4, checked, errors;
  int ws, rs, awc,wc,bc,arc,rc; bit awrep,wrep,brep,arrep,rrep; bit [4:0] exp_status;
  localparam WI=0, WW=1, WB=2, RI=0, RR=1;
  function new(string name,uvm_component parent); super.new(name,parent); analysis_export=new("analysis_export",this); endfunction
  function void build_phase(uvm_phase phase); void'(uvm_config_db#(int)::get(this,"","timeout_cycles",timeout_cycles)); endfunction
  function void clear_model(); ws=WI;rs=RI;awc=0;wc=0;bc=0;arc=0;rc=0;awrep=0;wrep=0;brep=0;arrep=0;rrep=0;exp_status=0; endfunction
  function void write(axi_timeout_cycle_item t); bit exp_irq; exp_irq=0;
    if(!t.aresetn) clear_model();
    else begin
      case(ws)
        WI: begin wc=0;bc=0;wrep=0;brep=0;
          if(t.awvalid&&t.awready) begin awc=0;awrep=0; ws=(t.wvalid&&t.wready&&t.wlast)?WB:WW; end
          else if(t.awvalid) begin if(!awrep) if(awc==timeout_cycles-1) begin exp_status[0]=1;exp_irq=1;awrep=1;end else awc++; end
          else begin awc=0;awrep=0; end
        end
        WW: begin awc=0;bc=0;awrep=0;brep=0;
          if(t.wvalid&&t.wready) begin wc=0;if(t.wlast)begin wrep=0;ws=WB;end end
          else if(!wrep) if(wc==timeout_cycles-1)begin exp_status[1]=1;exp_irq=1;wrep=1;end else wc++;
        end
        WB: begin awc=0;wc=0;awrep=0;wrep=0;
          if(t.bvalid&&t.bready)begin bc=0;brep=0;ws=WI;end
          else if(!brep) if(bc==timeout_cycles-1)begin exp_status[2]=1;exp_irq=1;brep=1;end else bc++;
        end
      endcase
      case(rs)
        RI: begin rc=0;rrep=0;
          if(t.arvalid&&t.arready)begin arc=0;arrep=0;rs=(t.rvalid&&t.rready&&t.rlast)?RI:RR;end
          else if(t.arvalid)begin if(!arrep)if(arc==timeout_cycles-1)begin exp_status[3]=1;exp_irq=1;arrep=1;end else arc++;end
          else begin arc=0;arrep=0;end
        end
        RR: begin arc=0;arrep=0;
          if(t.rvalid&&t.rready)begin rc=0;if(t.rlast)begin rrep=0;rs=RI;end end
          else if(!rrep)if(rc==timeout_cycles-1)begin exp_status[4]=1;exp_irq=1;rrep=1;end else rc++;
        end
      endcase
    end
    checked++;
    if(t.timeout_status!==exp_status||t.timeout_irq!==exp_irq)begin errors++;`uvm_error("MISMATCH",$sformatf("cycle=%0d status exp=%05b got=%05b irq exp=%0b got=%0b",checked,exp_status,t.timeout_status,exp_irq,t.timeout_irq))end
  endfunction
  function void report_phase(uvm_phase phase);
    if(checked==0||errors!=0) `uvm_error("SCOREBOARD",$sformatf("checked=%0d errors=%0d",checked,errors))
    else `uvm_info("M4_PASS",$sformatf("scoreboard checked %0d cycles",checked),UVM_LOW)
  endfunction
endclass
