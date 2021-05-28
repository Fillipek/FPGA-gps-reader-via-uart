`timescale 1ns / 1ps

module simple_receiver #(parameter clock_frequency = 100_000_000, baudrate = 9600, number_of_bits_in_uart_dataframe = 8, memory_size = 20) (input clk, rst, start_signal, rec, output logic finished_receiving_dataframe);

localparam uart_div_ratio = calculate_uart_div_ratio(clock_frequency, baudrate);
localparam bit_counter_lentgh = $clog2(number_of_bits_in_uart_dataframe);

logic [number_of_bits_in_uart_dataframe-1:0] received_memory [1:memory_size];
logic started_receiving;
logic clk_divided_by_ratio, clk_divided_by_ratio_times_16;

logic [bit_counter_lentgh:0] bit_counter_in_current_dataframe;

logic [number_of_bits_in_uart_dataframe-1:0] current_dataframe_reg;

//falling edge detector
logic [2:0] falling_edge_detector_register;
always @(posedge clk, posedge rst)
    if(rst)
        falling_edge_detector_register <= 2'b0;
    else if(~start_signal)
        falling_edge_detector_register <= {falling_edge_detector_register[0], rec};
always @(posedge clk, posedge rst)
    if(rst)
        started_receiving <= 1'b0;
    else if(falling_edge_detector_register[1] & ~falling_edge_detector_register[0])
        started_receiving <= 1'b1;

//clock divider by uart_div_ratio
integer div_counter_by_ratio;
always @(posedge clk, posedge rst)
    if(rst) begin
        div_counter_by_ratio <= 0;
        clk_divided_by_ratio <= 1'b0;
    end else if(started_receiving)
        if (div_counter_by_ratio == 0) begin
            div_counter_by_ratio <= uart_div_ratio - 1;
            clk_divided_by_ratio <= 1'b1;
        end else begin
            div_counter_by_ratio <= div_counter_by_ratio - 1; 
            clk_divided_by_ratio <= 1'b0;
        end
 
//clock divider by 16
logic [3:0] div_counter_by_16;
always @(posedge clk, posedge rst)
    if (rst) begin
        div_counter_by_16 <= 4'b0;
        clk_divided_by_ratio_times_16 <= 1'b0;
    end
    else if(started_receiving & clk_divided_by_ratio)
        if(div_counter_by_16 == 4'hf) begin
            div_counter_by_16 <= 4'b0;
            clk_divided_by_ratio_times_16 <= 1'b1;
        end else begin
            div_counter_by_16 <= div_counter_by_16 + 1'b1;
            clk_divided_by_ratio_times_16 <= 1'b0;
        end
        
 //shift register for current dataframe
always @(posedge clk_divided_by_ratio_times_16, posedge rst)
    if(rst)
        current_dataframe_reg <= {number_of_bits_in_uart_dataframe{1'b0}};
    else
        current_dataframe_reg <= {rec, current_dataframe_reg[number_of_bits_in_uart_dataframe-1:1]};
 
 //bitcounter for bits received in current dataframe
always @(posedge clk_divided_by_ratio_times_16, posedge rst)
    if(rst)
        bit_counter_in_current_dataframe <= {(bit_counter_lentgh+1){1'b0}};
    else if (bit_counter_in_current_dataframe == 9)
        bit_counter_in_current_dataframe <= {(bit_counter_lentgh+1){1'b0}};
    else if(started_receiving)
        bit_counter_in_current_dataframe <= bit_counter_in_current_dataframe + 1;
 
//transaction finish flag
always @(posedge clk, posedge rst)
    if (rst)
        finished_receiving_dataframe <= 1'b0;
    else if(started_receiving & (bit_counter_in_current_dataframe == number_of_bits_in_uart_dataframe + 1))
        finished_receiving_dataframe <= 1'b1;
    else
        finished_receiving_dataframe <= 1'b0;

//memory for received data
integer memory_address;
always @(posedge clk, posedge rst)
    if (rst)
        memory_address = 1;
    else if(finished_receiving_dataframe & clk_divided_by_ratio_times_16 & clk_divided_by_ratio)
        received_memory[memory_address++] = current_dataframe_reg;
        
function integer calculate_uart_div_ratio (input integer clock_frequency, baudrate);
    integer brate_mult16_div2, reminder, uart_div_ratio;
    begin
    brate_mult16_div2 = 8*baudrate;
    reminder = clock_frequency % (16 * baudrate);
    uart_div_ratio = clock_frequency / (16 * baudrate);
    if (brate_mult16_div2 < reminder)
    calculate_uart_div_ratio = uart_div_ratio+1;
    else
    calculate_uart_div_ratio = uart_div_ratio;
    end
endfunction
        
endmodule