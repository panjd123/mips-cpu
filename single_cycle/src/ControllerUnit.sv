`timescale 1ns / 1ps
`ifndef CONTROLLER_UNIT_SV
`define CONTROLLER_UNIT_SV

`include "common.vh"
module ControllerUnit(
    input Instruction instruction,
    output ControlSignal controlSignal
    );
    // 001111 10 0000 0000 0000 0000 1000
    always_comb begin : controlComb
        controlSignal.gprWriteEnabled = 0;
        controlSignal.dmWriteEnabled = 0;
        casex(instruction.instructionCode)
            add,addu,sub,subu: begin
                controlSignal.gprWriteRegisterSrc = gprWriteRegisterSrc_rd;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_aluResult;
                controlSignal.gprWriteEnabled = 1;
                controlSignal.aluInput1Src = aluInput1Src_gpr1;
                controlSignal.aluInput2Src = aluInput2Src_gpr2;
                controlSignal.aluOp = AluOp'(instruction.funct);
                controlSignal.dmWriteEnabled = 0;
                controlSignal.extSign = 0;
                controlSignal.pcJumpModeSrc = pcJumpModeSrc_next;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_0;
            end
            ori: begin
                controlSignal.gprWriteRegisterSrc = gprWriteRegisterSrc_rt;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_aluResult;
                controlSignal.gprWriteEnabled = 1;
                controlSignal.aluInput1Src = aluInput1Src_gpr1;
                controlSignal.aluInput2Src = aluInput2Src_ext;
                controlSignal.aluOp = OR;
                controlSignal.dmWriteEnabled = 0;
                controlSignal.extSign = 0;
                controlSignal.pcJumpModeSrc = pcJumpModeSrc_next;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_0;
            end
            lw: begin
                controlSignal.gprWriteRegisterSrc = gprWriteRegisterSrc_rt;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_dmResult;
                controlSignal.gprWriteEnabled = 1;
                controlSignal.aluInput1Src = aluInput1Src_gpr1;
                controlSignal.aluInput2Src = aluInput2Src_ext;
                controlSignal.aluOp = ADD;
                controlSignal.dmWriteEnabled = 0;
                controlSignal.extSign = 1;
                controlSignal.pcJumpModeSrc = pcJumpModeSrc_next;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_0;
            end
            sw: begin
                controlSignal.gprWriteRegisterSrc = gprWriteRegisterSrc_rd;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_aluResult;
                controlSignal.gprWriteEnabled = 0;
                controlSignal.aluInput1Src = aluInput1Src_gpr1;
                controlSignal.aluInput2Src = aluInput2Src_ext;
                controlSignal.aluOp = ADD;
                controlSignal.dmWriteEnabled = 1;
                controlSignal.extSign = 1;
                controlSignal.pcJumpModeSrc = pcJumpModeSrc_next;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_0;
            end
            beq: begin
                controlSignal.gprWriteRegisterSrc = gprWriteRegisterSrc_rd;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_aluResult;
                controlSignal.gprWriteEnabled = 0;
                controlSignal.aluInput1Src = aluInput1Src_gpr1;
                controlSignal.aluInput2Src = aluInput2Src_gpr2;
                controlSignal.aluOp = SUBU;
                controlSignal.dmWriteEnabled = 0;
                controlSignal.extSign = 1;
                controlSignal.pcJumpModeSrc = pcJumpModeSrc_beq;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_ext;
            end
            lui: begin
                controlSignal.gprWriteRegisterSrc = gprWriteRegisterSrc_rt;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_imm16;
                controlSignal.gprWriteEnabled = 1;
                controlSignal.aluInput1Src = aluInput1Src_gpr1;
                controlSignal.aluInput2Src = aluInput2Src_gpr2;
                controlSignal.aluOp = ADDU;
                controlSignal.dmWriteEnabled = 0;
                controlSignal.extSign = 0;
                controlSignal.pcJumpModeSrc = pcJumpModeSrc_next;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_0;
            end
            j: begin
                controlSignal.gprWriteRegisterSrc = gprWriteRegisterSrc_ra;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_aluResult;
                controlSignal.gprWriteEnabled = 0;
                controlSignal.aluInput1Src = aluInput1Src_pc;
                controlSignal.aluInput2Src = aluInput2Src_4;
                controlSignal.aluOp = ADDU;
                controlSignal.dmWriteEnabled = 0;
                controlSignal.extSign = 0;
                controlSignal.pcJumpModeSrc = pcJumpModeSrc_abs;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_imm26;
            end
            jal: begin
                controlSignal.gprWriteRegisterSrc = gprWriteRegisterSrc_ra;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_aluResult;
                controlSignal.gprWriteEnabled = 1;
                controlSignal.aluInput1Src = aluInput1Src_pc;
                controlSignal.aluInput2Src = aluInput2Src_4;
                controlSignal.aluOp = ADDU;
                controlSignal.dmWriteEnabled = 0;
                controlSignal.extSign = 0;
                controlSignal.pcJumpModeSrc = pcJumpModeSrc_abs;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_imm26;
            end
            jr: begin
                controlSignal.gprWriteRegisterSrc = gprWriteRegisterSrc_rt;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_aluResult;
                controlSignal.gprWriteEnabled = 0;
                controlSignal.aluInput1Src = aluInput1Src_gpr1;
                controlSignal.aluInput2Src = aluInput2Src_gpr2;
                controlSignal.aluOp = ADDU;
                controlSignal.dmWriteEnabled = 0;
                controlSignal.extSign = 0;
                controlSignal.pcJumpModeSrc = pcJumpModeSrc_absreg;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_gpr;
            end
            syscall: begin
                controlSignal.gprWriteRegisterSrc = gprWriteRegisterSrc_ra;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_aluResult;
                controlSignal.gprWriteEnabled = 1;
                controlSignal.aluInput1Src = aluInput1Src_gpr1;
                controlSignal.aluInput2Src = aluInput2Src_gpr2;
                controlSignal.aluOp = ADDU;
                controlSignal.dmWriteEnabled = 0;
                controlSignal.extSign = 0;
                controlSignal.pcJumpModeSrc = pcJumpModeSrc_abs;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_imm26;
            end
        endcase
    end
endmodule

`endif
