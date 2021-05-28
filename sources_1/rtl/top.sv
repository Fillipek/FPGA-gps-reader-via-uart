`timescale 1ns / 1ps

module top #(parameter mdeep = 20) (input clk, rst, rx, output tx, led, output logic ind5);

logic [3:0] AR_addr_GPS, AW_addr_GPS;
logic [31 : 0] W_data_GPS, R_data_GPS;
logic [1 : 0] B_resp_GPS, R_resp_GPS;
wire [3 : 0] W_strobe_GPS = 4'b1111;

logic [3:0] AR_addr_FTDI, AW_addr_FTDI;
logic [31 : 0] W_data_FTDI, R_data_FTDI;
logic [1 : 0] B_resp_FTDI, R_resp_FTDI;
wire [3 : 0] W_strobe_FTDI = 4'b1111;

reg high = 1'b1;

axi_uartlite_0 uart_gps (
  .s_axi_aclk(clk),
  .s_axi_aresetn(~rst),
  .interrupt(),

  .s_axi_araddr(AR_addr_GPS),
  .s_axi_arvalid(AR_valid_GPS),
  .s_axi_arready(AR_ready_GPS),
  
  .s_axi_rdata(R_data_GPS),
  .s_axi_rresp(R_resp_GPS),
  .s_axi_rvalid(R_valid_GPS),
  .s_axi_rready(R_ready_GPS),
  
  .s_axi_awaddr(AW_addr_GPS),
  .s_axi_awvalid(AW_valid_GPS),
  .s_axi_awready(AW_ready_GPS),
  
  .s_axi_wdata(W_data_GPS),
  .s_axi_wstrb(W_strobe_GPS),
  .s_axi_wvalid(W_valid_GPS),
  .s_axi_wready(W_ready_GPS),
  
  .s_axi_bresp(B_resp_GPS),
  .s_axi_bvalid(B_valid_GPS),
  .s_axi_bready(B_ready_GPS),

  .rx(rx),
  .tx(tx)
);

axi_uartlite_0 uart_ftdi (
  .s_axi_aclk(clk),
  .s_axi_aresetn(~rst),
  .interrupt(),

  .s_axi_araddr(AR_addr_FTDI),
  .s_axi_arvalid(AR_valid_FTDI),
  .s_axi_arready(AR_ready_FTDI),
  
  .s_axi_rdata(R_data_FTDI),
  .s_axi_rresp(R_resp_FTDI),
  .s_axi_rvalid(R_valid_FTDI),
  .s_axi_rready(R_ready_FTDI),
  
  .s_axi_awaddr(AW_addr_FTDI),
  .s_axi_awvalid(AW_valid_FTDI),
  .s_axi_awready(AW_ready_FTDI),
  
  .s_axi_wdata(W_data_FTDI),
  .s_axi_wstrb(W_strobe_FTDI),
  .s_axi_wvalid(W_valid_FTDI),
  .s_axi_wready(W_ready_FTDI),
  
  .s_axi_bresp(B_resp_FTDI),
  .s_axi_bvalid(B_valid_FTDI),
  .s_axi_bready(B_ready_FTDI),

  .rx(rx),
  .tx(tx)
);

// wire [$clog2(mdeep)-1:0] adr;
// wire [7:0] data_from_mem, data_to_mem;

master_axi #(.memory_depth(mdeep)) master (
  .clk(clk),
  .rst(rst),


  .AW_addr_GPS(AW_addr_GPS),
  .AW_valid_GPS(AW_valid_GPS),
  .AW_ready_GPS(AW_ready_GPS),

  .W_data_GPS(W_data_GPS),
  .W_valid_GPS(W_valid_GPS),
  .W_ready_GPS(W_ready_GPS),

  .B_resp_GPS(B_resp_GPS),
  .B_valid_GPS(B_valid_GPS),
  .B_ready_GPS(B_ready_GPS),
  
  .AR_addr_GPS(AR_addr_GPS),
  .AR_valid_GPS(AR_valid_GPS),
  .AR_ready_GPS(AR_ready_GPS),

  .R_data_GPS(R_data_GPS),
  .R_valid_GPS(R_valid_GPS),
  .R_ready_GPS(R_ready_GPS),


  .AR_addr_FTDI(AR_addr_FTDI),
  .AR_valid_FTDI(AR_valid_FTDI),
  .AR_ready_FTDI(AR_ready_FTDI),
  
  .R_data_FTDI(R_data_FTDI),
  .R_valid_FTDI(R_valid_FTDI),
  .R_ready_FTDI(R_ready_FTDI),
  
  .AW_addr_FTDI(AW_addr_FTDI),
  .AW_valid_FTDI(AW_valid_FTDI),
  .AW_ready_FTDI(AW_ready_FTDI),
  
  .W_data_FTDI(W_data_FTDI),
  .W_valid_FTDI(W_valid_FTDI),
  .W_ready_FTDI(W_ready_FTDI),
  
  .B_resp_FTDI(B_resp_FTDI),
  .B_valid_FTDI(B_valid_FTDI),
  .B_ready_FTDI(B_ready_FTDI)
  
    
  // .data_tr(data_from_mem),
  // .data_rec(data_to_mem),

  // .mem_addr(adr),

  // .wr(wr),
  // .rd(rd),

  // .rec_trn(led)
);

// memory #(.deep(mdeep)) storage (.clk(clk), .rd(rd), .wr(wr), .addr(adr),
//     .data_in(data_to_mem), .data_out(data_from_mem));

endmodule
