`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2024 02:23:05 PM
// Design Name: 
// Module Name: CU_FSM
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


module CU_FSM(
    input rst,
    input clk,
    input [6:0] opcode, //this is called IR[6:0]
    input [2:0] funct3, //this is called IR[14:12], the exact instruction from the opcode series
    input intr, //interrupt

    //outputs
    output logic PC_WE,
    output logic RF_WE,
    output logic mem_WE2,
    output logic memRDEN1,
    output logic memRDEN2,
    output logic reset,

    ///not used
    output logic csr_WE,
    output logic int_taken,
    output logic mret_exec
    );
    
    typedef enum { ST_INIT, ST_FETCH, ST_EXEC, ST_WRITEBACK, ST_INTR } state_type;
    state_type NS, PS;

    //state reg
    always_ff @( posedge clk ) begin
        if (rst) PS <= ST_INIT;
        else PS <= NS;
    end


    always_comb begin
        //sets all outputs to 0 each clock cycle
        PC_WE  = 1'b0;//pc write en
        RF_WE  = 1'b0;//reg file write en
        mem_WE2  = 1'b0;//mem file write en 2
        memRDEN1  = 1'b0;//mem file read en instruction
        memRDEN2  = 1'b0;//mem file read en data
        reset  = 1'b0;//resets the PC
        csr_WE  = 1'b0;//write en for csr
        int_taken  = 1'b0;//csr int taken
        mret_exec  = 1'b0;//csr mret exec

        //case block
        case(PS)

            //init state
            ST_INIT: begin
                reset = 1'b1;
                NS = ST_FETCH;
            end

            //fetch state
            ST_FETCH: begin
                memRDEN1 = 1'b1;
                NS = ST_EXEC;
            end

            //exec state. most difficult state
            ST_EXEC: begin

                case(opcode)
                    // CSR type ///////////////////////////////////////////////////////////////////////////////
                    7'b1110011: begin
                        case(funct3)
                            //"mret"
                            3'b000: begin
                                PC_WE = 1;
                                mret_exec = 1'b1;
                            end
                            //"csrrw"
                            3'b001: begin
                                PC_WE = 1;
                                RF_WE = 1;
                                csr_WE = 1;
                            end
                            //"csrrs"
                            3'b010: begin
                                PC_WE = 1;
                                RF_WE = 1;
                                csr_WE = 1;
                            end
                            //"csrrc"
                            3'b011: begin
                                PC_WE = 1;
                                RF_WE = 1;
                                csr_WE = 1;
                            end
                        endcase
                        NS = (intr==1'b1) ? ST_INTR : ST_FETCH;
                    end

                    // R type /////////////////////////////////////////////////////////////////////////////////
                    7'b0110011: begin
                        PC_WE = 1;
                        RF_WE = 1;
                        NS = (intr==1'b1) ? ST_INTR : ST_FETCH;
                    end
                    
                    // I type /////////////////////////////////////////////////////////////////////////////////
                    7'b0010011: begin
                        PC_WE = 1;
                        RF_WE = 1;
                        NS = (intr==1'b1) ? ST_INTR : ST_FETCH;
                    end
                    7'b1100111: begin //jalr
                        PC_WE = 1;
                        RF_WE = 1;
                        NS = (intr==1'b1) ? ST_INTR : ST_FETCH;
                    end
                    7'b0000011: begin //load from memory instructions lw, lh, lhu
                        memRDEN2 = 1;
                        NS = ST_WRITEBACK;
                    end


                    // S type /////////////////////////////////////////////////////////////////////////////////
                    7'b0100011: begin
                        PC_WE = 1;
                        mem_WE2 = 1;
                        NS = (intr==1'b1) ? ST_INTR : ST_FETCH;
                    end

                    // B type /////////////////////////////////////////////////////////////////////////////////
                    7'b1100011: begin
                        PC_WE = 1;
                        NS = (intr==1'b1) ? ST_INTR : ST_FETCH;
                    end

                    // U type /////////////////////////////////////////////////////////////////////////////////
                    7'b0110111: begin
                        PC_WE = 1;
                        RF_WE = 1;
                        NS = (intr==1'b1) ? ST_INTR : ST_FETCH;
                        
                    end
                    7'b0010111: begin 
                        PC_WE = 1;
                        RF_WE = 1;
                        NS = (intr==1'b1) ? ST_INTR : ST_FETCH;
                    end

                    // J type /////////////////////////////////////////////////////////////////////////////////
                    7'b1101111: begin
                        PC_WE = 1;
                        RF_WE = 1;
                        NS = (intr==1'b1) ? ST_INTR : ST_FETCH;
                    end

                    default:NS = ST_INIT; //blank default
                endcase

            end

            ST_WRITEBACK: begin
                PC_WE = 1;
                RF_WE = 1;
                NS = (intr==1'b1) ? ST_INTR : ST_FETCH;
            end

            ST_INTR: begin
                PC_WE = 1;
                int_taken = 1'b1;
                NS = ST_FETCH;
            end

            default: NS = ST_INIT;
        endcase
    end

endmodule
