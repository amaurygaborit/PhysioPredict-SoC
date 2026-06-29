// Global parameters
package soc_pkg;

    // Hardware
    parameter SYS_CLK_FREQ = 12_000_000; // System clock frequency

    // UART Communication
    parameter UART_BAUD_RATE = 115200;
    parameter CLKS_PER_BIT   = SYS_CLK_FREQ / UART_BAUD_RATE;

    // WFDB Dataset
    parameter DATASET_SIZE   = 1024; // Number of extracted data points
    parameter SAMPLE_RATE_HZ = 10;    // Transmission rate in Hz
    
    parameter SAMPLE_TIMER_MAX = SYS_CLK_FREQ / SAMPLE_RATE_HZ; // Timer threshold for target rate

endpackage