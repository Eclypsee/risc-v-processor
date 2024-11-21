`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2024 03:56:48 PM
// Design Name: 
// Module Name: ADD_FOUR
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

module ADD_FOUR (
    input [31:0] IN,    // 32-bit input input
    output [31:0] OUT   // 32-bit output incremented by 4
    );
    
    // Assigns output to input+4
    assign OUT = IN + 32'h4;
endmodule
