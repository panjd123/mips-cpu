`ifndef ARITHMETIC_LOGIC_UNIT_SV
`define ARITHMETIC_LOGIC_UNIT_SV

`include "common.vh"
module ArithmeticLogicUnit(
    input Vec32 aluInput1,
    input Vec32 aluInput2,
    input Vec6 aluOp,
    output Vec32 aluResult,
    output logic aluOver
    );
    assign aluOver = ((aluOp == ALU_ADD) && (~(aluInput1[31] ^ aluInput2[31]) & (aluInput1[31] ^ aluResult[31]))) ||
                  ((aluOp == ALU_SUB) && ((aluInput1[31] ^ aluInput2[31]) & (aluInput1[31] ^ aluResult[31])));
    always_comb begin : aluComb
        case(aluOp)
            ALU_ADD, ALU_ADDU: aluResult = aluInput1 + aluInput2;
            ALU_SUB, ALU_SUBU: aluResult = aluInput1 - aluInput2;
            ALU_LSHIFT, ALU_LSHIFTV: aluResult = aluInput2 << aluInput1[4:0];
            ALU_LRSHIFT, ALU_LRSHIFTV: aluResult = aluInput2 >> aluInput1[4:0];
            ALU_ARSHIFT, ALU_ARSHIFTV: aluResult = $signed(aluInput2) >>> aluInput1[4:0];
            ALU_AND: aluResult = aluInput1 & aluInput2;
            ALU_OR: aluResult = aluInput1 | aluInput2;
            ALU_XOR: aluResult = aluInput1 ^ aluInput2;
            ALU_NOR: aluResult = ~(aluInput1 | aluInput2);
            ALU_SLT: aluResult = $signed(aluInput1) < $signed(aluInput2);
            ALU_SLTU: aluResult = $unsigned(aluInput1) < $unsigned(aluInput2);
        endcase
    end
endmodule

`endif