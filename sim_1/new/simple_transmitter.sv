`timescale 1ns / 1ps


module simple_transmitter #(parameter fclk = 10**9, baudrate = 9600, nb = 8, deep = 20)
    (input clk, rst, str, output trn, input fin);
    
localparam ratio = fclk / baudrate - 1;
localparam bcntl = $clog2(nb);  //bit counter length
logic [bcntl:0] bitcnt;

typedef enum {idle, start, data, stop} states_e;
states_e st, nst;

logic oper;
integer cnt, inx;

integer file = $fopen("trmem.mem", "r");
reg [8:0] char = $fgetc(file);
byte queue[$];
int numof_chars;

initial begin
  while (char != 'h1ff) begin
    queue.push_back(char);
//    $display("Got char [%0d] %b", numof_chars, char);
    numof_chars++;
    char = $fgetc(file);
  end
  $write("[SIMUALTION] To send:  ");
  foreach (queue[j])
    $write("%c", queue[j]);
  $display();
end

logic [nb-1:0] val;

always @(posedge clk, posedge rst)
    if(rst) begin
        val <= 0;
        inx = 0; 
    end else if (fin | str) begin
        inx++;
        val = queue[inx-1];
        if(inx == deep) inx++;
    end

always @(posedge clk, posedge rst)
    if(rst)
        oper <= 1'b0;
    else if(str)
        oper <= 1'b1;
    else if(fin & (inx == numof_chars + 2))
        oper <= 1'b0;

wire new_bit = (cnt == ratio);
assign fin = new_bit & (st == stop);

always @(posedge clk, posedge rst)
    if(rst)
        cnt <= ratio;
    else if(st != idle)
        if (cnt == 0)
            cnt <= ratio;
        else
            cnt <= cnt - 1'b1;

always @(posedge clk, posedge rst)
    if(rst)
        st <= idle;
    else
        st <= nst;
        
always_comb begin
    nst = idle;
    case(st)
        idle: nst = oper ? start : idle;
        start: nst = new_bit ? data : start;
        data: nst = (bitcnt >= 9) ? stop : data;
        stop: nst = new_bit ? idle : stop;
    endcase
end

always @(posedge clk, posedge rst)
    if(rst)
        bitcnt <= {(bcntl+1){1'b0}};
    else if(oper & (bitcnt == nb+1))
        bitcnt <= {(bcntl+1){1'b0}};
    else if((st == data) & (oper & new_bit))
        bitcnt <= bitcnt + 1'b1;
        
logic [nb+1:0] trans_reg;
assign trn = (st == data) ? trans_reg[0] : 1'b1;
always @(posedge clk, posedge rst)
    if(rst)
        trans_reg <= {{nb+2}{1'b1}};
    else if((st == idle) & (bitcnt == 0))
        trans_reg <= {1'b1, val, 1'b0};
    else if((st == data) & new_bit)
        trans_reg <= {1'b1, trans_reg[nb+1:1]};
    else if(fin)
        trans_reg <= {1'b1, trans_reg[nb+1]};
endmodule
