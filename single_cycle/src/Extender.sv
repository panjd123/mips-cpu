`timescale 1ns / 1ps
`ifndef EXTENDER_SV
`define EXTENDER_SV
`include "common.vh"
module Extender(
    input Vec16 extInput,
    input logic extSign,
    output Vec32 extResult
);
    always_comb begin : extender
        if (extSign)
            extResult = {{16{extInput[15]}}, extInput};
        else
            extResult = {16'b0, extInput};
    end
endmodule
`endif