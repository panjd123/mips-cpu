`ifndef CONTROL_UNIT_SV
`define CONTROL_UNIT_SV

`include "common.vh"

module ControllerUnit(
    input Instruction instruction,
    output ControlSignal controlSignal
    );
    // 001111 10 0000 0000 0000 0000 1000
    always_comb begin : controlComb
        `init_control_signal(controlSignal);
        casex(instruction.instructionCode)
            NOP: begin
                // alreay initialized
            end
            ADD, ADDU, SUB, SUBU,
            SLL, SRL, SRA, SLLV, SRLV, SRAV,
            AND, OR,
            XOR, NOR, SLT, SLTU: begin
                controlSignal.gprReadIDSrc1 = gprRegisterSrc_RS;
                controlSignal.gprReadIDSrc2 = gprRegisterSrc_RT;
                controlSignal.gprResultRequiredStage1 = pipelineStage_EXECUTE;
                controlSignal.gprResultRequiredStage2 = pipelineStage_EXECUTE;
                // casex (instruction.instructionCode)
                //     SLL, SRL, SRA: controlSignal.gprResultRequiredStage2 = pipelineStage_NEVER;
                //     default: controlSignal.gprResultRequiredStage2 = pipelineStage_EXECUTE;
                // endcase
                // 对于 0 号寄存器，冒险检测（旁路）时跳过，所以此处统一不处理，下同。
                casex (instruction.instructionCode)
                    SLL, SRL, SRA: controlSignal.aluMduInputSrc1 = aluMduInputSrc_unsigned_shamt;
                    default: controlSignal.aluMduInputSrc1 = aluMduInputSrc_gpr1;
                endcase
                controlSignal.aluMduInputSrc2 = aluMduInputSrc_gpr2;
                controlSignal.aluOp = instruction.funct;
                controlSignal.gprWriteEnabled = 1'b1;
                controlSignal.gprWriteIDSrc = gprRegisterSrc_RD;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_aluResult;
            end
            ADDI, ADDIU, ANDI, ORI, XORI, SLTI, SLTIU: begin
                controlSignal.gprReadIDSrc1 = gprRegisterSrc_RS;
                controlSignal.gprResultRequiredStage1 = pipelineStage_EXECUTE;
                controlSignal.aluMduInputSrc1 = aluMduInputSrc_gpr1;
                casex (instruction.instructionCode)
                    ADDI, ADDIU, SLTI, SLTIU: controlSignal.aluMduInputSrc2 = aluMduInputSrc_signed_imm16;
                    ANDI, ORI: controlSignal.aluMduInputSrc2 = aluMduInputSrc_unsigned_imm16;
                endcase
                casex (instruction.instructionCode)
                    ADDI, ADDIU: controlSignal.aluOp = ALU_ADD;
                    ANDI: controlSignal.aluOp = ALU_AND;
                    ORI: controlSignal.aluOp = ALU_OR;
                    XORI: controlSignal.aluOp = ALU_XOR;
                    SLTI: controlSignal.aluOp = ALU_SLT;
                    SLTIU: controlSignal.aluOp = ALU_SLTU;
                endcase
                controlSignal.gprWriteEnabled = 1'b1;
                controlSignal.gprWriteIDSrc = gprRegisterSrc_RT;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_aluResult;
            end
            BEQ, BNE, BLEZ, BGTZ, BGEZ, BLTZ: begin
                controlSignal.gprReadIDSrc1 = gprRegisterSrc_RS;
                controlSignal.gprReadIDSrc2 = gprRegisterSrc_RT;
                controlSignal.gprResultRequiredStage1 = pipelineStage_DECODE;
                controlSignal.gprResultRequiredStage2 = pipelineStage_DECODE;
                // controlSignal.gprWriteEnabled = 1'b0;
                casex (instruction.instructionCode)
                    BEQ: controlSignal.pcJumpCondition = pcJumpCondition_eq;
                    BNE: controlSignal.pcJumpCondition = pcJumpCondition_ne;
                    BLEZ: controlSignal.pcJumpCondition = pcJumpCondition_le;
                    BGTZ: controlSignal.pcJumpCondition = pcJumpCondition_gt;
                    BGEZ: controlSignal.pcJumpCondition = pcJumpCondition_ge;
                    BLTZ: controlSignal.pcJumpCondition = pcJumpCondition_lt;
                endcase
                controlSignal.pcJumpMode = pcJumpMode_rel;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_signed_imm16_lshift_2;
            end
            LUI: begin
                controlSignal.gprWriteEnabled = 1'b1;
                controlSignal.gprWriteIDSrc = gprRegisterSrc_RT;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_imm16_lshift_16;
            end
            J, JAL: begin
                controlSignal.pcJumpMode = pcJumpMode_abs;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_unsigned_imm26_lshift_2;
                controlSignal.pcJumpCondition = pcJumpCondition_true;
                casex (instruction.instructionCode)
                    JAL: begin
                        controlSignal.gprWriteEnabled = 1'b1;
                        controlSignal.gprWriteIDSrc = gprRegisterSrc_RA;
                        controlSignal.gprWriteInputSrc = gprWriteInputSrc_pc_add_8;
                    end
                endcase
            end
            JR, JALR: begin
                controlSignal.gprReadIDSrc1 = gprRegisterSrc_RS;
                controlSignal.gprResultRequiredStage1 = pipelineStage_DECODE;
                controlSignal.pcJumpMode = pcJumpMode_reg;
                controlSignal.pcJumpInputSrc = pcJumpInputSrc_gpr_read1;
                controlSignal.pcJumpCondition = pcJumpCondition_true;
                casex (instruction.instructionCode)
                    JALR: begin
                        controlSignal.gprWriteEnabled = 1'b1;
                        controlSignal.gprWriteIDSrc = gprRegisterSrc_RA;
                        controlSignal.gprWriteInputSrc = gprWriteInputSrc_pc_add_8;
                    end 
                endcase
            end
            LB, LBU, LH, LHU, LW: begin
                controlSignal.gprReadIDSrc1 = gprRegisterSrc_RS;
                controlSignal.gprResultRequiredStage1 = pipelineStage_EXECUTE;
                controlSignal.aluMduInputSrc1 = aluMduInputSrc_gpr1;
                controlSignal.aluMduInputSrc2 = aluMduInputSrc_signed_imm16;
                controlSignal.aluOp = ALU_ADD;
                controlSignal.gprWriteEnabled = 1'b1;
                controlSignal.gprWriteIDSrc = gprRegisterSrc_RT;
                controlSignal.gprWriteInputSrc = gprWriteInputSrc_dmResult;
                casex (instruction.instructionCode)
                    LB: controlSignal.dmReadType = dmReadType_signed_1;
                    LBU: controlSignal.dmReadType = dmReadType_unsigned_1;
                    LH: controlSignal.dmReadType = dmReadType_signed_2;
                    LHU: controlSignal.dmReadType = dmReadType_unsigned_2;
                    LW: controlSignal.dmReadType = dmReadType_unsigned_4;
                endcase
            end
            SB, SH, SW: begin
                controlSignal.gprReadIDSrc1 = gprRegisterSrc_RS;
                controlSignal.gprReadIDSrc2 = gprRegisterSrc_RT;
                controlSignal.gprResultRequiredStage1 = pipelineStage_EXECUTE;
                controlSignal.gprResultRequiredStage2 = pipelineStage_MEMORY;
                controlSignal.aluMduInputSrc1 = aluMduInputSrc_gpr1;
                controlSignal.aluMduInputSrc2 = aluMduInputSrc_signed_imm16;
                controlSignal.aluOp = ALU_ADD;
                casex (instruction.instructionCode)
                    SB: controlSignal.dmWriteType = dmWriteType_1;
                    SH: controlSignal.dmWriteType = dmWriteType_2;
                    SW: controlSignal.dmWriteType = dmWriteType_4;
                endcase
            end
            // mdu related
        endcase
    end
endmodule

`endif