`timescale 1ns / 1ps

module master_axi #(
  // how many 8-bit words the memory can store
  parameter memory_depth = 20
) (
  input clk,
  input rst,
  
  // AXI AW channel GPS
  output logic [3:0] AW_addr_GPS,
  output logic AW_valid_GPS,
  input AW_ready_GPS,
  
  // AXI W channel GPS
  output [31:0] W_data_GPS,
  output logic W_valid_GPS,
  input W_ready_GPS,
  
  // AXI B channel GPS
  input [1:0] B_resp_GPS,
  input B_valid_GPS,
  output logic B_ready_GPS,
  
  // AXI AR channel GPS
  output logic [3:0] AR_addr_GPS,
  output logic AR_valid_GPS,
  input AR_ready_GPS,
  
  // AXI R channel GPS
  input [31:0] R_data_GPS,
  input R_valid_GPS,
  output logic R_ready_GPS,


  // AXI AW channel FTDI
  output logic [3:0] AW_addr_FTDI,
  output logic AW_valid_FTDI,
  input AW_ready_FTDI,
  
  // AXI W channel FTDI
  output [31:0] W_data_FTDI,
  output logic W_valid_FTDI,
  input W_ready_FTDI,
  
  // AXI B channel FTDI
  input [1:0] B_resp_FTDI,
  input B_valid_FTDI,
  output logic B_ready_FTDI,
  
  // AXI AR channel FTDI
  output logic [3:0] AR_addr_FTDI,
  output logic AR_valid_FTDI,
  input AR_ready_FTDI,
  
  // AXI R channel FTDI
  input [31:0] R_data_FTDI,
  input R_valid_FTDI,
  output logic R_ready_FTDI,

    
  // data input / output channels from memory
  input [7:0] data_tr,
  output logic [7:0] data_rec,
  
  // memory adrres for reading / writing
  output logic [$clog2(memory_depth)-1:0] mem_addr,
  
  // flags for memory module indicates whether READ or WRITE
  output logic wr,
  output logic rd,
  
  // flag distinguishes transmitting and receiving
  output logic rec_trn
);
    
localparam nb = $clog2(memory_depth);

//////////////////////////////////////
// FSM AND SOME IMPORTANT FLAGS
//////////////////////////////////////

typedef enum {
  READ_STATUS,
  WAIT_STATUS,
  READ,
  WAIT_READ
} statesEnum;

statesEnum st, nst;

logic [nb-1:0] addr;  
wire addr0 = (addr=={nb{1'b0}});

// RX FIFO valid flag - is there any data to read
wire rfifo_valid = (st == WAIT_STATUS & R_valid_GPS) ? R_data_GPS[0] : 1'b0;  
// TX FIFO full flag - is there any free space to write
wire tfifo_full = (st == WAIT_STATUS & R_valid_GPS) ? R_data_GPS[3] : 1'b0; 

always_comb begin
  nst = READ_STATUS;
  case(st)
    READ_STATUS: nst = WAIT_STATUS;
    WAIT_STATUS: nst = rfifo_valid ? (R_valid_GPS ? READ : WAIT_STATUS) : READ_STATUS;
    READ: nst = WAIT_READ;
    WAIT_READ: nst = R_valid_GPS ? READ_STATUS : WAIT_READ;
  endcase
end

always @(posedge clk, posedge rst)
    if(rst)
        st <= READ_STATUS;
    else
        st <= nst;   

//reg to distiguisz transmi and receive
//always @(posedge clk, posedge rst)
//    if(rst)
//        rec_trn <= 1'b1;
//    else if (addr == memory_depth)
//        rec_trn <= 1'b0;
//    else if (st == CLEAR)
//        rec_trn <= 1'b1; 

//////////////////////////////////////
// TRANSMITTER CONTROL

// AW CAHNNEL
assign AW_addr_GPS = 4'b0;
assign AW_valid_GPS = 1'b0;     

// W CAHNNEL
assign W_data_GPS = 32'b0;
assign W_valid_GPS = 1'b0;

// B CAHNNEL
assign B_ready_GPS = 1'b0;

//////////////////////////////////////
// RECEIVER CONTROL
//////////////////////////////////////
// AR CAHNNEL
//////////////////////////////////////
always @(posedge clk, posedge rst)
    if(rst)  
        AR_addr_GPS <= 4'b0;
    else if (st == READ_STATUS)
        AR_addr_GPS <= 4'h8;
    else if (st == READ)
        AR_addr_GPS <= 4'h0;  
         
always @(posedge clk, posedge rst)
    if(rst)         
        AR_valid_GPS <= 1'b0;
    else if(st == READ | st == READ_STATUS)
        AR_valid_GPS <= 1'b1;
    else if(AR_ready_GPS)
        AR_valid_GPS <= 1'b0;
        
//////////////////////////////////////
// R CAHNNEL
//////////////////////////////////////

always @(posedge clk, posedge rst)
    if(rst)        
        R_ready_GPS <= 1'b0;
    else if((st == WAIT_STATUS | st == WAIT_READ) & R_valid_GPS)
        R_ready_GPS <= 1'b1;  
    else
        R_ready_GPS <= 1'b0;  

//////////////////////////////////////
// MEMORY CONTROL
//////////////////////////////////////

reg [7:0] buffer;

// WRITE - buffer ready
always @(posedge clk)
    if(rst)
        wr <= 1'b0;
    else 
        wr <= (st == WAIT_READ) & R_valid_GPS;

// DATA
always @(posedge clk)
    if(rst)
        buffer <= 8'b0;
    else if (st == WAIT_READ) & R_valid_GPS)
        buffer <= R_data_GPS[7:0];


endmodule