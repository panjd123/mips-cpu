`ifndef GENERAL_PURPOSE_REGISTERS_SV
`define GENERAL_PURPOSE_REGISTERS_SV

`include "common.vh"
module GeneralPurposeRegisters(
    input reset,
    input clock,
    input Vec5 gprReadRegister1,
    input Vec5 gprReadRegister2,
    input Vec5 gprWriteRegister,
    input gprWriteEnabled,
    input Vec32 gprWriteInput,
    output Vec32 gprResult1,
    output Vec32 gprResult2
    );
    Vec32 data[31:0];
    assign gprResult1 = data[gprReadRegister1];
    assign gprResult2 = data[gprReadRegister2];
    always_ff @ (negedge clock) begin
        if(reset) begin
            for(integer i = 0; i < 32; i++) begin
                data[i] <= 32'h00000000;
            end
        end
        else if(gprWriteEnabled) begin
            if(gprWriteRegister != 5'b00000) begin
                data[gprWriteRegister] <= gprWriteInput;
            end
        end
    end
endmodule

`endif