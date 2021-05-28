`timescale 1ns / 1ps


module memory #(parameter deep = 16) (input clk, rd, wr, input [$clog2(deep)-1:0] addr,
    input [7:0] data_in, output logic [7:0] data_out);

reg [7:0] mem [1:deep];

always @(posedge clk)
    if(wr)
        mem[addr] <= data_in;
    else if(rd)
        data_out <= mem[addr];  
          
endmodule
