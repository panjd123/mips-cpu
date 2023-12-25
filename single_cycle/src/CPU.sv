// `timescale 1ns / 1ps
`ifndef CPU_SV
`define CPU_SV

`include "common.vh"
`include "ArithmeticLogicUnit.sv"
`include "ProgramCounter.sv"
`include "InstructionMemory.sv"
`include "GeneralPurposeRegisters.sv"
`include "ControllerUnit.sv"
`include "DataMemory.sv"
`include "Extender.sv"

module TopLevel(
    input logic reset,
    input logic clock
    );

    Vec32 aluInput1, aluInput2, aluResult;
    Vec6 aluOp;
    logic aluOver, aluZero;
    ArithmeticLogicUnit u_ArithmeticLogicUnit(
    	.aluInput1 (aluInput1 ),
        .aluInput2 (aluInput2 ),
        .aluOp     (aluOp     ),
        .aluResult (aluResult ),
        .aluOver   (aluOver   ),
        .aluZero   (aluZero   )
    );
    
    Vec2 pcJumpMode;
    Vec32 pcJumpInput;
    Vec32 pcValue;
    ProgramCounter u_ProgramCounter(
    	.reset       (reset       ),
        .clock       (clock       ),
        .pcJumpMode  (pcJumpMode  ),
        .pcJumpInput (pcJumpInput ),
        .pcValue     (pcValue     )
    );

    Vec5 gprReadRegister1, gprReadRegister2, gprWriteRegister;
    logic gprWriteEnabled;
    Vec32 gprWriteInput, gprResult1, gprResult2;
    GeneralPurposeRegisters u_GeneralPurposeRegisters(
    	.reset            (reset            ),
        .clock            (clock            ),
        .gprReadRegister1 (gprReadRegister1 ),
        .gprReadRegister2 (gprReadRegister2 ),
        .gprWriteRegister (gprWriteRegister ),
        .gprWriteEnabled  (gprWriteEnabled  ),
        .gprWriteInput    (gprWriteInput    ),
        .gprResult1       (gprResult1       ),
        .gprResult2       (gprResult2       )
    );
    
    Instruction instruction;
    InstructionMemory u_InstructionMemory(
    	.imAddress   (pcValue   ),
        .instruction (instruction )
    );

    ControlSignal controlSignal;
    ControllerUnit u_ControllerUnit(
    	.instruction   (instruction   ),
        .controlSignal (controlSignal )
    );

    Vec32 dmAddress, dmWriteInput, dmReadResult;
    logic dmWriteEnabled;
    DataMemory u_DataMemory(
    	.reset          (reset          ),
        .clock          (clock          ),
        .dmAddress      (dmAddress      ),
        .dmWriteEnabled (dmWriteEnabled ),
        .dmWriteInput   (dmWriteInput   ),
        .dmReadResult   (dmReadResult   )
    );

    Vec32 extResult;
    logic extSign;
    Extender u_Extender(
    	.extInput  (instruction.imm16  ),
        .extSign   (extSign   ),
        .extResult (extResult )
    );    

    assign gprReadRegister1 = instruction.rs;
    assign gprReadRegister2 = instruction.rt;
    assign dmAddress = aluResult;
    assign dmWriteInput = gprResult2;

    always_comb begin : gprWriteRegisterComb
        case(controlSignal.gprWriteRegisterSrc)
            gprWriteRegisterSrc_rt: gprWriteRegister = instruction.rt;
            gprWriteRegisterSrc_rd: gprWriteRegister = instruction.rd;
            gprWriteRegisterSrc_ra: gprWriteRegister = 5'b11111;
        endcase
    end

    always_comb begin : gprWriteInputComb
        case(controlSignal.gprWriteInputSrc)
            gprWriteInputSrc_aluResult: gprWriteInput = aluResult;
            gprWriteInputSrc_dmResult: gprWriteInput = dmReadResult;
            gprWriteInputSrc_imm16: gprWriteInput = {instruction.imm16,{16{1'b0}}};
        endcase
    end

    assign gprWriteEnabled = controlSignal.gprWriteEnabled;

    always_comb begin : aluInput1Comb
        case(controlSignal.aluInput1Src)
            aluInput1Src_gpr1: aluInput1 = gprResult1;
            aluInput1Src_pc: aluInput1 = pcValue;
        endcase
    end

    always_comb begin : aluInput2Comb
        case(controlSignal.aluInput2Src)
            aluInput2Src_gpr2: aluInput2 = gprResult2;
            aluInput2Src_ext: aluInput2 = extResult;
            aluInput2Src_4: aluInput2 = 4;
        endcase
    end

    assign aluOp = controlSignal.aluOp;
    assign dmWriteEnabled = controlSignal.dmWriteEnabled;
    assign extSign = controlSignal.extSign;

    always_comb begin: pcJumpModeComb
        if(controlSignal.pcJumpModeSrc == pcJumpModeSrc_beq)
            pcJumpMode = {1'b0, aluZero};
        else
            pcJumpMode = controlSignal.pcJumpModeSrc;
    end

    always_comb begin: pcJumpInputComb
        case(controlSignal.pcJumpInputSrc)
            pcJumpInputSrc_0: pcJumpInput = 0;
            pcJumpInputSrc_ext: pcJumpInput = extResult;
            pcJumpInputSrc_imm26: pcJumpInput = instruction.imm26;
            pcJumpInputSrc_gpr: pcJumpInput = gprResult1;
        endcase
    end

    always @(posedge clock) begin
        if(pcValue > 0) begin
            if(dmWriteEnabled) begin
                $display("@%h: *%h <= %h", pcValue, dmAddress, dmWriteInput);
            end
            if(gprWriteEnabled) begin
                $display("@%h: $%d <= %h", pcValue, gprWriteRegister, gprWriteInput);
            end
        end
        if(instruction.instructionCode == syscall) begin
            $finish;
        end
    end
endmodule

`endif