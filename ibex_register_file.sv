// Copyright lowRISC contributors.
// Copyright 2018 ETH Zurich and University of Bologna, see also CREDITS.md.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * RISC-V register file
 *
 * Register file with 31 or 15x 32 bit wide registers. Register 0 is fixed to 0.
 * This register file is based on flip flops. Use this register file when
 * targeting FPGA synthesis or Verilator simulation.
 */
module ibex_register_file #(
    parameter bit RV32E              = 0,
    parameter [31:0] DataWidth = 32
) (
    // Clock and Reset
    input  logic                 clk_i,
    input  logic                 rst_ni,

    input  logic                 test_en_i,

    //Read port R1
    input  logic [4:0]           raddr_a_i,
    output logic [DataWidth-1:0] rdata_a_o,

    //Read port R2
    input  logic [4:0]           raddr_b_i,
    output logic [DataWidth-1:0] rdata_b_o,


    // Write port W1
    input  logic [4:0]           waddr_a_i,
    input  logic [DataWidth-1:0] wdata_a_i,
    input  logic                 we_a_i

);

  localparam [31:0] ADDR_WIDTH = RV32E ? 4 : 5;
  localparam [31:0] NUM_WORDS  = 2**ADDR_WIDTH;

  logic [NUM_WORDS-1:0][DataWidth-1:0] rf_reg;
  logic [NUM_WORDS-1:1][DataWidth-1:0] rf_reg_tmp;
  logic [NUM_WORDS-1:1]                we_a_dec;


  logic [DataWidth-1:0] r0, r1, r2, r3, r4, r5, r6, r7, r8, r9,
                        r10, r11, r12, r13, r14, r15, r16, r17,
                        r18, r19, r20, r21, r22, r23, r24, r25,
                        r26, r27, r28, r29, r30, r31;
  assign r0 = rf_reg[0];
  assign r1 = rf_reg[1];
  assign r2 = rf_reg[2];
  assign r3 = rf_reg[3];
  assign r4 = rf_reg[4];
  assign r5 = rf_reg[5];
  assign r6 = rf_reg[6];
  assign r7 = rf_reg[7];
  assign r8 = rf_reg[8];
  assign r9 = rf_reg[9];
  assign r10 = rf_reg[10];
  assign r11 = rf_reg[11];
  assign r12 = rf_reg[12];
  assign r13 = rf_reg[13];
  assign r14 = rf_reg[14];
  assign r15 = rf_reg[15];
  assign r16 = rf_reg[16];
  assign r17 = rf_reg[17];
  assign r18 = rf_reg[18];
  assign r19 = rf_reg[19];
  assign r20 = rf_reg[20];
  assign r21 = rf_reg[21];
  assign r22 = rf_reg[22];
  assign r23 = rf_reg[23];
  assign r24 = rf_reg[24];
  assign r25 = rf_reg[25];
  assign r26 = rf_reg[26];
  assign r27 = rf_reg[27];
  assign r28 = rf_reg[28];
  assign r29 = rf_reg[29];
  assign r30 = rf_reg[30];
  assign r31 = rf_reg[31];

  always @(waddr_a_i, we_a_i) begin : we_a_decoder
    for (int i = 1; i < NUM_WORDS; i++) begin
      we_a_dec[i] = (waddr_a_i == 5'(i)) ?  we_a_i : 1'b0;
    end
  end

  // loop from 1 to NUM_WORDS-1 as R0 is nil
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rf_reg_tmp <= '0;
    end else begin
      for (int r = 1; r < NUM_WORDS; r++) begin
        if (we_a_dec[r]) rf_reg_tmp[r] <= wdata_a_i;
      end
    end
  end

  // R0 is nil
  assign rf_reg[0] = '0;
  assign rf_reg[NUM_WORDS-1:1] = rf_reg_tmp[NUM_WORDS-1:1];

  assign rdata_a_o = rf_reg[raddr_a_i];
  assign rdata_b_o = rf_reg[raddr_b_i];

endmodule
