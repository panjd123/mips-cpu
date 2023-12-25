`ifndef WRITE_BACK_SV
`define WRITE_BACK_SV

`include "common.vh"

module WriteBack(
    input logic reset,
    input logic clock,
    input IF_ID_REG IF_ID_REG_value,
    input ID_EX_REG ID_EX_REG_value,
    input EX_MEM_REG EX_MEM_REG_value,
    input MEM_WB_REG MEM_WB_REG_value,
    output logic gprWriteEnabled,
    output Vec5 gprWriteRegister,
    output Vec32 gprWriteInput,
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

    assign pcValue = MEM_WB_REG_value.pcValue;
    assign instruction = MEM_WB_REG_value.instruction;
    assign controlSignal = MEM_WB_REG_value.controlSignal;

    assign gprWriteEnabled = controlSignal.gprWriteEnabled;
    assign gprWriteInput = MEM_WB_REG_value.gprWriteInput;
    assign gprWriteRegister = MEM_WB_REG_value.gprWriteRegister;

    always_ff @(posedge clock) begin
        if(!reset) begin
            cnt = cnt + 1;
            $fdisplay(file, "WB(%d): @%h: %b", cnt, pcValue, instruction.instructionCode);
            if(gprWriteEnabled) begin
                $display("@%h: $%d <= %h", MEM_WB_REG_value.pcValue, gprWriteRegister, gprWriteInput);

                $fdisplay(result_file, "@%h: $%d <= %h", MEM_WB_REG_value.pcValue, gprWriteRegister, gprWriteInput);
                $fdisplay(debug_result_file, "(%d)@%h: $%d <= %h", cnt, MEM_WB_REG_value.pcValue, gprWriteRegister, gprWriteInput);
            end
            $fdisplay(file, "");
            $fdisplay(file, "gprWriteRegister: %b", gprWriteRegister);
            $fdisplay(file, "gprWriteInput: %h", gprWriteInput);
            $fdisplay(file, "");
            if(instruction.instructionCode == SYSCALL) begin
                $fclose(file);
                $fclose(result_file);
                $fclose(debug_result_file);
                $finish;
            end
        end
    end

endmodule

`endif