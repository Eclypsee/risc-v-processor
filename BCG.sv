`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2024 02:39:55 PM
// Design Name: 
// Module Name: BCG
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


module BCG(
    input [31:0] rs1,
    input [31:0] rs2,
    output br_eq,
    output br_lt,
    output br_ltu
    );

    assign br_eq = rs1 == rs2; // equal comparison
    assign br_lt = $signed(rs1) < $signed(rs2); // less than signed
    assign br_ltu = rs1 < rs2; // less than unsigned
endmodule

