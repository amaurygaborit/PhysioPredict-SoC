// Acts as a Slave. Streams physiological data to UART and
// generates an analog signal via Delta-Sigma DAC when receiving 's'.

import soc_pkg::*;

module top (
    input  logic clk,
    input  logic uart_rx_pin,    // UART RX pin from Master (STM32/PC)
    output logic uart_tx_pin,    // UART TX pin to PC
    output logic analog_out_pin, // Physical pin for the RC Filter (DAC)
    output logic led_pin         // iCESugar yellow LED (Status)
);

    // BRAM Declaration and Initialization
    logic [7:0] ecg_bram [0:DATASET_SIZE-1];
    
    initial $readmemh("../build/dataset.txt", ecg_bram);

    // Sample Rate Timer
    logic [31:0] timer = 0; 
    logic sample_tick = 0;  

    always_ff @(posedge clk) begin
        if (timer < SAMPLE_TIMER_MAX - 1) begin
            timer <= timer + 1;
            sample_tick <= 1'b0;
        end else begin
            timer <= 0;
            sample_tick <= 1'b1; // Trigger next read
        end
    end

    // Command Decoder (Master/Slave Control)
    logic is_streaming = 0; // Paused
    wire [7:0] rx_data;
    wire       rx_valid;

    always_ff @(posedge clk) begin
        if (rx_valid == 1'b1) begin
            if (rx_data == 8'h73) begin      // ASCII 's'
                is_streaming <= 1'b1;
            end else if (rx_data == 8'h70) begin // ASCII 'p'
                is_streaming <= 1'b0;
            end
        end
    end

    // Read Logic, DAC Register and UART Trigger
    logic [31:0] rom_addr = 0;
    logic        tx_start = 0;
    logic [7:0]  tx_data  = 0;
    wire         tx_ready;
    
    logic [7:0]  current_ecg_val = 0; // Value fed to the DAC

    always_ff @(posedge clk) begin
        tx_start <= 1'b0; 
        
        if (sample_tick == 1'b1) begin
            if (is_streaming == 1'b1) begin
                // Update the value for the DAC
                current_ecg_val <= ecg_bram[rom_addr];
                
                // Trigger UART Transmission if ready
                if (tx_ready == 1'b1) begin
                    tx_data  <= ecg_bram[rom_addr];
                    tx_start <= 1'b1;
                end
                
                // Move to next sample
                if (rom_addr < DATASET_SIZE - 1) begin
                    rom_addr <= rom_addr + 1;
                end else begin
                    rom_addr <= 0; // Loop dataset
                end
            end else begin
                // When paused, output 0V to the DAC
                current_ecg_val <= 8'd0;
            end
        end
    end

    // Visual Indicator (LED Active Low)
    assign led_pin = ~is_streaming;

    // DAC Instance
    sigma_delta_dac #(
        .DAC_BITLEN(8)
    ) my_dac (
        .clk(clk),
        .rst(1'b0), // No reset needed
        .dac_input(current_ecg_val),
        .dac_pin(analog_out_pin)
    );

    // UART Transmitter Instance
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) my_uart_tx (
        .clk(clk),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_pin(uart_tx_pin),
        .tx_ready(tx_ready)
    );

    // UART Receiver Instance
    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) my_uart_rx (
        .clk(clk),
        .rx_pin(uart_rx_pin),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

endmodule