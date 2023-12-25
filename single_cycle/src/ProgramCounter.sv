`timescale 1ns / 1ps

`ifndef PROGRAM_COUNTER_SV
`define PROGRAM_COUNTER_SV
`include "common.vh"
`define INIT_PC 32'h00003000
module ProgramCounter(
    input reset,
    input clock,
    input Vec2 pcJumpMode,
    input Vec32 pcJumpInput,
    output Vec32 pcValue
    );
    Vec32 pcReg;
    assign pcValue = pcReg;
    always @(posedge clock) begin
        if(reset) begin
            pcReg <= `INIT_PC;
        end
        else begin
            case(pcJumpMode)
                2'b00: pcReg <= pcReg + 4;
                2'b01: pcReg <= pcReg + 4 + {pcJumpInput[29:0], 2'b00};       // relative address
                2'b10: pcReg <= {pcReg[31:28], pcJumpInput[25:0], 2'b00}; // absolute address
                2'b11: pcReg <= pcJumpInput;                              // jump to address
            endcase
        end
    end
endmodule
`endif