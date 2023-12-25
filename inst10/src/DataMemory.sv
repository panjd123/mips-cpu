`ifndef DATA_MEMORY_SV
`define DATA_MEMORY_SV

`include "common.vh"
module DataMemory(
    input reset,
    input clock,
    input Vec32 dmAddress,
    input dmWriteEnabled,
    input Vec32 dmWriteInput,
    output Vec32 dmReadResult
    );
    integer i;
    reg [31:0] data[2047:0];
    assign dmReadResult = data[dmAddress[11:2]];
    initial begin
        $readmemh(`data_path, data, 0, 2047);
    end
    always @(posedge clock) begin
        if(reset) begin
            // for(i=0; i<1024; i=i+1) begin
            //     data[i] <= 32'h00000000;
            // end
        end
        else if(dmWriteEnabled) begin
            data[dmAddress[11:2]] <= dmWriteInput;
        end
    end
endmodule

`endif