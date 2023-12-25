`ifndef INSTRUCTION_FETCH_SV
`define INSTRUCTION_FETCH_SV
`include "common.vh"
`include "ProgramCounter.sv"
`include "InstructionMemory.sv"

module InstructionFetch(
    input logic reset,
    input logic clock,
    input logic jumpEnabled,
    input Vec32 pcJumpInput,
    input logic stallID,
    input logic stallEX,
    output IF_ID_REG IF_ID_REG_value,
    input integer file
    );
    integer cnt;
    initial begin
        cnt = 0;
    end
    Vec32 pcValue;
    Instruction instruction;

    assign stall = stallID || stallEX;

    ProgramCounter u_ProgramCounter(
        .reset       (reset       ),
        .clock       (clock       ),
        .stall       (stall       ),
        .jumpEnabled (jumpEnabled ),
        .pcJumpInput (pcJumpInput ),
        .pcValue     (pcValue     ),
        .file        (file        )
    );

    InstructionMemory u_InstructionMemory(
    	.imAddress   (pcValue   ),
        .instruction (instruction )
    );
    
    always_ff @(posedge clock) begin
        if(reset) begin
            IF_ID_REG_value.pcValue <= 32'h00000000;
            `init_instruction_unblocking(IF_ID_REG_value.instruction);
        end
        else if (!stall) begin 
            IF_ID_REG_value.pcValue <= pcValue;
            IF_ID_REG_value.instruction <= instruction;
        end

        if(!reset) begin
            cnt = cnt + 1;
            $fdisplay(file, "IF(%d): @%h: %h", cnt, pcValue, instruction.instructionCode);
            $fdisplay(file, "rs, rt, rd: %d, %d, %d", instruction.rs, instruction.rt, instruction.rd);
            $fdisplay(file, "imm16: %h", instruction.imm16);
            $fdisplay(file, "shamt: %h", instruction.shamt);
            $fdisplay(file, "stallID: %b\tstallEX: %b", stallID, stallEX);
            $fdisplay(file, "");
        end
    end

endmodule
`endif