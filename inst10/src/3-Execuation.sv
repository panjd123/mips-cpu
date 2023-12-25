`ifndef EXECUATION_SV
`define EXECUATION_SV

`include "common.vh"
`include "ForwardingUnit.sv"
`include "ArithmeticLogicUnit.sv"

module selectAluInput(
    input AluMduInputSrc aluMduInputSrc,
    input Vec32 forwardingGprResult1,
    input Vec32 forwardingGprResult2,
    input ID_EX_REG ID_EX_REG_value,
    output Vec32 aluInput
);
    always_comb begin : getAluInput
        case(aluMduInputSrc)
            aluMduInputSrc_gpr1:
                aluInput = forwardingGprResult1;
            aluMduInputSrc_gpr2:
                aluInput = forwardingGprResult2;
            aluMduInputSrc_unsigned_imm16:
                aluInput = {{16{1'b0}}, ID_EX_REG_value.instruction.imm16[15:0]};
            aluMduInputSrc_signed_imm16:
                aluInput = {{16{ID_EX_REG_value.instruction.imm16[15]}}, ID_EX_REG_value.instruction.imm16[15:0]};
            aluMduInputSrc_unsigned_shamt:
                aluInput = {{27{1'b0}}, ID_EX_REG_value.instruction.shamt[4:0]};
        endcase
    end
endmodule

module Execuation(
    input logic reset,
    input logic clock,
    input IF_ID_REG IF_ID_REG_value,
    input ID_EX_REG ID_EX_REG_value,
    output EX_MEM_REG EX_MEM_REG_value,
    input MEM_WB_REG MEM_WB_REG_value,
    input logic stallID, // unused
    output logic stallEX,
    input integer file
    );
    integer cnt;
    initial begin
        cnt = 0;
    end

    Vec32 pcValue;
    Instruction instruction;
    ControlSignal controlSignal;
    Vec5 gprReadRegister1, gprReadRegister2, gprWriteRegister;
    Vec32 gprResult1, gprResult2;

    assign pcValue = ID_EX_REG_value.pcValue;
    assign instruction = ID_EX_REG_value.instruction;
    assign controlSignal = ID_EX_REG_value.controlSignal;
    assign gprReadRegister1 = ID_EX_REG_value.gprReadRegister1;
    assign gprReadRegister2 = ID_EX_REG_value.gprReadRegister2;
    assign gprWriteRegister = ID_EX_REG_value.gprWriteRegister;
    assign gprResult1 = ID_EX_REG_value.gprResult1;
    assign gprResult2 = ID_EX_REG_value.gprResult2;
    
    Vec32 forwardingGprResult1, forwardingGprResult2;
    logic stallEX1, stallEX2;

    Vec3 forwardingSignal1, forwardingSignal2;

    ForwardingUnit u_ForwardingUnit1(
    	.requiredReg      (gprReadRegister1      ),
        .gprResult        (gprResult1        ),
        .memoryForwardingEnabled    (EX_MEM_REG_value.memoryForwardingEnabled1    ),
        .memoryForwardingResult     (EX_MEM_REG_value.memoryForwardingResult1     ),
        .requiredStage    (controlSignal.gprResultRequiredStage1    ),
        .pipelineStage    (pipelineStage_EXECUTE    ),
        .IF_ID_REG_value  (IF_ID_REG_value  ),
        .ID_EX_REG_value  (ID_EX_REG_value  ),
        .EX_MEM_REG_value (EX_MEM_REG_value ),
        .MEM_WB_REG_value (MEM_WB_REG_value ),
        .forwardingResult (forwardingGprResult1 ),
        .stall            (stallEX1            ),
        .forwardingSignal (forwardingSignal1)
    );
    
    ForwardingUnit u_ForwardingUnit2(
    	.requiredReg      (gprReadRegister2      ),
        .gprResult        (gprResult2        ),
        .memoryForwardingEnabled    (EX_MEM_REG_value.memoryForwardingEnabled2    ),
        .memoryForwardingResult     (EX_MEM_REG_value.memoryForwardingResult2     ),
        .requiredStage    (controlSignal.gprResultRequiredStage2    ),
        .pipelineStage    (pipelineStage_EXECUTE    ),
        .IF_ID_REG_value  (IF_ID_REG_value  ),
        .ID_EX_REG_value  (ID_EX_REG_value  ),
        .EX_MEM_REG_value (EX_MEM_REG_value ),
        .MEM_WB_REG_value (MEM_WB_REG_value ),
        .forwardingResult (forwardingGprResult2 ),
        .stall            (stallEX2            ),
        .forwardingSignal (forwardingSignal2)
    );

    assign stallEX = stallEX1 | stallEX2;
    
    Vec32 aluInput1, aluInput2;

    selectAluInput u_selectAluInput1(
        .aluMduInputSrc       (controlSignal.aluMduInputSrc1       ),
    	.forwardingGprResult1 (forwardingGprResult1 ),
        .forwardingGprResult2 (forwardingGprResult2 ),
        .ID_EX_REG_value      (ID_EX_REG_value      ),
        .aluInput             (aluInput1            )
    );

    selectAluInput u_selectAluInput2(
        .aluMduInputSrc       (controlSignal.aluMduInputSrc2       ),
    	.forwardingGprResult1 (forwardingGprResult1 ),
        .forwardingGprResult2 (forwardingGprResult2 ),
        .ID_EX_REG_value      (ID_EX_REG_value      ),
        .aluInput             (aluInput2            )
    );

    Vec32 aluResult;
    Vec32 mduResult;

    ArithmeticLogicUnit u_ArithmeticLogicUnit(
    	.aluInput1 (aluInput1 ),
        .aluInput2 (aluInput2 ),
        .aluOp     (controlSignal.aluOp     ),
        .aluResult (aluResult )
    );

    // MDU related

    Vec32 gprWriteInput;
    always_comb begin : getGprWriteInput
        case(controlSignal.gprWriteInputSrc)
            gprWriteInputSrc_aluResult:
                gprWriteInput = aluResult;
            gprWriteInputSrc_mduResult:
                gprWriteInput = mduResult;
            default:
                gprWriteInput = ID_EX_REG_value.gprWriteInput;
        endcase
    end

    always_ff @(posedge clock) begin
        if(reset || stallEX) begin
            EX_MEM_REG_value.pcValue <= 32'h00000000;
            `init_instruction_unblocking(EX_MEM_REG_value.instruction);
            `init_control_signal_unblocking(EX_MEM_REG_value.controlSignal);
            EX_MEM_REG_value.gprReadRegister1 <= 5'b00000;
            EX_MEM_REG_value.gprReadRegister2 <= 5'b00000;
            EX_MEM_REG_value.gprWriteRegister <= 5'b00000;
            EX_MEM_REG_value.gprResult1 <= 32'h00000000;
            EX_MEM_REG_value.gprResult2 <= 32'h00000000;
            EX_MEM_REG_value.gprWriteInput <= 32'h00000000;
            EX_MEM_REG_value.aluResult <= 32'h00000000;
            if(!reset) begin
                EX_MEM_REG_value.memoryForwardingEnabled1 <= !stallEX1;
                EX_MEM_REG_value.memoryForwardingEnabled2 <= !stallEX2;
                EX_MEM_REG_value.memoryForwardingResult1 <= forwardingGprResult1;
                EX_MEM_REG_value.memoryForwardingResult2 <= forwardingGprResult2;
            end
            else begin
                EX_MEM_REG_value.memoryForwardingEnabled1 <= 1'b0;
                EX_MEM_REG_value.memoryForwardingEnabled2 <= 1'b0;
                EX_MEM_REG_value.memoryForwardingResult1 <= 32'hxxxxxxxx;
                EX_MEM_REG_value.memoryForwardingResult2 <= 32'hxxxxxxxx;
            end
        end
        else
        begin
            EX_MEM_REG_value.pcValue <= pcValue;
            EX_MEM_REG_value.instruction <= instruction;
            EX_MEM_REG_value.controlSignal <= ID_EX_REG_value.controlSignal;
            EX_MEM_REG_value.gprReadRegister1 <= ID_EX_REG_value.gprReadRegister1;
            EX_MEM_REG_value.gprReadRegister2 <= ID_EX_REG_value.gprReadRegister2;
            EX_MEM_REG_value.gprWriteRegister <= ID_EX_REG_value.gprWriteRegister;
            EX_MEM_REG_value.gprResult1 <= forwardingGprResult1;
            EX_MEM_REG_value.gprResult2 <= forwardingGprResult2;
            EX_MEM_REG_value.gprWriteInput <= gprWriteInput;
            EX_MEM_REG_value.aluResult <= aluResult;
            EX_MEM_REG_value.memoryForwardingEnabled1 <= 1'b0;
            EX_MEM_REG_value.memoryForwardingEnabled2 <= 1'b0;
            EX_MEM_REG_value.memoryForwardingResult1 <= 32'hxxxxxxxx;
            EX_MEM_REG_value.memoryForwardingResult2 <= 32'hxxxxxxxx;
        end
        if(!reset) begin
            cnt = cnt + 1;
            $fdisplay(file, "EX(%d): @%h: %b", cnt, pcValue, instruction.instructionCode);
            $fdisplay(file, "stallEX: %b\tstallEX1: %b\tstallEX2: %b", stallEX, stallEX1, stallEX2);
            $fdisplay(file, "gprReadRegister1: %d", gprReadRegister1);
            $fdisplay(file, "gprReadRegister2: %d", gprReadRegister2);
            $fdisplay(file, "gprResult1: %h", gprResult1);
            $fdisplay(file, "gprResult2: %h", gprResult2);

            $fdisplay(file, "----Forwarding----");
            $fdisplay(file, "requiredStage1: %d", controlSignal.gprResultRequiredStage1);
            $fdisplay(file, "requiredStage2: %d", controlSignal.gprResultRequiredStage2);
            $fdisplay(file, "forwardingSignal1: %b", forwardingSignal1);
            $fdisplay(file, "forwardingSignal2: %b", forwardingSignal2);
            $fdisplay(file, "forwardingGprResult1: %h", forwardingGprResult1);
            $fdisplay(file, "forwardingGprResult2: %h", forwardingGprResult2);


            $fdisplay(file, "");
            $fdisplay(file, "aluInput1: %h", aluInput1);
            $fdisplay(file, "aluInput2: %h", aluInput2);
            $fdisplay(file, "aluResult: %h", aluResult);
            $fdisplay(file, "");

            $fdisplay(file, "gprWriteRegister: %b", gprWriteRegister);
            $fdisplay(file, "gprWriteInput: %h", gprWriteInput);
            $fdisplay(file, "");
        end
    end
    
endmodule

`endif