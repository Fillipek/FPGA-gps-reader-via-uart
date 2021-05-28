`timescale 1ns / 1ps

module test_uart;

localparam mem_depth = 10, hp = 5, fclk = 100_000_000, br2 = 115_200, br1 = 9600, size = 8;
localparam ratio1 = fclk / br1 - 1;
localparam ratio2 = fclk / br2 - 1;
logic clk, rst, start_transmitter, start_receiver;

top uut (.clk(clk), .rst(rst), .rx_gps(rx_gps), .tx_gps(tx_gps), .rx_ftdi(rx_ftdi), .tx_ftdi(tx_ftdi));

simple_receiver #(
  .clock_frequency(fclk),
  .baudrate(br2),
  .number_of_bits_in_uart_dataframe(size),
  .memory_size(mem_depth)
) receiver (
  .clk(clk),
  .rst(rst),
  .start_signal(start_receiver),
  .rec(tx_ftdi),
  .finished_receiving_dataframe(finr)
);

// transmitter
simple_transmitter #(
  .fclk(fclk),
  .baudrate(br1),
  .nb(size),
  .deep(mem_depth)
) transmitter (
  .clk(clk),
  .rst(rst),
  .str(start_transmitter),
  .trn(rx_gps),
  .fin(fint)
);

// clk gen
initial begin
    clk = 1'b0;
    forever #hp clk = ~clk;
end

// rst gen
initial begin
    rst = 1'b0;
    #1 rst = 1'b1;
    repeat (5) @(posedge clk);
    #2 rst = 1'b0;
end

// activate transmitter, then receiver
initial begin
    start_transmitter = 1'b0;
    start_receiver = 1'b0;
    @(negedge rst);
    repeat(ratio1/8) @(posedge clk);
    
    repeat(2) @(negedge clk);
    start_transmitter = 1'b1;
    $display("Start sending at: %t ns", $time);
    @(negedge clk);
    start_transmitter = 1'b0;
    
    repeat(transmitter.numof_chars) @(negedge fint);
    
    start_receiver = 1'b1;
    $display("Start receiving at: %t ns", $time);
    repeat(2) @(negedge clk);
    start_receiver = 1'b0;
    
    repeat(transmitter.numof_chars) @(negedge finr);
    
    #100 $finish;
end

initial begin
    @(negedge start_transmitter);
    repeat(transmitter.numof_chars) @(negedge fint);
    repeat(10) @(posedge clk);
//    $display("Received by FPGA: %h", uut.storage.mem);
    
    // $write("[SIMUALTION] In FPGA:  ");
    // foreach (uut.storage.mem[j])
    //   $write("%c", uut.storage.mem[j]);
    // $display();

    // repeat(transmitter.numof_chars) @(negedge finr);
    
    // $write("[SIMUALTION] In Receiver:  ");
    // foreach (receiver.received_memory[j])
    //   $write("%c", receiver.received_memory[j]);
    // $display();

end

endmodule
