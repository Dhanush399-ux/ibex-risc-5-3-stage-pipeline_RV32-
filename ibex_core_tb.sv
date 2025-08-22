// Disable RVFI to avoid port issues
`undef RVFI

module ibex_core_tb;

  // Import IBEX package (might be needed)
  // import ibex_pkg::*;
  // Clock and reset
  logic clk;
  logic rst_n;
  
  // Test enable
  logic test_en;
  
  // Hart ID and boot address
  logic [31:0] hart_id;
  logic [31:0] boot_addr;
  
  // Instruction memory interface
  logic        instr_req;
  logic        instr_gnt;
  logic        instr_rvalid;
  logic [31:0] instr_addr;
  logic [31:0] instr_rdata;
  logic        instr_err;
  
  // Data memory interface
  logic        data_req;
  logic        data_gnt;
  logic        data_rvalid;
  logic        data_we;
  logic [3:0]  data_be;
  logic [31:0] data_addr;
  logic [31:0] data_wdata;
  logic [31:0] data_rdata;
  logic        data_err;
  
  // Interrupt inputs
  logic        irq_software;
  logic        irq_timer;
  logic        irq_external;
  logic [14:0] irq_fast;
  logic        irq_nm;
  
  // Debug interface
  logic        debug_req;
  
  // RVFI (RISC-V Formal Interface) signals - only if RVFI is defined
`ifdef RVFI
  logic        rvfi_valid;
  logic [63:0] rvfi_order;
  logic [31:0] rvfi_insn;
  logic        rvfi_trap;
  logic        rvfi_halt;
  logic        rvfi_intr;
  logic [ 1:0] rvfi_mode;
  logic [ 4:0] rvfi_rs1_addr;
  logic [ 4:0] rvfi_rs2_addr;
  logic [31:0] rvfi_rs1_rdata;
  logic [31:0] rvfi_rs2_rdata;
  logic [ 4:0] rvfi_rd_addr;
  logic [31:0] rvfi_rd_wdata;
  logic [31:0] rvfi_pc_rdata;
  logic [31:0] rvfi_pc_wdata;
  logic [31:0] rvfi_mem_addr;
  logic [ 3:0] rvfi_mem_rmask;
  logic [ 3:0] rvfi_mem_wmask;
  logic [31:0] rvfi_mem_rdata;
  logic [31:0] rvfi_mem_wdata;
`endif
  
  // CPU control signals
  logic        fetch_enable;
  logic        core_sleep;
  logic        ebrk_insn;

  // Instantiate IBEX core
  ibex_core #(
    .PMPEnable(1'b0),           // Disable PMP for simplicity
    .PMPGranularity(0),
    .PMPNumRegions(4),
    .MHPMCounterNum(0),
    .MHPMCounterWidth(40),
    .RV32E(1'b0),              // Use RV32I (not RV32E)
    .RV32M(1'b1),              // Enable multiply/divide
    .DmHaltAddr(32'h1A110800),
    .DmExceptionAddr(32'h1A110808)
  ) uut (
    // Clock and Reset
    .clk_i(clk),
    .rst_ni(rst_n),
    
    .test_en_i(test_en),
    
    .hart_id_i(hart_id),
    .boot_addr_i(boot_addr),
    
    // Instruction memory interface
    .instr_req_o(instr_req),
    .instr_gnt_i(instr_gnt),
    .instr_rvalid_i(instr_rvalid),
    .instr_addr_o(instr_addr),
    .instr_rdata_i(instr_rdata),
    .instr_err_i(instr_err),
    
    // Data memory interface
    .data_req_o(data_req),
    .data_gnt_i(data_gnt),
    .data_rvalid_i(data_rvalid),
    .data_we_o(data_we),
    .data_be_o(data_be),
    .data_addr_o(data_addr),
    .data_wdata_o(data_wdata),
    .data_rdata_i(data_rdata),
    .data_err_i(data_err),
    
    // Interrupt inputs
    .irq_software_i(irq_software),
    .irq_timer_i(irq_timer),
    .irq_external_i(irq_external),
    .irq_fast_i(irq_fast),
    .irq_nm_i(irq_nm),
    
    // Debug interface
    .debug_req_i(debug_req),
    
    // RVFI signals (only if RVFI is enabled)
`ifdef RVFI
    .rvfi_valid(rvfi_valid),
    .rvfi_order(rvfi_order),
    .rvfi_insn(rvfi_insn),
    .rvfi_trap(rvfi_trap),
    .rvfi_halt(rvfi_halt),
    .rvfi_intr(rvfi_intr),
    .rvfi_mode(rvfi_mode),
    .rvfi_rs1_addr(rvfi_rs1_addr),
    .rvfi_rs2_addr(rvfi_rs2_addr),
    .rvfi_rs1_rdata(rvfi_rs1_rdata),
    .rvfi_rs2_rdata(rvfi_rs2_rdata),
    .rvfi_rd_addr(rvfi_rd_addr),
    .rvfi_rd_wdata(rvfi_rd_wdata),
    .rvfi_pc_rdata(rvfi_pc_rdata),
    .rvfi_pc_wdata(rvfi_pc_wdata),
    .rvfi_mem_addr(rvfi_mem_addr),
    .rvfi_mem_rmask(rvfi_mem_rmask),
    .rvfi_mem_wmask(rvfi_mem_wmask),
    .rvfi_mem_rdata(rvfi_mem_rdata),
    .rvfi_mem_wdata(rvfi_mem_wdata),
