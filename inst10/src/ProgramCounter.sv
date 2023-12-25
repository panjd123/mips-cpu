`ifndef PROGRAM_COUNTER_SV
`define PROGRAM_COUNTER_SV

`include "common.vh"
module ProgramCounter(
    input reset,
    input clock,
    input logic stall,
    input logic jumpEnabled,
    input Vec32 pcJumpInput,
    output Vec32 pcValue,
    input integer file
    );
    Vec32 pcReg;
    assign pcValue = pcReg;
    always @(posedge clock) begin
        if(reset) begin
            pcReg <= `INIT_PC;
        end
        else begin
            if(!stall) begin
                if(jumpEnabled) begin
                    $fdisplay(file, "PC: %h -> %h", pcReg, pcJumpInput);
                    pcReg <= pcJumpInput;
                end
                else begin
                    pcReg <= pcReg + 4;
                end
            end
        end
    end
endmodule

`endif