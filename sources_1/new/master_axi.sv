`timescale 1ns / 1ps

module master_axi (
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
  output logic [31:0] W_data_FTDI,
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

  output logic received_dollar

);

//////////////////////////////////////
// FSM AND SOME IMPORTANT FLAGS
//////////////////////////////////////

typedef enum {
  READ_STATUS,
  WAIT_STATUS,
  READ,
  WAIT_READ
} gps_states;

gps_states st, nst;

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
reg wr;

// WRITE - buffer ready
always @(posedge clk, posedge rst)
    if(rst)
        wr <= 1'b0;
    else 
        wr <= (st == WAIT_READ) & R_valid_GPS;

// DATA
always @(posedge clk, posedge rst)
    if(rst)
        buffer <= 8'b0;
    else if ((st == WAIT_READ) & R_valid_GPS)
        buffer <= R_data_GPS[7:0];

// WRITE - test dollar
always @(posedge clk, posedge rst)
    if(rst)
        received_dollar <= 1'b0;
    else if (wr && buffer == 8'h24)
        received_dollar <= ~received_dollar;

/////////////////////////////////////
// FTDI UART CONTROL FSM
/////////////////////////////////////

typedef enum {
  FTDI_READ_STATUS,
  FTDI_WAIT_STATUS,
  FTDI_WRITE,
  FTDI_WAIT_WRITE,
  FTDI_WAIT_RESP
} ftdi_states;

ftdi_states ftdi_st, ftdi_nst;

always_comb begin
  ftdi_nst = FTDI_READ_STATUS;
  case(st)
    FTDI_READ_STATUS: ftdi_nst = FTDI_WAIT_STATUS;
    FTDI_WAIT_STATUS: ftdi_nst = wr ? FTDI_READ_STATUS : (R_valid_FTDI ? FTDI_WRITE : FTDI_READ_STATUS);
    FTDI_WRITE: ftdi_nst = FTDI_WAIT_WRITE;
    FTDI_WAIT_WRITE: ftdi_nst = AW_ready_FTDI ? FTDI_WAIT_RESP : FTDI_WAIT_WRITE;
    FTDI_WAIT_RESP: ftdi_nst = B_valid_FTDI ? FTDI_READ_STATUS : FTDI_WAIT_RESP;

    // WAIT_STATUS:
    //   if(rec_trn)
    //     nst = rfifo_valid ? (R_valid ? READ : WAIT_STATUS) : READ_STATUS;
    //   else
    //     nst = tfifo_full ? READ_STATUS : (R_valid ? WRITE : WAIT_STATUS);
    // READ: nst = WAIT_READ;
    // WAIT_READ: nst = R_valid ? READ_STATUS : WAIT_READ;
    // WRITE: nst = WAIT_WRITE;
    // WAIT_WRITE: nst = AW_ready ? WAIT_RESP : WAIT_WRITE;
    // WAIT_RESP: nst = B_valid ? (addr0 ? CLEAR : READ_STATUS) : WAIT_RESP;
    // CLEAR: nst = READ_STATUS;
  endcase
end

always @(posedge clk, posedge rst)
    if(rst)
        ftdi_st <= FTDI_READ_STATUS;
    else
        ftdi_st <= ftdi_nst;


//////////////////////////////////
// FTDI CONTROL
/////////////////////////////////

// wystapi write - zacznij wysylanie
// AW CAHNNEL
always @(posedge clk, posedge rst)
    if(rst)  
        AW_addr_FTDI <= 4'b0;
    else if (ftdi_st == FTDI_WRITE | ftdi_st == FTDI_WAIT_WRITE)
        AW_addr_FTDI <= 4'h4;
    else
        AW_addr_FTDI <= 4'b0;
        
always @(posedge clk, posedge rst)
    if(rst)
        AW_valid_FTDI <= 1'b0;
    else begin
        if (ftdi_st == FTDI_WRITE | ftdi_st == FTDI_WAIT_WRITE)
            AW_valid_FTDI <= 1'b1;
        if(AW_ready_FTDI)
            AW_valid_FTDI <= 1'b0; 
    end        

// W CAHNNEL FTDI
always @(posedge clk, posedge rst)
    if(rst)         
        W_valid_FTDI <= 1'b0;
    else begin
        if (ftdi_st == FTDI_WRITE | ftdi_st == FTDI_WAIT_WRITE)
            W_valid_FTDI <= 1'b1;
        if (W_ready_FTDI)
            W_valid_FTDI <= 1'b0; 
        end

always @(posedge clk, posedge rst)
    if(rst)
        W_data_FTDI <= 32'b0;
    else if (ftdi_st == FTDI_WRITE)
        W_data_FTDI = {24'b0, buffer};
    else if (W_ready_FTDI)
        W_data_FTDI <= 32'b0;

// B CAHNNEL FTDI trzeba zobaczyc czy wszystkie kanaly uzwyamy
always @(posedge clk, posedge rst)
    if(rst)        
        B_ready_FTDI <= 1'b0;
    else begin
        if (ftdi_st == FTDI_WRITE)
            B_ready_FTDI <= 1'b1;  
        if (B_valid_FTDI)
            B_ready_FTDI <= 1'b0;
        end

// AR CAHNNEL FTDI
always @(posedge clk, posedge rst)
    if(rst)  
        AR_addr_FTDI <= 4'b0;
    else if (ftdi_st == FTDI_READ_STATUS)
        AR_addr_FTDI <= 4'h8;
         
always @(posedge clk, posedge rst)
    if(rst)         
        AR_valid_FTDI <= 1'b0;
    else if(ftdi_st == FTDI_READ_STATUS)
        AR_valid_FTDI <= 1'b1;
    else if(AR_ready_FTDI)
        AR_valid_FTDI <= 1'b0;

// R CAHNNEL FTDI
always @(posedge clk, posedge rst)
    if(rst)        
        R_ready_FTDI <= 1'b0;
    else if((ftdi_st == FTDI_WAIT_STATUS) & R_valid_FTDI)
        R_ready_FTDI <= 1'b1;  
    else
        R_ready_FTDI <= 1'b0;  

endmodule