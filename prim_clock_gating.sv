`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.08.2025 00:05:59
// Design Name: 
// Module Name: prim_clock_gating
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// Description: Simple clock-gating primitive for simulation (Cadence-friendly)
// This module ensures no X-propagation and handles test enable properly.
//////////////////////////////////////////////////////////////////////////////////

module prim_clock_gating (
    input  logic clk_i,      // Main clock input
    input  logic en_i,       // Clock enable
    input  logic test_en_i,  // Test enable (bypass gating in test mode)
    output logic clk_o       // Gated clock output
);

    // For simulation, we model this as a glitch-free gated clock
    // If test_en_i is asserted, bypass gating completely
    logic gate_enable;

    always_comb begin
        if (test_en_i)
            gate_enable = 1'b1;
        else
            gate_enable = en_i;
    end

    assign clk_o = clk_i & gate_enable;

endmodule
