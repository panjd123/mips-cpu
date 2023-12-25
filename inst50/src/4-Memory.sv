`ifndef MEMORY_SV
`define MEMORY_SV

`include "common.vh"
`include "ForwardingUnit.sv"
`include "DataMemory.sv"

module Memory(
    input logic reset,
    input logic clock,
    input IF_ID_REG IF_ID_REG_value,
    input ID_EX_REG ID_EX_REG_value,
    input EX_MEM_REG EX_MEM_REG_value,
    output MEM_WB_REG MEM_WB_REG_value,
    input integer file,
    input integer result_file,
    input integer debug_result_file
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

    assign pcValue = EX_MEM_REG_value.pcValue;
    assign instruction = EX_MEM_REG_value.instruction;
    assign controlSignal = EX_MEM_REG_value.controlSignal;
    assign gprReadRegister1 = EX_MEM_REG_value.gprReadRegister1;
    assign gprReadRegister2 = EX_MEM_REG_value.gprReadRegister2;
    assign gprWriteRegister = EX_MEM_REG_value.gprWriteRegister;
    assign gprResult1 = EX_MEM_REG_value.gprResult1;
    assign gprResult2 = EX_MEM_REG_value.gprResult2;

    Vec32 forwardingGprResult1, forwardingGprResult2;
    logic stallMEM1, stallMEM2;

    ForwardingUnit u_ForwardingUnit1(
    	.requiredReg      (gprReadRegister1      ),
        .gprResult        (gprResult1        ),
        .memoryForwardingEnabled    (1'b0),
        .memoryForwardingResult     (32'hxxxxxxxx),
        .requiredStage    (controlSignal.gprResultRequiredStage1    ),
        .pipelineStage    (pipelineStage_MEMORY    ),
        .IF_ID_REG_value  (IF_ID_REG_value  ),
        .ID_EX_REG_value  (ID_EX_REG_value  ),
        .EX_MEM_REG_value (EX_MEM_REG_value ),
        .MEM_WB_REG_value (MEM_WB_REG_value ),
        .forwardingResult (forwardingGprResult1 ),
        .stall            (stallMEM1            )
    );
    
    ForwardingUnit u_ForwardingUnit2(
    	.requiredReg      (gprReadRegister2      ),
        .gprResult        (gprResult2        ),
        .memoryForwardingEnabled    (1'b0),
        .memoryForwardingResult     (32'hxxxxxxxx),
        .requiredStage    (controlSignal.gprResultRequiredStage2    ),
        .pipelineStage    (pipelineStage_MEMORY    ),
        .IF_ID_REG_value  (IF_ID_REG_value  ),
        .ID_EX_REG_value  (ID_EX_REG_value  ),
        .EX_MEM_REG_value (EX_MEM_REG_value ),
        .MEM_WB_REG_value (MEM_WB_REG_value ),
        .forwardingResult (forwardingGprResult2 ),
        .stall            (stallMEM2            )
    );

    logic dmWriteEnabled;
    Vec32 dmAddress, dmWriteInput;

    assign dmWriteEnabled = (controlSignal.dmWriteType != dmWriteType_0);
    assign dmAddress = EX_MEM_REG_value.aluResult;
    assign dmWriteInput = forwardingGprResult2;
    
    Vec32 dmReadResult;
    Vec32 trueWriteInputOutput;
    Vec32 trueDmAddress;
    assign trueDmAddress = {dmAddress[31:2], 2'b00};

    DataMemory u_DataMemory(
    	.reset                (reset                ),
        .clock                (clock                ),
        .dmAddress            (dmAddress            ),
        .dmReadType           (controlSignal.dmReadType           ),
        .dmWriteType          (controlSignal.dmWriteType          ),
        .dmWriteInput         (dmWriteInput         ),
        .dmReadResult         (dmReadResult         ),
        .trueWriteInputOutput (trueWriteInputOutput )
    );
    

    Vec32 gprWriteInput;

    always_comb begin : getGprWriteInputComb
        case(controlSignal.gprWriteInputSrc)
            gprWriteInputSrc_dmResult:
                gprWriteInput = dmReadResult;
            default:
                gprWriteInput = EX_MEM_REG_value.gprWriteInput;
        endcase
    end

    always_ff @(posedge clock) begin: writeBack
        if (reset) begin
            MEM_WB_REG_value.pcValue <= 32'h00000000;
            `init_instruction_unblocking(MEM_WB_REG_value.instruction);
            `init_control_signal_unblocking(MEM_WB_REG_value.controlSignal);
            MEM_WB_REG_value.gprReadRegister1 <= 5'b00000;
            MEM_WB_REG_value.gprReadRegister2 <= 5'b00000;
            MEM_WB_REG_value.gprWriteRegister <= 5'b00000;
            MEM_WB_REG_value.gprResult1 <= 32'h00000000;
            MEM_WB_REG_value.gprResult2 <= 32'h00000000;
            MEM_WB_REG_value.gprWriteInput <= 32'h00000000;
            MEM_WB_REG_value.dmReadResult <= 32'h00000000;
            MEM_WB_REG_value.exception <= 1'b0;
        end else begin
            MEM_WB_REG_value.pcValue <= pcValue;
            MEM_WB_REG_value.instruction <= instruction;
            MEM_WB_REG_value.controlSignal <= EX_MEM_REG_value.controlSignal;
            MEM_WB_REG_value.gprReadRegister1 <= EX_MEM_REG_value.gprReadRegister1;
            MEM_WB_REG_value.gprReadRegister2 <= EX_MEM_REG_value.gprReadRegister2;
            MEM_WB_REG_value.gprWriteRegister <= EX_MEM_REG_value.gprWriteRegister;
            MEM_WB_REG_value.gprResult1 <= forwardingGprResult1;
            MEM_WB_REG_value.gprResult2 <= forwardingGprResult2;
            MEM_WB_REG_value.gprWriteInput <= gprWriteInput;
            MEM_WB_REG_value.dmReadResult <= dmReadResult;
            MEM_WB_REG_value.exception <= EX_MEM_REG_value.exception;
            cnt = cnt + 1;
            $fdisplay(file, "MEM(%d): @%h: %h", cnt, pcValue, instruction.instructionCode);
            if(dmWriteEnabled && EX_MEM_REG_value.pcValue!=32'h00000000) begin // Avoid bubble (sll $0 $0 0) output 
                $display("@%h: *%h <= %h", EX_MEM_REG_value.pcValue, trueDmAddress, trueWriteInputOutput);
                
                $fdisplay(result_file, "@%h: *%h <= %h", EX_MEM_REG_value.pcValue, trueDmAddress, trueWriteInputOutput);
                $fdisplay(debug_result_file, "(%d)@%h: *%h <= %h", cnt, EX_MEM_REG_value.pcValue, trueDmAddress, trueWriteInputOutput);
            end
            $fdisplay(file, "");
            $fdisplay(file, "forwardingGprResult1: %h", forwardingGprResult1);
            $fdisplay(file, "forwardingGprResult2: %h", forwardingGprResult2);
            $fdisplay(file, "");
            $fdisplay(file, "gprWriteRegister: %b", gprWriteRegister);
            $fdisplay(file, "gprWriteInput: %h", gprWriteInput);
            $fdisplay(file, "dmAddress: %h", dmAddress);
            $fdisplay(file, "trueDmAddress: %h", trueDmAddress);
            $fdisplay(file, "dmReadResult: %h", dmReadResult);
            $fdisplay(file, "dmWriteEnabled: %b", dmWriteEnabled);
            $fdisplay(file, "dmWriteInput: %h", dmWriteInput);
            $fdisplay(file, "trueWriteInputOutput: %h", trueWriteInputOutput);
            $fdisplay(file, "");
        end
    end
    

endmodule
`endif