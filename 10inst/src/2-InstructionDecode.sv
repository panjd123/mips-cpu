`ifndef INSTRUCTION_DECODE_SV
`define INSTRUCTION_DECODE_SV

`include "common.vh"
`include "ControllerUnit.sv"
`include "ForwardingUnit.sv"

module InstructionDecode(
    input logic reset,
    input logic clock,
    input Vec32 gprResult1,
    input Vec32 gprResult2,
    input IF_ID_REG IF_ID_REG_value,
    output ID_EX_REG ID_EX_REG_value,
    input EX_MEM_REG EX_MEM_REG_value,
    input MEM_WB_REG MEM_WB_REG_value,
    output Vec5 gprReadRegister1,
    output Vec5 gprReadRegister2,
    output logic jumpEnabled,
    output Vec32 pcJumpInput,
    output logic stallID,
    input logic stallEX,
    input integer file
    );
    integer cnt;
    initial begin
        cnt = 0;
    end
    Vec32 pcValue;
    Instruction instruction;
    assign instruction = IF_ID_REG_value.instruction;
    assign pcValue = IF_ID_REG_value.pcValue;

    ControlSignal controlSignal;
    ControllerUnit u_ControllerUnit(
    	.instruction   (instruction   ),
        .controlSignal (controlSignal )
    );

    Vec5 gprWriteRegister;

    always_comb begin: getGprID
        `getGprID(gprReadRegister1, controlSignal.gprReadIDSrc1, IF_ID_REG_value.instruction);
        `getGprID(gprReadRegister2, controlSignal.gprReadIDSrc2, IF_ID_REG_value.instruction);
        `getGprID(gprWriteRegister, controlSignal.gprWriteIDSrc, IF_ID_REG_value.instruction);
    end

    Vec32 forwardingGprResult1, forwardingGprResult2;
    logic stallID1, stallID2;
    Vec3 forwardingSignal1, forwardingSignal2;

    ForwardingUnit u_ForwardingUnit1(
    	.requiredReg                (gprReadRegister1      ),
        .gprResult                  (gprResult1        ),
        .memoryForwardingEnabled    (1'b0),
        .memoryForwardingResult     (32'hxxxxxxxx),
        .requiredStage              (controlSignal.gprResultRequiredStage1    ),
        .pipelineStage              (pipelineStage_DECODE    ),
        .IF_ID_REG_value            (IF_ID_REG_value  ),
        .ID_EX_REG_value            (ID_EX_REG_value  ),
        .EX_MEM_REG_value           (EX_MEM_REG_value ),
        .MEM_WB_REG_value           (MEM_WB_REG_value ),
        .forwardingResult           (forwardingGprResult1 ),
        .stall                      (stallID1            ),
        .forwardingSignal           (forwardingSignal1)
    );
    
    ForwardingUnit u_ForwardingUnit2(
    	.requiredReg                (gprReadRegister2      ),
        .gprResult                  (gprResult2        ),
        .memoryForwardingEnabled    (1'b0),
        .memoryForwardingResult     (32'hxxxxxxxx),
        .requiredStage              (controlSignal.gprResultRequiredStage2    ),
        .pipelineStage              (pipelineStage_DECODE    ),
        .IF_ID_REG_value            (IF_ID_REG_value  ),
        .ID_EX_REG_value            (ID_EX_REG_value  ),
        .EX_MEM_REG_value           (EX_MEM_REG_value ),
        .MEM_WB_REG_value           (MEM_WB_REG_value ),
        .forwardingResult           (forwardingGprResult2 ),
        .stall                      (stallID2            ),
        .forwardingSignal           (forwardingSignal2)
    );

    assign stallID = stallID1 || stallID2;
    assign stall = stallID || stallEX;

    logic jumpConditionEnabled;
    always_comb begin: getJumpEnabled
        case(controlSignal.pcJumpCondition)
            pcJumpCondition_true:
                jumpConditionEnabled = 1;
            pcJumpCondition_false:
                jumpConditionEnabled = 0;
            pcJumpCondition_eq:
                jumpConditionEnabled = (forwardingGprResult1 == forwardingGprResult2);
            pcJumpCondition_ne:
                jumpConditionEnabled = (forwardingGprResult1 != forwardingGprResult2);
            pcJumpCondition_lt:
                jumpConditionEnabled = ($signed(forwardingGprResult1) < $signed(0));
            pcJumpCondition_gt:
                jumpConditionEnabled = ($signed(forwardingGprResult1) > $signed(0));
            pcJumpCondition_le:
                jumpConditionEnabled = ($signed(forwardingGprResult1) <= $signed(0));
            pcJumpCondition_ge:
                jumpConditionEnabled = ($signed(forwardingGprResult1) >= $signed(0));
        endcase
    end

    assign jumpEnabled = jumpConditionEnabled;

    always_comb begin : getGprWriteEnabled
        case(controlSignal.pcJumpInputSrc)
            pcJumpInputSrc_gpr_read1:
                pcJumpInput = forwardingGprResult1;
            pcJumpInputSrc_signed_imm16_lshift_2:
                pcJumpInput = pcValue + 4 + {{14{instruction.imm16[15]}}, instruction.imm16[15:0], 2'b00};
            pcJumpInputSrc_unsigned_imm26_lshift_2:
                pcJumpInput = {pcValue[31:28], instruction.imm26[25:0], 2'b00};
        endcase
    end

    Vec32 gprWriteInput;
    always_comb begin : getGprWriteInput
        case(controlSignal.gprWriteInputSrc)
            gprWriteInputSrc_pc_add_8:
                gprWriteInput = pcValue + 8;
            gprWriteInputSrc_imm16_lshift_16:
                gprWriteInput = {instruction.imm16[15:0], 16'b0};
            default:
                gprWriteInput = 32'hxxxxxxxx;
        endcase
    end

    always_ff @(posedge clock) begin
        if(reset || stallID && !stallEX) begin  // ID is the last stall signal, pass bubble
            ID_EX_REG_value.pcValue <=  32'h00000000;
            `init_instruction_unblocking(ID_EX_REG_value.instruction);
            `init_control_signal_unblocking(ID_EX_REG_value.controlSignal);
            ID_EX_REG_value.gprReadRegister1 <= 5'b00000;
            ID_EX_REG_value.gprReadRegister2 <= 5'b00000;
            ID_EX_REG_value.gprWriteRegister <= 5'b00000;
            ID_EX_REG_value.gprResult1 <= 32'h00000000;
            ID_EX_REG_value.gprResult2 <= 32'h00000000;
            ID_EX_REG_value.gprWriteInput <= 32'h00000000;
        end
        else if(stallEX) begin      // EX is the last stall signal
            // do nothing
        end
        else begin                  // !stallID && !stallEX
            ID_EX_REG_value.pcValue <= pcValue;
            ID_EX_REG_value.instruction <= instruction;
            ID_EX_REG_value.controlSignal <= controlSignal;
            ID_EX_REG_value.gprReadRegister1 <= gprReadRegister1;
            ID_EX_REG_value.gprReadRegister2 <= gprReadRegister2;
            ID_EX_REG_value.gprWriteRegister <= gprWriteRegister;
            ID_EX_REG_value.gprResult1 <= forwardingGprResult1;
            ID_EX_REG_value.gprResult2 <= forwardingGprResult2;
            ID_EX_REG_value.gprWriteInput <= gprWriteInput;
        end
        if(!reset) begin
            cnt = cnt + 1;
            $fdisplay(file, "ID(%d): @%h: %b", cnt, pcValue, instruction.instructionCode);
            $fdisplay(file, "gprReadRegister1: %d", gprReadRegister1);
            $fdisplay(file, "gprReadRegister2: %d", gprReadRegister2);
            $fdisplay(file, "gprResult1: %h", gprResult1);
            $fdisplay(file, "gprResult2: %h", gprResult2);

            $fdisplay(file, "jumpEnabled: %b", jumpEnabled);
            $fdisplay(file, "pcJumpInput: %h", pcJumpInput);

            $fdisplay(file, "gprReadIDSrc1: %b", controlSignal.gprReadIDSrc1);
            $fdisplay(file, "gprReadIDSrc2: %b", controlSignal.gprReadIDSrc2);
            $fdisplay(file, "gprWriteIDSrc: %b", controlSignal.gprWriteIDSrc);
            $fdisplay(file, "gprWriteEnabled: %b", controlSignal.gprWriteEnabled);
            $fdisplay(file, "gprWriteInputSrc: %b", controlSignal.gprWriteInputSrc);
            $fdisplay(file, "pcJumpMode: %b", controlSignal.pcJumpMode);
            $fdisplay(file, "pcJumpInputSrc: %b", controlSignal.pcJumpInputSrc);
            $fdisplay(file, "pcJumpCondition: %b", controlSignal.pcJumpCondition);
            $fdisplay(file, "aluOp: %b", controlSignal.aluOp);
            $fdisplay(file, "aluMduInputSrc1: %b", controlSignal.aluMduInputSrc1);
            $fdisplay(file, "aluMduInputSrc2: %b", controlSignal.aluMduInputSrc2);
            $fdisplay(file, "dmReadType: %b", controlSignal.dmReadType);
            $fdisplay(file, "dmWriteType: %b", controlSignal.dmWriteType);
            $fdisplay(file, "");
            $fdisplay(file, "gprWriteRegister: %b", gprWriteRegister);
            $fdisplay(file, "gprWriteInput: %h", gprWriteInput);
            $fdisplay(file, "");

            $fdisplay(file, "----Forwarding----");
            $fdisplay(file, "requiredStage1: %d", controlSignal.gprResultRequiredStage1);
            $fdisplay(file, "requiredStage2: %d", controlSignal.gprResultRequiredStage2);
            $fdisplay(file, "forwardingSignal1: %b", forwardingSignal1);
            $fdisplay(file, "forwardingSignal2: %b", forwardingSignal2);
            $fdisplay(file, "forwardingGprResult1: %h", forwardingGprResult1);
            $fdisplay(file, "forwardingGprResult2: %h", forwardingGprResult2);
            $fdisplay(file, "stallID1: %b\tstallID2: %b", stallID1, stallID2);
            $fdisplay(file, "");
        end
    end
endmodule
`endif