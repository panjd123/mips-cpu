`ifndef FORWARDING_UNIT_SV
`define FORWARDING_UNIT_SV
`include "common.vh"
`include "2-InstructionDecode.sv"
`include "3-Execuation.sv"
`include "4-Memory.sv"
`include "5-WriteBack.sv"
/*
| IF | ID | EX | MEM | WB  |     |     |
|    | IF | ID | EX  | MEM | WB  |     |
|    |    | IF | ID  | EX  | MEM | WB  |
|    |    |    | IF  | ID  | EX  | MEM | WB |
*/

typedef enum Vec3 { 
    forwardingSignal_none,
    forwardingSignal_ID_EX,
    forwardingSignal_EX_MEM,
    forwardingSignal_MEM_WB,
    forwardingSignal_MEMORY    
} ForwardingSignal;

module ForwardingUnit(
    input Vec5 requiredReg,
    input Vec32 gprResult,
    input logic memoryForwardingEnabled,
    input Vec32 memoryForwardingResult,
    input PipelineStage requiredStage,
    input PipelineStage pipelineStage,
    input IF_ID_REG IF_ID_REG_value,
    input ID_EX_REG ID_EX_REG_value,
    input EX_MEM_REG EX_MEM_REG_value,
    input MEM_WB_REG MEM_WB_REG_value,
    output Vec32 forwardingResult,
    output logic stall,
    output ForwardingSignal forwardingSignal // debug only
    );
    PipelineStage readyStage;
    always_comb begin : blockName
        if (!memoryForwardingEnabled) begin
            if (pipelineStage < pipelineStage_ID_EX && 
                ID_EX_REG_value.controlSignal.gprWriteEnabled && 
                ID_EX_REG_value.gprWriteRegister == requiredReg &&
                requiredReg != 0) begin
                    forwardingSignal = forwardingSignal_ID_EX; // 3'b001
                    forwardingResult = ID_EX_REG_value.gprWriteInput;
                    readyStage = readyPipelineStage(ID_EX_REG_value.controlSignal.gprWriteInputSrc);
                    stall = (readyStage > pipelineStage_ID_EX) && (pipelineStage == requiredStage); // 还没准备好，但是需要用到
                end
            else if(pipelineStage < pipelineStage_EX_MEM &&
                EX_MEM_REG_value.controlSignal.gprWriteEnabled && 
                EX_MEM_REG_value.gprWriteRegister == requiredReg &&
                requiredReg != 0) begin
                    forwardingSignal = forwardingSignal_EX_MEM; // 3'b010
                    forwardingResult = EX_MEM_REG_value.gprWriteInput;
                    readyStage = readyPipelineStage(EX_MEM_REG_value.controlSignal.gprWriteInputSrc);
                    stall = (readyStage > pipelineStage_EX_MEM) && (pipelineStage == requiredStage);
                end
            else if(pipelineStage < pipelineStage_MEM_WB &&
                MEM_WB_REG_value.controlSignal.gprWriteEnabled && 
                MEM_WB_REG_value.gprWriteRegister == requiredReg &&
                requiredReg != 0) begin
                    forwardingSignal = forwardingSignal_MEM_WB; // 3'b011
                    forwardingResult = MEM_WB_REG_value.gprWriteInput;
                    readyStage = readyPipelineStage(MEM_WB_REG_value.controlSignal.gprWriteInputSrc);
                    stall = (readyStage > pipelineStage_MEM_WB) && (pipelineStage == requiredStage);
                end
            else begin
                forwardingSignal = forwardingSignal_none;       // 3'b000
                forwardingResult = gprResult;
                stall = 0;
            end
        end
        else begin
            forwardingSignal = forwardingSignal_MEMORY;         // 3'b100
            forwardingResult = memoryForwardingResult;
            stall = 0;
        end
    end
endmodule
`endif