`endif
    
    // CPU control signals
    .fetch_enable_i(fetch_enable),
    .core_sleep_o(core_sleep),
    .ebrk_insn_o(ebrk_insn)
    
    // Note: RVFI signals are ifdef'd out, so not connected
  );
  
  // Simple memory models
  // Instruction memory - always grant requests
  assign instr_gnt = instr_req;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      instr_rvalid <= 1'b0;
    end else begin
      instr_rvalid <= instr_req && instr_gnt;
    end
  end
  
  // Instruction memory with our test program
  logic [31:0] instruction_memory [0:255]; // 256 words of instruction memory
  
  // Initialize instruction memory with our test program
  initial begin
    // Initialize all locations to NOP first
    for (int i = 0; i < 256; i++) begin
      instruction_memory[i] = 32'h00000013; // NOP
    end
    
    // Load our test program
    instruction_memory[0]  = 32'h00A00093; // addi x1, x0, 10
    instruction_memory[1]  = 32'h01400113; // addi x2, x0, 20
    instruction_memory[2]  = 32'h002081B3; // add  x3, x1, x2  
    instruction_memory[3]  = 32'h00518213; // addi x4, x3, 5
    instruction_memory[4]  = 32'h00000013; // nop
    instruction_memory[5]  = 32'h00000013; // nop
    instruction_memory[6]  = 32'h00000063; // beq  x0, x0, 0 (infinite loop)
    
    $display("Instruction memory loaded with test program");
  end
  
  // Memory read logic
  assign instr_rdata = instruction_memory[instr_addr[9:2]]; // Word-aligned access
  
  // Data memory - always grant requests  
  assign data_gnt = data_req;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_rvalid <= 1'b0;
    end else begin
      data_rvalid <= data_req && data_gnt;
    end
  end
  
  // Simple data memory (just return zeros)
  assign data_rdata = 32'h00000000;
  
  // Tie off error signals
  assign instr_err = 1'b0;
  assign data_err = 1'b0;
  
  // Initialize control signals
  assign hart_id = 32'h00000000;
  assign boot_addr = 32'h00000000;
  assign test_en = 1'b0;
  assign fetch_enable = 1'b1;  // Enable fetching
  
  // Initialize interrupt signals
  assign irq_software = 1'b0;
  assign irq_timer = 1'b0;
  assign irq_external = 1'b0;
  assign irq_fast = 15'h0;
  assign irq_nm = 1'b0;
  assign debug_req = 1'b0;
  
  // Clock generation (100 MHz)
  initial clk = 0;
  always #5 clk = ~clk;
  
  // Reset and stimulus
  initial begin
    $display("Starting IBEX Core Testbench with Test Program");
    
    // Reset sequence
    rst_n = 0;
    #100;
    rst_n = 1;
    $display("Reset released at time %0t", $time);
    
    // Let it run longer to see our program execute
    #10000;
    
    $display("Simulation completed at time %0t", $time);
    $finish;
  end
  
  // Enhanced monitoring with instruction decode
  always @(posedge clk) begin
    if (rst_n && instr_req) begin
      $display("Time %0t: Fetching instruction from address 0x%08h = 0x%08h", 
               $time, instr_addr, instr_rdata);
      
      // Simple instruction decode for monitoring
      case (instr_rdata[6:0])
        7'b0010011: begin // I-type (ADDI)
          if (instr_rdata[14:12] == 3'b000) begin
            $display("  -> ADDI x%0d, x%0d, %0d", 
                     instr_rdata[11:7], instr_rdata[19:15], 
                     $signed(instr_rdata[31:20]));
          end
        end
        7'b0110011: begin // R-type (ADD)
          if (instr_rdata[31:25] == 7'b0000000 && instr_rdata[14:12] == 3'b000) begin
            $display("  -> ADD x%0d, x%0d, x%0d", 
                     instr_rdata[11:7], instr_rdata[19:15], instr_rdata[24:20]);
          end
        end
        7'b1100011: begin // B-type (BEQ)
          if (instr_rdata[14:12] == 3'b000) begin
            $display("  -> BEQ x%0d, x%0d, offset=%0d", 
                     instr_rdata[19:15], instr_rdata[24:20], 
                     $signed({instr_rdata[31], instr_rdata[7], instr_rdata[30:25], instr_rdata[11:8], 1'b0}));
          end
        end
        7'b0010011: begin
          if (instr_rdata == 32'h00000013) begin
            $display("  -> NOP");
          end
        end
        default: $display("  -> Unknown instruction: 0x%08h", instr_rdata);
      endcase
    end
    
    if (rst_n && data_req) begin
      $display("Time %0t: Data request to address 0x%08h, WE=%b", $time, data_addr, data_we);
    end
  end

endmodule
