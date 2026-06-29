// UART Receiver
// Listens to a physical pin and decodes a byte using
// the standard UART protocol.

module uart_rx #(
    parameter CLKS_PER_BIT = 104
)(
    input  logic       clk,
    input  logic       rx_pin,    // Physical RX pin
    output logic [7:0] rx_data,   // Received data
    output logic       rx_valid   // 1 clock cycle pulse (Data ready)
);

    typedef enum logic [2:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    } state_t;

    state_t state = IDLE;

    logic [7:0] clk_count = 0;
    logic [2:0] bit_index = 0;
    logic [7:0] shift_reg = 0;

    always_ff @(posedge clk) begin
        // Default valid pulse value
        rx_valid <= 1'b0;

        case (state)
            IDLE: begin
                clk_count <= 0;
                bit_index <= 0;
                
                // Detect Start bit (falling edge 1 to 0)
                if (rx_pin == 1'b0) begin
                    state <= START_BIT;
                end
            end

            START_BIT: begin
                // Wait for HALF a bit to sample right in the middle (more reliable)
                if (clk_count == (CLKS_PER_BIT / 2)) begin
                    if (rx_pin == 1'b0) begin
                        clk_count <= 0;
                        state     <= DATA_BITS;
                    end else begin
                        state     <= IDLE; // False start (glitch/noise)
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            DATA_BITS: begin
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    shift_reg[bit_index] <= rx_pin; // Capture the bit
                    
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        state <= STOP_BIT;
                    end
                end
            end

            STOP_BIT: begin
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    rx_data  <= shift_reg;
                    rx_valid <= 1'b1; // Raise flag: byte is ready!
                    state    <= IDLE;
                end
            end
        endcase
    end
endmodule