`ifndef DATA_MEMORY_SV
`define DATA_MEMORY_SV

`include "common.vh"
module DataMemory(
    input logic reset,
    input logic clock,
    input Vec32 dmAddress,
    input Vec3 dmReadType,
    input Vec2 dmWriteType,
    input Vec32 dmWriteInput,
    output Vec32 dmReadResult,
    output Vec32 trueWriteInputOutput // for debug
    );
    integer i;
    Vec32 data[2047:0];
    Vec32 trueWriteInput;
    Vec32 dataOld;
    assign trueWriteInputOutput = trueWriteInput; // for debug
    // assign dmReadResult = data[dmAddress[11:2]];
    assign dataOld = data[dmAddress[11:2]];
    initial begin
        $readmemh(`data_path, data, 0, 2047);
    end

    always_comb begin : writeInputComb
        case(dmWriteType)
            dmWriteType_0: 
                ; // do nothing
            dmWriteType_1:
                case (dmAddress[1:0])
                    2'b00: trueWriteInput = {dataOld[31:8], dmWriteInput[7:0]};
                    2'b01: trueWriteInput = {dataOld[31:16], dmWriteInput[7:0], dataOld[7:0]};
                    2'b10: trueWriteInput = {dataOld[31:24], dmWriteInput[7:0], dataOld[15:0]};
                    2'b11: trueWriteInput = {dmWriteInput[7:0], dataOld[23:0]};
                endcase
            dmWriteType_2:
                case (dmAddress[1])
                    1'b0: trueWriteInput = {dataOld[31:16], dmWriteInput[15:0]};
                    1'b1: trueWriteInput = {dmWriteInput[15:0], dataOld[15:0]};    
                endcase
            dmWriteType_4:
                trueWriteInput = dmWriteInput;
        endcase
    end

    always_comb begin: readComb
        case(dmReadType)
            dmReadType_unsigned_1:
                case (dmAddress[1:0])
                    2'b00: dmReadResult = {24'h000000, dataOld[7:0]};
                    2'b01: dmReadResult = {24'h000000, dataOld[15:8]};
                    2'b10: dmReadResult = {24'h000000, dataOld[23:16]};
                    2'b11: dmReadResult = {24'h000000, dataOld[31:24]};
                endcase
            dmReadType_unsigned_2:
                case (dmAddress[1])
                    1'b0: dmReadResult = {16'h0000, dataOld[15:0]};
                    1'b1: dmReadResult = {16'h0000, dataOld[31:16]};
                endcase
            dmReadType_unsigned_4:
                dmReadResult = dataOld;
            dmReadType_signed_1:
                case (dmAddress[1:0])
                    2'b00: dmReadResult = {{24{dataOld[7]}}, dataOld[7:0]};
                    2'b01: dmReadResult = {{24{dataOld[15]}}, dataOld[15:8]};
                    2'b10: dmReadResult = {{24{dataOld[23]}}, dataOld[23:16]};
                    2'b11: dmReadResult = {{24{dataOld[31]}}, dataOld[31:24]};
                endcase
            dmReadType_signed_2:
                case (dmAddress[1])
                    1'b0: dmReadResult = {{16{dataOld[15]}}, dataOld[15:0]};
                    1'b1: dmReadResult = {{16{dataOld[31]}}, dataOld[31:16]};
                endcase
        endcase
    end

    always @(posedge clock) begin
        if(reset) begin
            // for(i=0; i<1024; i=i+1) begin
            //     data[i] <= 32'h00000000;
            // end
        end
        else if(dmWriteType != dmWriteType_0) begin
            data[dmAddress[11:2]] <= trueWriteInput;
        end
    end
endmodule

`endif