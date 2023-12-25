`ifndef CPU_SV
`define CPU_SV

`include "common.vh"
`include "ArithmeticLogicUnit.sv"
`include "ProgramCounter.sv"
`include "InstructionMemory.sv"
`include "GeneralPurposeRegisters.sv"
`include "DataMemory.sv"
`include "1-InstructionFetch.sv"
`include "2-InstructionDecode.sv"
`include "3-Execuation.sv"
`include "4-Memory.sv"
`include "5-WriteBack.sv"

module TopLevel(
    input logic reset,
    input logic clock
    );

    logic stallID, stallEX;
    logic jumpEnabled;
    Vec32 pcJumpInput;
    IF_ID_REG IF_ID_REG_value;
    ID_EX_REG ID_EX_REG_value;
    EX_MEM_REG EX_MEM_REG_value;
    MEM_WB_REG MEM_WB_REG_value;
    integer file;
    integer result_file, debug_result_file;
    integer total_stall;
    initial begin
        file = $fopen("./output/log.txt", "w");
        result_file = $fopen("./output/result.txt", "w");
        debug_result_file = $fopen("./output/debug_result.txt", "w");
    end


    Vec5 gprReadRegister1, gprReadRegister2, gprWriteRegister;
    logic gprWriteEnabled;
    Vec32 gprWriteInput;
    Vec32 gprResult1, gprResult2;

    InstructionFetch u_InstructionFetch(
    	.reset           (reset           ),
        .clock           (clock           ),
        .jumpEnabled     (jumpEnabled     ),
        .pcJumpInput     (pcJumpInput     ),
        .stallID         (stallID         ),
        .stallEX         (stallEX         ),
        .IF_ID_REG_value (IF_ID_REG_value ),
        .file            (file            )
    );
    

    InstructionDecode u_InstructionDecode(
    	.reset            (reset            ),
        .clock            (clock            ),
        .gprResult1       (gprResult1       ),
        .gprResult2       (gprResult2       ),
        .IF_ID_REG_value  (IF_ID_REG_value  ),
        .ID_EX_REG_value  (ID_EX_REG_value  ),
        .EX_MEM_REG_value (EX_MEM_REG_value ),
        .MEM_WB_REG_value (MEM_WB_REG_value ),
        .gprReadRegister1 (gprReadRegister1 ),
        .gprReadRegister2 (gprReadRegister2 ),
        .jumpEnabled      (jumpEnabled      ),
        .pcJumpInput      (pcJumpInput      ),
        .stallID          (stallID          ),
        .stallEX          (stallEX          ),
        .file             (file             )
    );

    Execuation u_Execuation(
    	.reset            (reset            ),
        .clock            (clock            ),
        .IF_ID_REG_value  (IF_ID_REG_value  ),
        .ID_EX_REG_value  (ID_EX_REG_value  ),
        .EX_MEM_REG_value (EX_MEM_REG_value ),
        .MEM_WB_REG_value (MEM_WB_REG_value ),
        .stallID          (stallID          ),
        .stallEX          (stallEX          ),
        .file             (file             )
    );

    Memory u_Memory(
    	.reset            (reset            ),
        .clock            (clock            ),
        .IF_ID_REG_value  (IF_ID_REG_value  ),
        .ID_EX_REG_value  (ID_EX_REG_value  ),
        .EX_MEM_REG_value (EX_MEM_REG_value ),
        .MEM_WB_REG_value (MEM_WB_REG_value ),
        .file             (file             ),
        .result_file      (result_file      ),
        .debug_result_file(debug_result_file)
    );

    WriteBack u_WriteBack(
    	.reset            (reset            ),
        .clock            (clock            ),
        .IF_ID_REG_value  (IF_ID_REG_value  ),
        .ID_EX_REG_value  (ID_EX_REG_value  ),
        .EX_MEM_REG_value (EX_MEM_REG_value ),
        .MEM_WB_REG_value (MEM_WB_REG_value ),
        .gprWriteEnabled  (gprWriteEnabled  ),
        .gprWriteRegister (gprWriteRegister ),
        .gprWriteInput    (gprWriteInput    ),
        .file             (file             ),
        .result_file      (result_file      ),
        .debug_result_file(debug_result_file)
    );

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

    always_ff @(posedge clock) begin
        if (reset) begin
            total_stall <= 0;
        end else begin
            if (stallID || stallEX) begin
                total_stall <= total_stall + 1;
                $display("#Stall: %d", total_stall);
            end
        end
    end
    
endmodule
`endif
