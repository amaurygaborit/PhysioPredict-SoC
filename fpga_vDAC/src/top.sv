import soc_pkg::*;

module top (
    input  logic clk,         // System clock (12 MHz)
    output logic uart_tx_pin, // UART TX pin to PC
    output logic led_pin      // iCESugar yellow LED
);

    // BRAM
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

    // Read and Transmit Logic
    logic [31:0] rom_addr = 0;
    logic       tx_start = 0;
    logic [7:0] tx_data  = 0;
    wire        tx_ready;

    always_ff @(posedge clk) begin
        tx_start <= 1'b0; 
        
        // Wait for timer tick and UART readiness
        if (sample_tick == 1'b1 && tx_ready == 1'b1) begin
            
            tx_data  <= ecg_bram[rom_addr];
            tx_start <= 1'b1;
            
            if (rom_addr < DATASET_SIZE - 1) begin
                rom_addr <= rom_addr + 1;
            end else begin
                rom_addr <= 0; // Loop dataset
            end
        end
    end

    // Visual Indicator (LED)
    assign led_pin = ~rom_addr[9]; 

    // UART Transmitter Instance
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) my_uart (
        .clk(clk),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_pin(uart_tx_pin),
        .tx_ready(tx_ready)
    );

endmodule