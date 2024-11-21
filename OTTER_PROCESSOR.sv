`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2024 04:52:37 PM
// Design Name: 
// Module Name: OTTER_PROCESSOR
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


module OTTER_PROCESSOR(
    input RST,
    input INTR,
    input clk,
    input [31:0] IOBUS_IN,

    output IOBUS_WR,
    output [31:0] IOBUS_OUT,
    output [31:0] IOBUS_ADDR
    );

    //immed gen and regfile io
    logic [31:0] rs1;
    logic [31:0] rs2;
    logic [31:0] U;
    logic [31:0] I;
    logic [31:0] S;
    logic [31:0] J;
    logic [31:0] B;
    logic [1:0] RF_SEL;
    logic RF_WE;

    //pc and +4 module io
    logic PC_RST;             // Reset signal
    logic PC_WE;              // Write enable signal
    logic [31:0] JALR;        // 32-bit JALR logic
    logic [31:0] BRANCH;      // 32-bit Branch target logic
    logic [31:0] JAL;         // 32-bit JAL logic
    logic [31:0] MTVEC;       // 32-bit Machine trap-vector base address (MTVEC)
    logic [31:0] MEPC;        // 32-bit Machine exception program counter (MEPC)
    logic [2:0] PC_SEL;       // 3-bit selection signal for the MUX

    logic [31:0] PC_COUNT;   // 32-bit Program Counter output
    logic [31:0] PC_PLUS_FOUR; // 32-bit PC + 4 output

    //memory file io
    logic [31:0] IR;            //DOUT_1 instruction
    logic mem_WE2;
    logic memRDEN1;
    logic memRDEN2;
    logic [31:0] DOUT2;

    //alu io
    logic [3:0] ALU_FUN;
    logic [1:0] srcA_SEL;
    logic [2:0] srcB_SEL;
    logic [31:0] ALU_RESULT;
    logic [31:0] NOT_rs1;

    //csr unused stuff////////////////////////////////////////////////////////
    logic csr_WE;
    logic int_taken;
    logic mret_exec;
    logic [31:0] csr_RD;
    logic mstatus_3;
    /////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////PROGRAM COUNTER AND +4////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //"intermediates"
    logic [31:0] PC_MUX_OUT;    // Intermediate signal for the PC MUX output
    logic [31:0] PC_COUNT_OUT;  // Intermediate signal for the PC COUNT register output
    logic [31:0] ADD_FOUR_OUT;  // Intermediate signal for the ADD_FOUR module output
    // Instantiate the ADD_FOUR module
    ADD_FOUR ADD_FOUR (.IN(PC_COUNT_OUT), .OUT(ADD_FOUR_OUT));
    // Assign the output of ADD_FOUR to PC_PLUS_FOUR
    assign PC_PLUS_FOUR = ADD_FOUR_OUT;
    // Instantiate the PC_MUX module
    PC_MUX PC_MUX(.add_four(ADD_FOUR_OUT), .jalr(JALR), .branch(BRANCH), .jal(JAL), .mtvec(MTVEC), .mepc(MEPC), .PC_SEL(PC_SEL), .OUT(PC_MUX_OUT));
    // Instantiate the PC module (32-bit register)
    PC PC(.PC_DIN(PC_MUX_OUT), .clk(clk), .PC_WE(PC_WE), .PC_RST(PC_RST), .PC_COUNT(PC_COUNT_OUT));
    // assign output of PC
    assign PC_COUNT = PC_COUNT_OUT;
    
     //////////////////////////////////////////////////////////////////////////////////////////////////////////////
     ////////////////////////////////////////////// CSR ///////////////////////////////////////////////////////////
     //////////////////////////////////////////////////////////////////////////////////////////////////////////////

    CSR CSR(.reset(PC_RST), .mret_exec(mret_exec), .int_taken(int_taken), .ADDR(IR[31:20]), .csr_WE(csr_WE), .PC(PC_COUNT_OUT), .WD(ALU_RESULT), .clk(clk), .mstatus_3(mstatus_3), .mepc(MEPC), .mtvec(MTVEC), .RD(csr_RD));
    assign INTR_FSM = INTR & mstatus_3;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// THE ALU ////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //internals for the alu
    logic [31:0] ALU_srcA;
    logic [31:0] ALU_srcB;
    assign NOT_rs1 = ~rs1;
    ALU_SRCA_MUX ALU_SRCA_MUX(.rs1(rs1), .Utype(U), .NOT_rs1(NOT_rs1), .srcA_SEL(srcA_SEL), .ALU_srcA(ALU_srcA));
    ALU_SRCB_MUX ALU_SRCB_MUX(.rs2(rs2), .Itype(I), .Stype(S), .PC(PC_COUNT), .csr_RD(csr_RD), .srcB_SEL(srcB_SEL), .ALU_srcB(ALU_srcB));
    ALU ALU(.srcA(ALU_srcA), .srcB(ALU_srcB), .alu_fun(ALU_FUN), .alu_result(ALU_RESULT));
    assign IOBUS_ADDR = ALU_RESULT;
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////REG FILE, IMMED GEN, BAG////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////

    logic [31:0] w_data;
    REG_FILE_MUX REG_FILE_MUX(.pc_plus_four(PC_PLUS_FOUR), .csr_rd(csr_RD), .dout2(DOUT2), .alu_result(ALU_RESULT), .RF_SEL(RF_SEL), .OUT(w_data));
    REG_FILE REG_FILE(.en(RF_WE), .adr1(IR[19:15]), .adr2(IR[24:20]), .w_adr(IR[11:7]), .w_data(w_data), .clk(clk), .rs1(rs1), .rs2(rs2));
    IMMED_GEN IMMED_GEN(.IR(IR[31:7]), .U(U), .I(I), .S(S), .J(J), .B(B));
    BAG BAG(.PC(PC_COUNT), .J_type(J), .B_type(B), .I_type(I), .rs1(rs1), .jal(JAL), .branch(BRANCH), .jalr(JALR));
    assign IOBUS_OUT = rs2;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////// MEMORY FILE ///////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    Memory Memory(.MEM_CLK(clk), .MEM_RDEN1(memRDEN1), .MEM_RDEN2(memRDEN2), .MEM_WE2(mem_WE2), .MEM_ADDR1(PC_COUNT[15:2]), .MEM_ADDR2(ALU_RESULT), .MEM_DIN2(rs2), .MEM_SIZE(IR[13:12]), .MEM_SIGN(IR[14]), .IO_IN(IOBUS_IN), .IO_WR(IOBUS_WR), .MEM_DOUT1(IR), .MEM_DOUT2(DOUT2));

    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////CONTROL UNIT DECODER AND FSM AND BCG/////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // recall format .nameInFile(InternalSignal)

    //intermediates for bcg and cu dcdr
    logic br_lt;
    logic br_ltu;
    logic br_eq;
    BCG BCG(.rs1(rs1), .rs2(rs2), .br_eq(br_eq), .br_lt(br_lt), .br_ltu(br_ltu));
    CU_DCDR CU_DCDR(.opcode(IR[6:0]), .funct3(IR[14:12]), .ir_30(IR[30]), .int_taken(int_taken), .br_eq(br_eq), .br_lt(br_lt), .br_ltu(br_ltu), .ALU_FUN(ALU_FUN), .srcA_SEL(srcA_SEL), .srcB_SEL(srcB_SEL), .PC_SEL(PC_SEL), .RF_SEL(RF_SEL));
    CU_FSM CU_FSM(.rst(RST), .clk(clk), .opcode(IR[6:0]), .funct3(IR[14:12]), .intr(INTR_FSM), .PC_WE(PC_WE), .RF_WE(RF_WE), .mem_WE2(mem_WE2), .memRDEN1(memRDEN1), .memRDEN2(memRDEN2), .reset(PC_RST), .csr_WE(csr_WE), .int_taken(int_taken), .mret_exec(mret_exec));

endmodule
