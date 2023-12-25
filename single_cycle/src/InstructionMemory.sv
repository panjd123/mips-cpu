// `timescale 1ns / 1ps

`ifndef INSTRUCTION_MEMORY_SV
`define INSTRUCTION_MEMORY_SV
`include "common.vh"

module InstructionMemory(
    input Vec32 imAddress,
    output Instruction instruction
    );

    Vec32 memory [1023:0];

    initial
    begin
        $readmemh(`code_path, memory);
        // $display("Instruction Memory Loaded");
        // for (int i = 0; i < 60; i = i + 1) begin
        //     $display("memory[%d] = %h", i, memory[i]);
        // end
    end

    assign instruction.instructionCode = InstructionCode'(memory[imAddress[11:2]]);
    assign instruction.rs = memory[imAddress[11:2]][25:21];
    assign instruction.rt = memory[imAddress[11:2]][20:16];
    assign instruction.rd = memory[imAddress[11:2]][15:11];
    assign instruction.imm16 = memory[imAddress[11:2]][15:0];
    assign instruction.imm26 = memory[imAddress[11:2]][25:0];
    assign instruction.funct = memory[imAddress[11:2]][5:0];
    assign instruction.shamt = memory[imAddress[11:2]][10:6];

endmodule
`endif