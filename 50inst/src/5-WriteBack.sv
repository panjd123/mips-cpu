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
    assign exception = MEM_WB_REG_value.exception;

    Vec32 v0, a0;
    assign v0 = MEM_WB_REG_value.gprResult1;
    assign a0 = MEM_WB_REG_value.gprResult2;

    assign gprWriteEnabled = controlSignal.gprWriteEnabled;
    assign gprWriteInput = MEM_WB_REG_value.gprWriteInput;
    assign gprWriteRegister = MEM_WB_REG_value.gprWriteRegister;

    always_ff @(posedge clock) begin
        if(!reset) begin
            cnt = cnt + 1;
            $fdisplay(file, "WB(%d): @%h: %h", cnt, pcValue, instruction.instructionCode);
            if(gprWriteEnabled && MEM_WB_REG_value.pcValue!=32'h00000000) begin // Avoid bubble (sll $0 $0 0) output
                $display("@%h: $%d <= %h", MEM_WB_REG_value.pcValue, gprWriteRegister, gprWriteInput);

                $fdisplay(result_file, "@%h: $%d <= %h", MEM_WB_REG_value.pcValue, gprWriteRegister, gprWriteInput);
                $fdisplay(debug_result_file, "(%d)@%h: $%d <= %h", cnt, MEM_WB_REG_value.pcValue, gprWriteRegister, gprWriteInput);
            end
            $fdisplay(file, "");
            $fdisplay(file, "gprWriteEnabled: %b", gprWriteEnabled);
            $fdisplay(file, "gprWriteRegister: %b", gprWriteRegister);
            $fdisplay(file, "gprWriteInput: %h", gprWriteInput);
            $fdisplay(file, "");
            casex (instruction.instructionCode)
                SYSCALL: begin
                    $fdisplay(file, "syscall: %h %h", v0, a0);
                    case(v0)
                        1: begin // print_int
                            $display("%d", a0);
                            $fdisplay(result_file, "%d", a0);
                            $fdisplay(debug_result_file, "(%d)%d", cnt, a0);
                            // $finish;
                        end
                        10: begin // exit
                            // $fclose(file);
                            // $fclose(result_file);
                            // $fclose(debug_result_file);
                            $finish;
                        end
                        default: begin
                            // $fclose(file);
                            // $fclose(result_file);
                            // $fclose(debug_result_file);
                            $finish;
                        end
                    endcase
                end
            endcase
            
            if(exception) begin
                $display("Runtime exception at %h: arithmetic overflow", pcValue);
                $finish;
            end
        end
    end

endmodule

`endif