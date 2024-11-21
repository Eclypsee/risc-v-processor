`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2024 03:54:58 PM
// Design Name: 
// Module Name: CSR
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


module CSR(
    input reset,
    input mret_exec, //return exec
    input int_taken, //interrupt taken
    input[31:20] ADDR, //write addresss
    input csr_WE, //enable writing
    input [31:0] PC, //current pc
    input [31:0] WD, //write data
    input clk,

    output mstatus_3, //address 0x300 in the CSR memory
    output [31:0] mepc,//address 0x341 in the CSR memory
    output [31:0] mtvec, //addresss 0x305 in the CSR memory
    output logic [31:0] RD
    );

    // Create a memory module with 32-bit width and 4096(12 bit) addresses
    logic [31:0] register [0:2];
    // Initialize the memory to be all 0s
    initial begin
        int i;
        for (i=0; i<3; i=i+1) begin
            register[i] = 0;
        end
    end

    assign mstatus_3 = register[0][3];
    assign mepc = register[1];
    assign mtvec = register[2];

    always_comb begin
        case(ADDR)
            32'h300: RD <= register[0];
            32'h341: RD <= register[1];
            32'h305: RD <= register[2];
            default: RD <= 32'hdeadbeef;
        endcase
    end

    always_ff @(posedge clk) begin
        if(reset) begin
            int i;
            for (i=0; i<3; i=i+1) begin
                register[i] <= 0;
            end
        end
        if(mret_exec)begin
            register[0][3] <= register[0][7]; // Restore MIE from MPIE
            register[0][7] <= 1'b0;           // Clear MPIE
        end
        if(int_taken)begin
            register[0][7] <= register[0][3]; // Save current MIE to MPIE
            register[0][3] <= 1'b0;           // Disable MIE (interrupts globally disabled)
            register[1] <= PC;
        end
        if (csr_WE) begin
            case(ADDR)
            32'h300: register[0] <= WD;
            32'h341: register[1] <= WD;
            32'h305: register[2] <= WD;
            endcase
        end
    end

endmodule
