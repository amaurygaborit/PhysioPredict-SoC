// UART TX
// Transmits a single byte using the standard UART protocol (1 start bit, 8 data bits, 1 stop bit).

module uart_tx #(
    parameter CLKS_PER_BIT = 104 // 12 MHz / 115200 baud = 104
)(
    input  logic       clk,
    input  logic       tx_start,  // Trigger to start transmission
    input  logic [7:0] tx_data,   // Data to transmit
    output logic       tx_pin,    // Physical TX pin
    output logic       tx_ready   // 1 = Ready to send, 0 = Busy
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
        case (state)
            IDLE: begin
                tx_pin   <= 1'b1; // Line idle (High)
                tx_ready <= 1'b1;
                
                if (tx_start == 1'b1) begin
                    tx_ready  <= 1'b0;
                    shift_reg <= tx_data;
                    state     <= START_BIT;
                    clk_count <= 0;
                end
            end

            START_BIT: begin
                tx_pin <= 1'b0; // Start bit (Low)
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    state     <= DATA_BITS;
                    bit_index <= 0;
                end
            end

            DATA_BITS: begin
                tx_pin <= shift_reg[bit_index]; // Send current data bit
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        state <= STOP_BIT;
                    end
                end
            end

            STOP_BIT: begin
                tx_pin <= 1'b1; // Stop bit (High)
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    state     <= IDLE;
                end
            end
        endcase
    end
endmodule