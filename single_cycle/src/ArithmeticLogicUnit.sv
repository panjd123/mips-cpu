// `timescale 1ns / 1ps
`ifndef ARITHMETIC_LOGIC_UNIT_SV
`define ARITHMETIC_LOGIC_UNIT_SV

`include "common.vh"
module ArithmeticLogicUnit(
    input Vec32 aluInput1,
    input Vec32 aluInput2,
    input Vec6 aluOp,
    output Vec32 aluResult,
    output logic aluOver,
    output logic aluZero);
    assign aluZero = (aluResult == {32{1'b0}});
    assign aluOver = ((aluOp == ADD) && (~(aluInput1[31] ^ aluInput2[31]) & (aluInput1[31] ^ aluResult[31]))) ||
                  ((aluOp == SUB) && ((aluInput1[31] ^ aluInput2[31]) & (aluInput1[31] ^ aluResult[31])));
    always @(*)
    begin
        case(aluOp)
            ADD, ADDU: aluResult <= aluInput1 + aluInput2;
            SUB, SUBU: aluResult <= aluInput1 - aluInput2;
            LSHIFT, LSHIFTV: aluResult <= aluInput2 << aluInput1[4:0];
            LRSHIFT, LRSHIFTV: aluResult = aluInput2 >> aluInput1[4:0];
            ARSHIFT, ARSHIFTV: aluResult <= $signed(aluInput2) >>> aluInput1[4:0];
            AND: aluResult <= aluInput1 & aluInput2;
            OR: aluResult <= aluInput1 | aluInput2;
            XOR: aluResult <= aluInput1 ^ aluInput2;
            NOR: aluResult <= ~(aluInput1 | aluInput2);
            SLT: aluResult <= $signed(aluInput1) < $signed(aluInput2);
            SLTU: aluResult <= $unsigned(aluInput1) < $unsigned(aluInput2);
        endcase
    end
endmodule

`endif